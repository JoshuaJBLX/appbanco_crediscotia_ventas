import 'package:cloud_firestore/cloud_firestore.dart';

class AsesorModel {
  final String id;
  final String userId;
  final String agenciaId;
  final String codigoAsesor;
  final String especialidad;
  final String zonaAsignada;
  final bool activo;
  final int metaVisitasMes;
  final int metaCreditosMes;
  final double metaMontoMes;
  final int visitasMesActual;
  final int creditosMesActual;
  final double montoMesActual;

  AsesorModel({
    required this.id,
    required this.userId,
    required this.agenciaId,
    required this.codigoAsesor,
    required this.especialidad,
    required this.zonaAsignada,
    required this.activo,
    required this.metaVisitasMes,
    required this.metaCreditosMes,
    required this.metaMontoMes,
    required this.visitasMesActual,
    required this.creditosMesActual,
    required this.montoMesActual,
  });

  factory AsesorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AsesorModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      agenciaId: data['agenciaId'] ?? '',
      codigoAsesor: data['codigoAsesor'] ?? '',
      especialidad: data['especialidad'] ?? 'microempresa',
      zonaAsignada: data['zonaAsignada'] ?? '',
      activo: data['activo'] ?? true,
      metaVisitasMes: data['metaVisitasMes'] ?? 80,
      metaCreditosMes: data['metaCreditosMes'] ?? 25,
      metaMontoMes: (data['metaMontoMes'] ?? 150000).toDouble(),
      visitasMesActual: data['visitasMesActual'] ?? 0,
      creditosMesActual: data['creditosMesActual'] ?? 0,
      montoMesActual: (data['montoMesActual'] ?? 0).toDouble(),
    );
  }

  double get pctVisitas => metaVisitasMes > 0
      ? (visitasMesActual * 100 / metaVisitasMes)
      : 0;

  double get pctCreditos => metaCreditosMes > 0
      ? (creditosMesActual * 100 / metaCreditosMes)
      : 0;

  double get pctMonto => metaMontoMes > 0
      ? (montoMesActual * 100 / metaMontoMes)
      : 0;
}