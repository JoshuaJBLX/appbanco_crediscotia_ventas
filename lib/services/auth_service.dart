import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hashear contraseña usando SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verificar si la contraseña es correcta
  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  /// Login con código de asesor y contraseña
  static Future<Map<String, dynamic>> login({
    required String codigoAsesor,
    required String password,
  }) async {
    try {
      // 1. Buscar asesor por código
      final asesorQuery = await _firestore
          .collection('asesores')
          .where('codigoAsesor', isEqualTo: codigoAsesor)
          .where('activo', isEqualTo: true)
          .limit(1)
          .get();

      if (asesorQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Código de asesor no encontrado',
        };
      }

      final asesorDoc = asesorQuery.docs.first;
      final asesorData = asesorDoc.data();
      final userId = asesorData['userId'];

      // 2. Obtener usuario
      final userDoc = await _firestore.collection('usuarios').doc(userId).get();
      
      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'Usuario no encontrado',
        };
      }

      final userData = userDoc.data()!;
      
      // 3. Verificar contraseña (hash)
      final storedHash = userData['passwordHash'] ?? '';
      
      if (storedHash.isEmpty) {
        return {
          'success': false,
          'message': 'Usuario no tiene contraseña configurada',
        };
      }

      if (!verifyPassword(password, storedHash)) {
        return {
          'success': false,
          'message': 'Contraseña incorrecta',
        };
      }

      // 4. Login exitoso
      return {
        'success': true,
        'data': {
          'asesorId': asesorDoc.id,
          'userId': userId,
          'codigo': asesorData['codigoAsesor'],
          'nombre': '${userData['nombre']} ${userData['apellido']}',
          'email': userData['email'],
          'rol': userData['rol'],
          'agenciaId': asesorData['agenciaId'],
        }
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  /// Crear/actualizar contraseña de un usuario (para administradores)
  static Future<bool> setPassword(String userId, String newPassword) async {
    try {
      final passwordHash = hashPassword(newPassword);
      
      await _firestore.collection('usuarios').doc(userId).update({
        'passwordHash': passwordHash,
        'hasPassword': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error al guardar contraseña: $e');
      return false;
    }
  }

  /// Cambiar contraseña (requiere verificar la actual)
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Obtener usuario actual
      final userDoc = await _firestore.collection('usuarios').doc(userId).get();
      
      if (!userDoc.exists) {
        return {'success': false, 'message': 'Usuario no encontrado'};
      }

      final userData = userDoc.data()!;
      final storedHash = userData['passwordHash'] ?? '';

      // Verificar contraseña actual
      if (!verifyPassword(currentPassword, storedHash)) {
        return {'success': false, 'message': 'Contraseña actual incorrecta'};
      }

      // Actualizar con nueva contraseña
      final newHash = hashPassword(newPassword);
      await _firestore.collection('usuarios').doc(userId).update({
        'passwordHash': newHash,
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Contraseña actualizada'};

    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}