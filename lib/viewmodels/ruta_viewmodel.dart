import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ubicacion_model.dart';

class RutaViewModel extends ChangeNotifier {
  List<UbicacionModel> _ubicaciones = [];
  List<UbicacionModel> get ubicaciones => _ubicaciones;
  
  List<UbicacionModel> _rutaOptimizada = [];
  List<UbicacionModel> get rutaOptimizada => _rutaOptimizada;
  
  Position? _posicionActual;
  Position? get posicionActual => _posicionActual;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _tienePermisoUbicacion = false;
  bool get tienePermisoUbicacion => _tienePermisoUbicacion;
  
  bool _cargando = false;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ============================================================
  // CARGAR UBICACIONES DESDE FIRESTORE
  // ============================================================
  Future<void> cargarUbicaciones() async {
    if (_cargando) return;
    
    _cargando = true;
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _firestore.collection('clientes_perfil').get();
      
      final List<UbicacionModel> ubicacionesTemp = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        double lat = _toDouble(data['lat']);
        double lng = _toDouble(data['lng']);
        final deuda = _toDouble(data['deudaActual']);
        final nombre = '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}'.trim();
        
        if (lat != 0.0 && lng != 0.0) {
          ubicacionesTemp.add(UbicacionModel(
            clienteId: doc.id,
            nombre: nombre,
            latitud: lat,
            longitud: lng,
            prioridad: deuda > 0 ? 'ALTA' : 'NORMAL',
            tipoGestion: deuda > 0 ? 'Cobranza' : 'Nuevo Cliente',
            direccion: data['direccion'] ?? '',
            visitado: false,
          ));
        }
      }
      
      _ubicaciones = ubicacionesTemp;
      _rutaOptimizada = List.from(_ubicaciones);
      
    } catch (e) {
      debugPrint('Error cargando ubicaciones: $e');
    } finally {
      _isLoading = false;
      _cargando = false;
      notifyListeners();
    }
  }
  
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  Future<void> solicitarPermisosUbicacion() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      _tienePermisoUbicacion = permission == LocationPermission.always || 
                                permission == LocationPermission.whileInUse;
      notifyListeners();
    } catch (e) {
      debugPrint('Error solicitando permisos: $e');
    }
  }
  
  Future<void> obtenerPosicionActual() async {
    if (!_tienePermisoUbicacion) {
      await solicitarPermisosUbicacion();
    }
    
    try {
      _posicionActual = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error obteniendo posición: $e');
    }
  }
  
  void optimizarRuta() {
    if (_posicionActual == null) {
      _rutaOptimizada = List.from(_ubicaciones.where((u) => !u.visitado));
      notifyListeners();
      return;
    }
    
    final noVisitados = _ubicaciones.where((u) => !u.visitado).toList();
    
    if (noVisitados.isEmpty) {
      _rutaOptimizada = [];
      notifyListeners();
      return;
    }
    
    final List<UbicacionModel> ordenados = List.from(noVisitados);
    ordenados.sort((a, b) {
      final distanciaA = _calcularDistancia(
        _posicionActual!.latitude,
        _posicionActual!.longitude,
        a.latitud,
        a.longitud,
      );
      final distanciaB = _calcularDistancia(
        _posicionActual!.latitude,
        _posicionActual!.longitude,
        b.latitud,
        b.longitud,
      );
      return distanciaA.compareTo(distanciaB);
    });
    
    _rutaOptimizada = ordenados;
    notifyListeners();
  }
  
  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3; // Radio de la Tierra en metros
    final double p1 = lat1 * pi / 180;
    final double p2 = lat2 * pi / 180;
    final double dp = (lat2 - lat1) * pi / 180;
    final double dl = (lon2 - lon1) * pi / 180;
    
    final double a = sin(dp / 2) * sin(dp / 2) +
        cos(p1) * cos(p2) *
        sin(dl / 2) * sin(dl / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
  }
  
  Future<void> lanzarNavegacion(double lat, double lng, String nombre) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'
    );
    
    final Uri wazeUri = Uri.parse(
      'https://waze.com/ul?ll=$lat,$lng&navigate=yes'
    );
    
    try {
      if (await canLaunchUrl(wazeUri)) {
        await launchUrl(wazeUri);
      } else if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri);
      }
    } catch (e) {
      debugPrint('Error lanzando navegación: $e');
    }
  }
  
  void marcarVisitado(String clienteId) {
    final index = _ubicaciones.indexWhere((u) => u.clienteId == clienteId);
    if (index != -1) {
      _ubicaciones[index].visitado = true;
      
      final rutaIndex = _rutaOptimizada.indexWhere((u) => u.clienteId == clienteId);
      if (rutaIndex != -1) {
        _rutaOptimizada.removeAt(rutaIndex);
      }
      
      notifyListeners();
    }
  }
  
  void reiniciarVisitas() {
    for (var i = 0; i < _ubicaciones.length; i++) {
      _ubicaciones[i].visitado = false;
    }
    _rutaOptimizada = List.from(_ubicaciones);
    notifyListeners();
  }
}