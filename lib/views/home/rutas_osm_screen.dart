import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../services/osrm_service.dart';

class RutasOsmScreen extends StatefulWidget {
  const RutasOsmScreen({super.key});

  @override
  State<RutasOsmScreen> createState() => _RutasOsmScreenState();
}

class _RutasOsmScreenState extends State<RutasOsmScreen> {
  bool _isLoading = true;
  final MapController _mapController = MapController();
  List<Marker> _marcadores = [];
  final List<Polyline> _polilineas = [];
  
  final List<Map<String, dynamic>> _ubicaciones = [
    {'nombre': 'Rosa Condori', 'prioridad': 'ALTA', 'tipo': 'Cobranza', 'lat': -12.0653, 'lng': -75.2049},
    {'nombre': 'Juan Huanca', 'prioridad': 'ALTA', 'tipo': 'Cobranza', 'lat': -12.0445, 'lng': -75.2112},
    {'nombre': 'María Paucar', 'prioridad': 'ALTA', 'tipo': 'Cobranza', 'lat': -12.0820, 'lng': -75.2120},
  ];
  
  List<Map<String, dynamic>> _rutaOptimizada = [];

  @override
  void initState() {
    super.initState();
    _rutaOptimizada = List.from(_ubicaciones);
    _cargarMarcadores();
    _cargarRutaInicial();
    _isLoading = false;
  }

  void _cargarMarcadores() {
    _marcadores = [];
    for (var ubicacion in _ubicaciones) {
      _marcadores.add(
        Marker(
          width: 80,
          height: 80,
          point: LatLng(ubicacion['lat']!, ubicacion['lng']!),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ubicacion['nombre']!,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const Icon(Icons.location_pin, color: Colors.red, size: 30),
            ],
          ),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _cargarRutaInicial() async {
    await _dibujarRutaReal();
    if (mounted) {
      setState(() {});
    }
  }
  
  Future<void> _dibujarRutaReal() async {
    if (_rutaOptimizada.length < 2) return;
    
    _polilineas.clear();
    
    for (int i = 0; i < _rutaOptimizada.length - 1; i++) {
      final origen = _rutaOptimizada[i];
      final destino = _rutaOptimizada[i + 1];
      
      final puntos = await OsrmService.getRoutePolyline(
        originLat: origen['lat']!,
        originLng: origen['lng']!,
        destLat: destino['lat']!,
        destLng: destino['lng']!,
      );
      
      if (puntos.isNotEmpty) {
        _polilineas.add(
          Polyline(
            points: puntos,
            color: CrediscotiaTheme.primary,
            strokeWidth: 4,
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }
  
  LatLngBounds _getBounds() {
    double minLat = _rutaOptimizada.first['lat']!;
    double maxLat = _rutaOptimizada.first['lat']!;
    double minLng = _rutaOptimizada.first['lng']!;
    double maxLng = _rutaOptimizada.first['lng']!;
    
    for (final ubicacion in _rutaOptimizada) {
      minLat = minLat < ubicacion['lat']! ? minLat : ubicacion['lat']!;
      maxLat = maxLat > ubicacion['lat']! ? maxLat : ubicacion['lat']!;
      minLng = minLng < ubicacion['lng']! ? minLng : ubicacion['lng']!;
      maxLng = maxLng > ubicacion['lng']! ? maxLng : ubicacion['lng']!;
    }
    
    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-12.0653, -75.2049),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.appbanco_crediscotia_ventas',
              ),
              MarkerLayer(markers: _marcadores),
              PolylineLayer(polylines: _polilineas),
            ],
          ),
          
          // Panel superior
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3 pendientes',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '3 en ruta',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ruta optimizada')),
                        );
                      },
                      icon: const Icon(Icons.route, size: 18),
                      label: const Text('Optimizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CrediscotiaTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Lista horizontal
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _rutaOptimizada.length,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemBuilder: (context, index) {
                  final ubicacion = _rutaOptimizada[index];
                  
                  return GestureDetector(
                    onTap: () {
                      _mapController.move(
                        LatLng(ubicacion['lat']!, ubicacion['lng']!),
                        15,
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 8),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ubicacion['nombre']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      ubicacion['tipo']!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}