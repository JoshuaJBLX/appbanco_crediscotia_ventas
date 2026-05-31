import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkMonitor extends ChangeNotifier {
  static final NetworkMonitor _instance = NetworkMonitor._internal();
  static NetworkMonitor get instance => _instance;
  
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;
  
  NetworkMonitor._internal() {
    _init();
  }
  
  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
    
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }
  
  void _updateStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    
    _isConnected = !results.contains(ConnectivityResult.none);
    _hasInternet = _isConnected;
    
    if (wasConnected != _isConnected) {
      notifyListeners();
      
      if (_isConnected) {
        _onReconnected();
      } else {
        _onDisconnected();
      }
    }
  }
  
  void _onReconnected() {
    debugPrint('✅ Conexión de red restaurada');
    // Notificar a los servicios que deben sincronizar
    // Usar importación completa para evitar conflicto
    // SyncService.instance.sincronizarPendientes();
  }
  
  void _onDisconnected() {
    debugPrint('⚠️ Sin conexión de red - Modo offline activado');
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
