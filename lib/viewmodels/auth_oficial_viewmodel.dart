import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

enum AuthState {
  initial,
  loading,
  success,
  error,
}

class AuthOficialViewModel extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  AuthState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> login(String employeeCode, String password) async {
    _state = AuthState.loading;
    notifyListeners();

    // Validaciones básicas
    if (employeeCode.isEmpty || password.isEmpty) {
      _state = AuthState.error;
      _errorMessage = 'Ingrese código y contraseña';
      notifyListeners();
      return;
    }

    // Llamar al servicio de autenticación
    final result = await AuthService.login(
      codigoAsesor: employeeCode,
      password: password,
    );

    if (result['success'] == true) {
      final data = result['data'];
      
      // Guardar sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('asesor_id', data['asesorId']);
      await prefs.setString('asesor_nombre', data['nombre']);
      await prefs.setString('asesor_codigo', data['codigo']);
      await prefs.setString('user_id', data['userId']);

      _state = AuthState.success;
      _errorMessage = '';
    } else {
      _state = AuthState.error;
      _errorMessage = result['message'];
    }
    
    notifyListeners();
  }

  void resetState() {
    _state = AuthState.initial;
    _errorMessage = '';
    notifyListeners();
  }
}