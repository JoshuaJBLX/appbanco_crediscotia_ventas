import 'package:cloud_firestore/cloud_firestore.dart';

class OficialModel {
  final String id;
  final String codigo;
  final String password;
  final String nombre;
  final String email;
  final String rol;

  OficialModel({
    required this.id,
    required this.codigo,
    required this.password,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory OficialModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OficialModel(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      password: data['password'] ?? '',
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'oficial',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'codigo': codigo,
      'password': password,
      'nombre': nombre,
      'email': email,
      'rol': rol,
    };
  }
}