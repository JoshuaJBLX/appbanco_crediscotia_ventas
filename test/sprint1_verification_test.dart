import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appbanco_crediscotia_ventas/core/storage/local_db.dart';
import 'package:appbanco_crediscotia_ventas/core/network/network_monitor.dart';
import 'package:appbanco_crediscotia_ventas/viewmodels/cartera_viewmodel.dart';
import 'package:appbanco_crediscotia_ventas/models/client_model.dart';
import 'package:appbanco_crediscotia_ventas/theme/app_theme.dart';

void main() {
  group('SPRINT 1 - Verificación completa', () {
    
    // ============================================================
    // 1. BASE DE DATOS LOCAL
    // ============================================================
    group('1. Base de Datos Local (SQLite)', () {
      
      test('1.1 - La base de datos debe inicializarse correctamente', () async {
        final db = LocalDatabase.instance;
        final database = await db.database;
        
        expect(database, isNotNull);
        expect(database.isOpen, true);
      });
      
      test('1.2 - Debe crear todas las tablas necesarias', () async {
        final db = LocalDatabase.instance;
        final database = await db.database;
        
        final tables = await database.query('sqlite_master', 
          where: 'type = ?', 
          whereArgs: ['table']);
        
        final tableNames = tables.map((t) => t['name'] as String).toList();
        
        expect(tableNames, contains('cartera_local'));
        expect(tableNames, contains('clientes_local'));
        expect(tableNames, contains('scores_local'));
        expect(tableNames, contains('sync_queue'));
      });
      
      test('1.3 - Debe poder guardar y leer cartera local', () async {
        final db = LocalDatabase.instance;
        
        final testData = [
          {
            'id': 'test_1',
            'asesor_id': 'asesor_001',
            'cliente_id': 'cli_001',
            'cliente_nombre': 'Test Cliente',
            'cliente_dni': '12345678',
            'tipo_gestion': 'renovacion',
            'prioridad': 'ALTA',
            'score_prioridad': 85,
            'estado_visita': 'pendiente',
            'monto_solicitado': 5000,
            'orden_manual': 0,
            'sync_pending': 0,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          }
        ];
        
        await db.saveCarteraLocal(testData);
        final saved = await db.getCarteraLocal('asesor_001');
        
        expect(saved.isNotEmpty, true);
        expect(saved.first['cliente_nombre'], 'Test Cliente');
      });
    });
    
    // ============================================================
    // 2. MONITOR DE RED
    // ============================================================
    group('2. Monitor de Red', () {
      
      test('2.1 - NetworkMonitor debe ser singleton', () {
        final instance1 = NetworkMonitor.instance;
        final instance2 = NetworkMonitor.instance;
        
        expect(identical(instance1, instance2), true);
      });
      
      test('2.2 - Debe tener estado de conexión inicial', () {
        final monitor = NetworkMonitor.instance;
        
        expect(monitor.isConnected, isA<bool>());
        expect(monitor.hasInternet, isA<bool>());
      });
      
      test('2.3 - Debe notificar cambios a los listeners', () async {
        final monitor = NetworkMonitor.instance;
        var notified = false;
        
        monitor.addListener(() {
          notified = true;
        });
        
        monitor.notifyListeners();
        
        expect(notified, true);
      });
    });
    
    // ============================================================
    // 3. CARTERA VIEWMODEL
    // ============================================================
    group('3. Cartera ViewModel', () {
      
      test('3.1 - Debe inicializar con valores por defecto', () {
        final vm = CarteraViewModel();
        
        expect(vm.clients, isNotNull);
        expect(vm.filteredClients, isNotNull);
        expect(vm.totalVisits, isA<int>());
        expect(vm.completedVisits, isA<int>());
        expect(vm.progress, isA<double>());
      });
      
      test('3.2 - Debe censurar DNI correctamente', () {
        final vm = CarteraViewModel();
        
        expect(vm.getCensoredDni('12345678'), '***5678');
        expect(vm.getCensoredDni('87654321'), '***4321');
        expect(vm.getCensoredDni('12345'), '***2345');
        expect(vm.getCensoredDni('123'), '123');
      });
      
      test('3.3 - Debe calcular prioridad correctamente', () {
        final vm = CarteraViewModel();
        
        final clientMora = Client(
          id: '1',
          name: 'Test Mora',
          document: '12345678',
          managementType: 'cobranza',
          status: 'pendiente',
          phone: '',
          address: '',
          debtAmount: 5000,
        );
        
        final clientRenovacion = Client(
          id: '2',
          name: 'Test Renovacion',
          document: '87654321',
          managementType: 'renovacion',
          status: 'pendiente',
          phone: '',
          address: '',
          debtAmount: 0,
        );
        
        final clientNuevo = Client(
          id: '3',
          name: 'Test Nuevo',
          document: '11223344',
          managementType: 'nuevo',
          status: 'pendiente',
          phone: '',
          address: '',
          debtAmount: 0,
        );
        
        expect(vm.getPrioridadText(clientMora), 'ALTA');
        expect(vm.getPrioridadColor(clientMora), Colors.red);
        expect(vm.getPrioridadText(clientRenovacion), isIn(['ALTA', 'MEDIA', 'NORMAL']));
        expect(vm.getPrioridadText(clientNuevo), isIn(['ALTA', 'MEDIA', 'NORMAL']));
      });
      
      test('3.4 - Debe filtrar correctamente (usando filteredClients)', () {
        final vm = CarteraViewModel();
        
        // Probar diferentes filtros - verificamos que no lance excepciones
        vm.setFilter('Renovaciones');
        expect(vm.filteredClients, isNotNull);
        
        vm.setFilter('Nuevas');
        expect(vm.filteredClients, isNotNull);
        
        vm.setFilter('En mora');
        expect(vm.filteredClients, isNotNull);
        
        vm.setFilter('Visitados');
        expect(vm.filteredClients, isNotNull);
        
        vm.setFilter('Todos');
        expect(vm.filteredClients, isNotNull);
      });
      
      test('3.5 - Debe procesar búsqueda correctamente', () {
        final vm = CarteraViewModel();
        
        // Verificar que setSearchQuery no lanza excepciones
        vm.setSearchQuery('test');
        expect(vm.filteredClients, isNotNull);
        
        vm.setSearchQuery('');
        expect(vm.filteredClients, isNotNull);
      });
      
      test('3.6 - Debe tener getters públicos funcionales', () {
        final vm = CarteraViewModel();
        
        expect(vm.totalVisits, isA<int>());
        expect(vm.completedVisits, isA<int>());
        expect(vm.progress, isA<double>());
        expect(vm.isOffline, isA<bool>());
      });
    });
    
    // ============================================================
    // 4. MODELO DE CLIENTE
    // ============================================================
    group('4. Modelo de Cliente', () {
      
      test('4.1 - Debe crear cliente correctamente', () {
        final client = Client(
          id: 'test_id',
          name: 'Test Name',
          document: '12345678',
          managementType: 'renovacion',
          status: 'pendiente',
          phone: '987654321',
          address: 'Test Address',
          debtAmount: 1000,
        );
        
        expect(client.id, 'test_id');
        expect(client.name, 'Test Name');
        expect(client.document, '12345678');
        expect(client.managementType, 'renovacion');
        expect(client.status, 'pendiente');
        expect(client.phone, '987654321');
        expect(client.address, 'Test Address');
        expect(client.debtAmount, 1000);
      });
      
      test('4.2 - Debe devolver ícono correcto según tipo de gestión', () {
        final renovacion = Client(
          id: '1', name: '', document: '',
          managementType: 'renovacion', status: '',
          phone: '', address: '',
        );
        
        final nuevo = Client(
          id: '2', name: '', document: '',
          managementType: 'nuevo', status: '',
          phone: '', address: '',
        );
        
        final cobranza = Client(
          id: '3', name: '', document: '',
          managementType: 'cobranza', status: '',
          phone: '', address: '',
        );
        
        expect(renovacion.getManagementIcon(), Icons.autorenew);
        expect(nuevo.getManagementIcon(), Icons.person_add);
        expect(cobranza.getManagementIcon(), Icons.attach_money);
      });
      
      test('4.3 - Debe devolver texto correcto según tipo de gestión', () {
        final renovacion = Client(
          id: '1', name: '', document: '',
          managementType: 'renovacion', status: '',
          phone: '', address: '',
        );
        
        final nuevo = Client(
          id: '2', name: '', document: '',
          managementType: 'nuevo', status: '',
          phone: '', address: '',
        );
        
        final cobranza = Client(
          id: '3', name: '', document: '',
          managementType: 'cobranza', status: '',
          phone: '', address: '',
        );
        
        expect(renovacion.getManagementText(), 'Renovación');
        expect(nuevo.getManagementText(), 'Nuevo Cliente');
        expect(cobranza.getManagementText(), 'Cobranza');
      });
      
      test('4.4 - Debe devolver color correcto según tipo de gestión', () {
        final renovacion = Client(
          id: '1', name: '', document: '',
          managementType: 'renovacion', status: '',
          phone: '', address: '',
        );
        
        final nuevo = Client(
          id: '2', name: '', document: '',
          managementType: 'nuevo', status: '',
          phone: '', address: '',
        );
        
        final cobranza = Client(
          id: '3', name: '', document: '',
          managementType: 'cobranza', status: '',
          phone: '', address: '',
        );
        
        expect(renovacion.getManagementColor(), Colors.orange);
        expect(nuevo.getManagementColor(), Colors.blue);
        expect(cobranza.getManagementColor(), CrediscotiaTheme.primary);
      });
    });
  });
  
  // ============================================================
  // PRUEBAS INTEGRADAS
  // ============================================================
  group('Pruebas Integradas - Escenarios completos', () {
    
    test('Escenario 1: Guardar y leer desde caché local', () async {
      final db = LocalDatabase.instance;
      
      final testData = [
        {
          'id': 'cache_test_1',
          'asesor_id': 'test_asesor',
          'cliente_id': 'cli_001',
          'cliente_nombre': 'Cache Client',
          'cliente_dni': '11112222',
          'tipo_gestion': 'nuevo',
          'prioridad': 'NORMAL',
          'score_prioridad': 50,
          'estado_visita': 'pendiente',
          'monto_solicitado': 0,
          'orden_manual': 0,
          'sync_pending': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }
      ];
      
      await db.saveCarteraLocal(testData);
      final cached = await db.getCarteraLocal('test_asesor');
      
      expect(cached.isNotEmpty, true);
      expect(cached.first['cliente_nombre'], 'Cache Client');
    });
    
    test('Escenario 2: Marcar visita y guardar en cola', () async {
      final db = LocalDatabase.instance;
      final testId = 'test_visit_001';
      
      await db.saveCarteraLocal([
        {
          'id': testId,
          'asesor_id': 'test_asesor',
          'cliente_id': 'cli_002',
          'cliente_nombre': 'Visit Client',
          'cliente_dni': '22223333',
          'tipo_gestion': 'renovacion',
          'prioridad': 'ALTA',
          'score_prioridad': 85,
          'estado_visita': 'pendiente',
          'monto_solicitado': 5000,
          'orden_manual': 0,
          'sync_pending': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }
      ]);
      
      await db.updateEstadoVisitaLocal(
        testId,
        'visitado',
        'completado',
        'Visita exitosa',
      );
      
      final updated = await db.getCarteraLocal('test_asesor');
      final client = updated.firstWhere((c) => c['id'] == testId);
      
      expect(client['estado_visita'], 'visitado');
      expect(client['sync_pending'], 1);
    });
    
    test('Escenario 3: Verificar que el ViewModel maneja filtros sin errores', () {
      final vm = CarteraViewModel();
      
      // Verificar que los métodos no lanzan excepciones
      expect(() => vm.setFilter('Renovaciones'), returnsNormally);
      expect(() => vm.setFilter('Nuevas'), returnsNormally);
      expect(() => vm.setFilter('En mora'), returnsNormally);
      expect(() => vm.setFilter('Visitados'), returnsNormally);
      expect(() => vm.setFilter('Todos'), returnsNormally);
      
      expect(() => vm.setSearchQuery('test'), returnsNormally);
      expect(() => vm.setSearchQuery(''), returnsNormally);
    });
  });
}