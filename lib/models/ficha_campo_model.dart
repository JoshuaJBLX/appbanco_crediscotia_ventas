import 'package:cloud_firestore/cloud_firestore.dart';

class FichaCampoModel {
  final String? id;
  final String asesorId;
  final String? clienteUserId;
  final double latitud;
  final double longitud;
  final String distrito;
  final String tipoVisita;
  final String negocioNombre;
  final String negocioRubro;
  final double ingresoDeclarado;
  final double gastoDeclarado;
  final double montoSolicitado;
  final String observaciones;
  final bool creadaOffline;
  final String estadoFicha;
  final double? scoreObtenido;
  final DateTime? createdAt;

  FichaCampoModel({
    this.id,
    required this.asesorId,
    this.clienteUserId,
    required this.latitud,
    required this.longitud,
    required this.distrito,
    required this.tipoVisita,
    required this.negocioNombre,
    required this.negocioRubro,
    required this.ingresoDeclarado,
    required this.gastoDeclarado,
    required this.montoSolicitado,
    required this.observaciones,
    this.creadaOffline = false,
    this.estadoFicha = 'borrador',
    this.scoreObtenido,
    this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'asesorId': asesorId,
      if (clienteUserId != null) 'clienteUserId': clienteUserId,
      'latitud': latitud,
      'longitud': longitud,
      'distrito': distrito,
      'tipoVisita': tipoVisita,
      'negocioNombre': negocioNombre,
      'negocioRubro': negocioRubro,
      'ingresoDeclarado': ingresoDeclarado,
      'gastoDeclarado': gastoDeclarado,
      'montoSolicitado': montoSolicitado,
      'observaciones': observaciones,
      'creadaOffline': creadaOffline,
      'estadoFicha': estadoFicha,
      if (scoreObtenido != null) 'scoreObtenido': scoreObtenido,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory FichaCampoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FichaCampoModel(
      id: doc.id,
      asesorId: data['asesorId'] ?? '',
      clienteUserId: data['clienteUserId'],
      latitud: (data['latitud'] ?? 0).toDouble(),
      longitud: (data['longitud'] ?? 0).toDouble(),
      distrito: data['distrito'] ?? '',
      tipoVisita: data['tipoVisita'] ?? 'prospeccion',
      negocioNombre: data['negocioNombre'] ?? '',
      negocioRubro: data['negocioRubro'] ?? '',
      ingresoDeclarado: (data['ingresoDeclarado'] ?? 0).toDouble(),
      gastoDeclarado: (data['gastoDeclarado'] ?? 0).toDouble(),
      montoSolicitado: (data['montoSolicitado'] ?? 0).toDouble(),
      observaciones: data['observaciones'] ?? '',
      creadaOffline: data['creadaOffline'] ?? false,
      estadoFicha: data['estadoFicha'] ?? 'borrador',
      scoreObtenido: data['scoreObtenido']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}