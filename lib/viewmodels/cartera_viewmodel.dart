import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/client_model.dart';
import '../core/storage/local_db.dart';

class CarteraViewModel extends ChangeNotifier {
  List<Client> _clients = [];
  List<Client> get clients => _clients;
  
  List<Client> _filteredClients = [];
  List<Client> get filteredClients => _filteredClients;
  
  String _searchQuery = '';
  String _currentFilter = 'Todos';
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isOffline = false;
  bool get isOffline => _isOffline;
  
  String _lastSyncTime = '';
  String get lastSyncTime => _lastSyncTime;
  
  int get totalVisits => _clients.where((c) => c.status == 'pendiente').length;
  int get completedVisits => _clients.where((c) => c.status == 'visitado').length;
  
  double get progress {
    final total = totalVisits + completedVisits;
    return total > 0 ? completedVisits / total : 0;
  }
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabase _localDb = LocalDatabase.instance;
  
  CarteraViewModel() {
    _init();
  }
  
  Future<void> _init() async {
    await cargarDatos();
    _monitorConnectivity();
  }
  
  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) async {
      final hasInternet = !results.contains(ConnectivityResult.none);
      if (hasInternet && _isOffline) {
        debugPrint('🌐 Internet recuperado - Sincronizando...');
        await _sincronizarPendientes();
        await cargarDatos();
      }
      _isOffline = !hasInternet;
      notifyListeners();
    });
  }
  
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
  
  Future<void> cargarDatos() async {
    _isLoading = true;
    notifyListeners();
    
    final hasNetwork = await _hasInternet();
    
    if (!hasNetwork) {
      await _cargarDesdeCacheLocal();
      _isOffline = true;
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    try {
      final snapshot = await _firestore.collection('clientes_perfil').get();
      
      final List<Client> loadedClients = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        final scoreDoc = await _firestore.collection('scores').doc(doc.id).get();
        double score = 0;
        if (scoreDoc.exists) {
          final scoreValue = scoreDoc.data()?['score'];
          if (scoreValue is int) {
            score = scoreValue.toDouble();
          } else if (scoreValue is double) {
            score = scoreValue;
          }
        }
        
        final localStatus = await _getLocalVisitStatus(doc.id);
        
        final client = Client(
          id: doc.id,
          name: '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}'.trim(),
          document: data['dni']?.toString() ?? '---',
          managementType: _determinarTipoGestion(data),
          status: localStatus ?? 'pendiente',
          phone: data['telefono']?.toString() ?? '',
          address: data['direccion']?.toString() ?? '',
          debtAmount: _toDouble(data['deudaActual']),
          score: score,
          visitDate: localStatus != null ? DateTime.now() : null,
        );
        
        loadedClients.add(client);
      }
      
      _clients = loadedClients;
      _lastSyncTime = _formatTime(DateTime.now());
      _applyFiltersAndSearch();
      
      await _guardarEnCacheLocal();
      _isOffline = false;
      
    } catch (e) {
      debugPrint('Error cargando datos: $e');
      await _cargarDesdeCacheLocal();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<String?> _getLocalVisitStatus(String clientId) async {
    try {
      final carteraLocal = await _localDb.getCarteraLocal('asesor_001');
      final local = carteraLocal.firstWhere(
        (c) => c['cliente_id'] == clientId,
        orElse: () => {},
      );
      return local['estado_visita'] == 'visitado' ? 'visitado' : null;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> _guardarEnCacheLocal() async {
    try {
      final clientesData = _clients.map((client) => {
        'id': client.id,
        'asesor_id': 'asesor_001',
        'cliente_id': client.id,
        'cliente_nombre': client.name,
        'cliente_dni': client.document,
        'tipo_gestion': client.managementType,
        'prioridad': getPrioridadText(client),
        'score_prioridad': client.managementType == 'cobranza' ? 85 : (client.managementType == 'renovacion' ? 50 : 25),
        'estado_visita': client.status,
        'monto_solicitado': client.debtAmount,
        'orden_manual': 0,
        'sync_pending': client.status == 'visitado' ? 1 : 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }).toList();
      
      await _localDb.saveCarteraLocal(clientesData);
      debugPrint('✅ ${clientesData.length} clientes guardados en caché local');
    } catch (e) {
      debugPrint('❌ Error guardando en caché: $e');
    }
  }
  
  Future<void> _cargarDesdeCacheLocal() async {
    try {
      final cachedData = await _localDb.getCarteraLocal('asesor_001');
      
      if (cachedData.isNotEmpty) {
        _clients = cachedData.map((item) => Client(
          id: item['cliente_id'],
          name: item['cliente_nombre'],
          document: item['cliente_dni'],
          managementType: item['tipo_gestion'],
          status: item['estado_visita'],
          phone: '',
          address: '',
          debtAmount: (item['monto_solicitado'] ?? 0).toDouble(),
          visitDate: item['estado_visita'] == 'visitado' ? DateTime.now() : null,
        )).toList();
        
        _applyFiltersAndSearch();
        _isOffline = true;
        debugPrint('✅ ${_clients.length} clientes cargados desde caché local (modo offline)');
      } else {
        debugPrint('⚠️ No hay datos en caché local');
      }
    } catch (e) {
      debugPrint('❌ Error cargando desde caché: $e');
    }
  }
  
  Future<void> _sincronizarPendientes() async {
    try {
      final pendingItems = await _localDb.getPendingSyncItems();
      
      if (pendingItems.isEmpty) return;
      
      debugPrint('📤 Sincronizando ${pendingItems.length} visitas pendientes...');
      
      for (final item in pendingItems) {
        try {
          final syncData = item['data'] as Map<String, dynamic>;
          
          await _firestore.collection('fichas_campo').add({
            'clienteId': syncData['clientId'],
            'asesorId': 'asesor_001',
            'estado': 'visitado',
            'observacion': syncData['observacion'],
            'fechaVisita': FieldValue.serverTimestamp(),
            'sincronizado': true,
          });
          
          await _localDb.removeFromSyncQueue(item['id']);
          debugPrint('  ✅ Sincronizado: ${syncData['clientId']}');
          
        } catch (e) {
          debugPrint('  ❌ Error sincronizando: $e');
          await _localDb.incrementAttempts(item['id']);
        }
      }
      
      debugPrint('✅ Sincronización completada');
    } catch (e) {
      debugPrint('❌ Error en sincronización: $e');
    }
  }
  
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0.0;
  }
  
  String _determinarTipoGestion(Map<String, dynamic> data) {
    final deuda = _toDouble(data['deudaActual']);
    final tipoNegocio = data['tipoNegocio']?.toString().toLowerCase() ?? '';
    
    if (deuda > 0) {
      return 'cobranza';
    }
    
    if (tipoNegocio == 'renovacion' || tipoNegocio.contains('renov')) {
      return 'renovacion';
    }
    
    return 'nuevo';
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  void setFilter(String filter) {
    _currentFilter = filter;
    _applyFiltersAndSearch();
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSearch();
    notifyListeners();
  }
  
  void _applyFiltersAndSearch() {
    var filtered = List<Client>.from(_clients);
    
    switch (_currentFilter) {
      case 'Renovaciones':
        filtered = filtered.where((c) => c.managementType == 'renovacion').toList();
        break;
      case 'Nuevas':
        filtered = filtered.where((c) => c.managementType == 'nuevo').toList();
        break;
      case 'En mora':
        filtered = filtered.where((c) => c.managementType == 'cobranza').toList();
        break;
      case 'Visitados':
        filtered = filtered.where((c) => c.status == 'visitado').toList();
        break;
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        final nombreMatch = c.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final dniMatch = c.document.endsWith(_searchQuery);
        return nombreMatch || dniMatch;
      }).toList();
    }
    
    filtered.sort((a, b) {
      if (a.status == 'visitado' && b.status != 'visitado') return 1;
      if (a.status != 'visitado' && b.status == 'visitado') return -1;
      return 0;
    });
    
    _filteredClients = filtered;
  }
  
  String getCensoredDni(String dni) {
    if (dni.length <= 4) return dni;
    final last4 = dni.substring(dni.length - 4);
    return '***$last4';
  }
  
  String getPrioridadText(Client client) {
    if (client.managementType == 'cobranza') return 'ALTA';
    if (client.managementType == 'renovacion') return 'MEDIA';
    return 'NORMAL';
  }
  
  Color getPrioridadColor(Client client) {
    final prioridad = getPrioridadText(client);
    switch (prioridad) {
      case 'ALTA': return Colors.red;
      case 'MEDIA': return Colors.orange;
      default: return Colors.green;
    }
  }
  
  void reordenarManual(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    
    final List<Client> newOrder = List.from(_filteredClients);
    final client = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, client);
    
    _filteredClients = newOrder;
    
    for (int i = 0; i < newOrder.length; i++) {
      final clientId = newOrder[i].id;
      final originalIndex = _clients.indexWhere((c) => c.id == clientId);
      if (originalIndex != -1) {
        _clients[originalIndex] = newOrder[i];
      }
    }
    
    notifyListeners();
  }
  
  Future<void> markAsVisited(String clientId, {String? observacion}) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index != -1) {
      _clients[index] = Client(
        id: _clients[index].id,
        name: _clients[index].name,
        document: _clients[index].document,
        managementType: _clients[index].managementType,
        status: 'visitado',
        phone: _clients[index].phone,
        address: _clients[index].address,
        debtAmount: _clients[index].debtAmount,
        score: _clients[index].score,
        visitDate: DateTime.now(),
      );
      
      _applyFiltersAndSearch();
      await _guardarEnCacheLocal();
      notifyListeners();
      
      final hasNetwork = await _hasInternet();
      
      final syncData = {
        'clienteId': clientId,
        'clienteNombre': _clients[index].name,
        'observacion': observacion ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (hasNetwork) {
        try {
          // Guardar con estructura correcta
          await _firestore.collection('fichas_campo').add({
            'clienteId': clientId,
            'clienteNombre': _clients[index].name,
            'asesorId': 'asesor_001',
            'estado': 'visitado',           // 👈 Campo correcto
            'observacion': observacion ?? '',
            'fechaVisita': FieldValue.serverTimestamp(),
            'sincronizado': true,
          });
          debugPrint('✅ Visita sincronizada con Firestore');
        } catch (e) {
          debugPrint('❌ Error sincronizando: $e - Guardando en cola');
          await _localDb.addToSyncQueue(
            operation: 'UPDATE',
            tableName: 'cartera_local',
            recordId: clientId,
            data: syncData,
          );
        }
      } else {
        debugPrint('📱 Modo offline - Visita guardada en cola local');
        await _localDb.addToSyncQueue(
          operation: 'UPDATE',
          tableName: 'cartera_local',
          recordId: clientId,
          data: syncData,
        );
      }
    }
  }
}