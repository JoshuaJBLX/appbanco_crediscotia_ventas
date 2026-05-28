import 'package:cloud_firestore/cloud_firestore.dart';

class ClientePerfilModel {
  final String userId;
  final String nombres;
  final String apellidos;
  final String dni;
  final String tipoNegocio;
  final int antiguedadNegocio;
  final bool localPropio;
  final String zonaNegocio;
  final double ingresoMensualEst;
  final double gastoMensualEst;
  final double deudaActual;
  final int entidadesDeuda;
  final String estadoCliente;

  ClientePerfilModel({
    required this.userId,
    required this.nombres,
    required this.apellidos,
    required this.dni,
    required this.tipoNegocio,
    required this.antiguedadNegocio,
    required this.localPropio,
    required this.zonaNegocio,
    required this.ingresoMensualEst,
    required this.gastoMensualEst,
    required this.deudaActual,
    required this.entidadesDeuda,
    required this.estadoCliente,
  });

  String get nombreCompleto => '$nombres $apellidos';
  double get capacidadPago => ingresoMensualEst - gastoMensualEst;

  factory ClientePerfilModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientePerfilModel(
      userId: doc.id,
      nombres: data['nombres'] ?? '',
      apellidos: data['apellidos'] ?? '',
      dni: data['dni'] ?? '',
      tipoNegocio: data['tipoNegocio'] ?? '',
      antiguedadNegocio: data['antiguedadNegocio'] ?? 0,
      localPropio: data['localPropio'] ?? false,
      zonaNegocio: data['zonaNegocio'] ?? 'urbano',
      ingresoMensualEst: (data['ingresoMensualEst'] ?? 0).toDouble(),
      gastoMensualEst: (data['gastoMensualEst'] ?? 0).toDouble(),
      deudaActual: (data['deudaActual'] ?? 0).toDouble(),
      entidadesDeuda: data['entidadesDeuda'] ?? 0,
      estadoCliente: data['estadoCliente'] ?? 'prospecto',
    );
  }
}