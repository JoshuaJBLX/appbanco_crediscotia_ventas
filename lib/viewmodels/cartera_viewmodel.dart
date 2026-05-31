import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_model.dart';

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
  
  Future<void> cargarDatos() async {
    _isLoading = true;
    notifyListeners();
    
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
        
        final client = Client(
          id: doc.id,
          name: '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}'.trim(),
          document: data['dni']?.toString() ?? '---',
          managementType: _determinarTipoGestion(data),
          status: 'pendiente',
          phone: data['telefono']?.toString() ?? '',
          address: data['direccion']?.toString() ?? '',
          debtAmount: _toDouble(data['deudaActual']),
          score: score,
        );
        
        loadedClients.add(client);
      }
      
      _clients = loadedClients;
      _lastSyncTime = _formatTime(DateTime.now());
      _applyFiltersAndSearch();
      
    } catch (e) {
      debugPrint('Error cargando datos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      notifyListeners();
      
      debugPrint('Visita marcada: $clientId - Observación: $observacion');
    }
  }
}