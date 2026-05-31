import 'dart:convert';
import 'package:flutter/foundation.dart';  // 👈 AGREGAR ESTA LÍNEA
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_db.dart';
import '../network/network_monitor.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  static SyncService get instance => _instance;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabase _localDb = LocalDatabase.instance;
  
  bool _isSyncing = false;
  
  SyncService._internal();
  
  Future<void> sincronizarPendientes() async {
    if (!NetworkMonitor.instance.isConnected) {
      debugPrint('⚠️ No hay conexión, no se puede sincronizar');
      return;
    }
    
    if (_isSyncing) {
      debugPrint('⚠️ Ya hay una sincronización en curso');
      return;
    }
    
    _isSyncing = true;
    debugPrint('🔄 Iniciando sincronización de datos pendientes...');
    
    try {
      final pendingItems = await _localDb.getPendingSyncItems();
      
      if (pendingItems.isEmpty) {
        debugPrint('✅ No hay datos pendientes para sincronizar');
        _isSyncing = false;
        return;
      }
      
      debugPrint('📤 Sincronizando ${pendingItems.length} elementos...');
      
      for (final item in pendingItems) {
        try {
          final operation = item['operation'];
          final tableName = item['table_name'];
          final recordId = item['record_id'];
          final data = item['data'];
          
          switch (operation) {
            case 'UPDATE':
              await _syncUpdate(tableName, recordId, data);
              break;
            case 'DELETE':
              await _syncDelete(tableName, recordId);
              break;
          }
          
          await _localDb.removeFromSyncQueue(item['id']);
          debugPrint('  ✅ Sincronizado: $tableName/$recordId');
          
        } catch (e) {
          debugPrint('  ❌ Error sincronizando: $e');
          await _localDb.incrementAttempts(item['id']);
        }
      }
      
      debugPrint('✅ Sincronización completada');
      
    } catch (e) {
      debugPrint('❌ Error en sincronización: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> _syncUpdate(String tableName, String recordId, String data) async {
    switch (tableName) {
      case 'cartera_local':
        final Map<String, dynamic> parsedData = Map.from(_parseData(data));
        await _firestore.collection('fichas_campo').doc(recordId).update({
          'estadoFicha': parsedData['estado_visita'],
          'observaciones': parsedData['observacion_visita'],
          'sincronizadaAt': FieldValue.serverTimestamp(),
        });
        break;
    }
  }
  
  Future<void> _syncDelete(String tableName, String recordId) async {
    switch (tableName) {
      case 'cartera_local':
        // No implementar borrado por ahora
        break;
    }
  }
  
  dynamic _parseData(String data) {
    try {
      return jsonDecode(data);
    } catch (e) {
      return data;
    }
  }
}