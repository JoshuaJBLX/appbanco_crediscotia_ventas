import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AsesorDashboardViewModel extends ChangeNotifier {
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? get dashboard => _dashboard;

  String _asesorId = '';
  String get asesorId => _asesorId;

  String _nombreAsesor = '';
  String get nombreAsesor => _nombreAsesor;

  String _codigoAsesor = '';
  String get codigoAsesor => _codigoAsesor;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> cargarDashboard(String asesorId) async {
    _asesorId = asesorId;

    try {
      final asesorDoc = await _firestore.collection('asesores').doc(asesorId).get();
      
      if (asesorDoc.exists) {
        final asesorData = asesorDoc.data()!;
        _codigoAsesor = asesorData['codigoAsesor'] ?? '';
        
        final userId = asesorData['userId'];
        final userDoc = await _firestore.collection('usuarios').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _nombreAsesor = '${userData['nombre']} ${userData['apellido']}';
        }

        // Convertir todo a double
        final metaVisitas = (asesorData['metaVisitasMes'] ?? 80).toDouble();
        final metaCreditos = (asesorData['metaCreditosMes'] ?? 25).toDouble();
        final metaMonto = (asesorData['metaMontoMes'] ?? 0.0).toDouble();
        final visitasActual = (asesorData['visitasMesActual'] ?? 0).toDouble();
        final creditosActual = (asesorData['creditosMesActual'] ?? 0).toDouble();
        final montoActual = (asesorData['montoMesActual'] ?? 0.0).toDouble();

        // Visitas de hoy - simplificado para evitar índice
        final visitasHoy = await _firestore
            .collection('fichas_campo')
            .where('asesorId', isEqualTo: asesorId)
            .get();

        _dashboard = {
          'metaVisitasMes': metaVisitas,
          'metaCreditosMes': metaCreditos,
          'metaMontoMes': metaMonto,
          'visitasMesActual': visitasActual,
          'creditosMesActual': creditosActual,
          'montoMesActual': montoActual,
          'pctVisitas': metaVisitas > 0 ? (visitasActual * 100 / metaVisitas) : 0.0,
          'pctCreditos': metaCreditos > 0 ? (creditosActual * 100 / metaCreditos) : 0.0,
          'pctMonto': metaMonto > 0 ? (montoActual * 100 / metaMonto) : 0.0,
          'visitasHoy': visitasHoy.docs.length.toDouble(),
        };
      } else {
        _dashboard = _getDefaultDashboard();
      }
    } catch (e) {
      debugPrint('Error cargando dashboard: $e');
      _dashboard = _getDefaultDashboard();
    }
    
    notifyListeners();
  }

  Map<String, dynamic> _getDefaultDashboard() {
    return {
      'metaVisitasMes': 80.0,
      'metaCreditosMes': 25.0,
      'metaMontoMes': 150000.0,
      'visitasMesActual': 0.0,
      'creditosMesActual': 0.0,
      'montoMesActual': 0.0,
      'pctVisitas': 0.0,
      'pctCreditos': 0.0,
      'pctMonto': 0.0,
      'visitasHoy': 0.0,
    };
  }
}