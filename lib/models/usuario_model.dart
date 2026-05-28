import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String email;
  final String nombre;
  final String apellido;
  final String rol; // 'asesor', 'cliente', 'admin'
  final bool activo;
  final DateTime createdAt;

  UsuarioModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.rol,
    required this.activo,
    required this.createdAt,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UsuarioModel(
      id: doc.id,
      email: data['email'] ?? '',
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      rol: data['rol'] ?? 'cliente',
      activo: data['activo'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'rol': rol,
      'activo': activo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}