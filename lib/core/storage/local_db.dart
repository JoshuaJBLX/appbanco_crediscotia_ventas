import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/db_constants.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static LocalDatabase get instance => _instance;
  
  static Database? _database;
  
  LocalDatabase._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, DbConstants.databaseName);
    
    return await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Crear todas las tablas
    await db.execute(DbConstants.createCarteraTable);
    await db.execute(DbConstants.createClientesTable);
    await db.execute(DbConstants.createScoresTable);
    await db.execute(DbConstants.createSyncQueueTable);
    
    print('✅ Base de datos local creada exitosamente');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Actualizando base de datos de $oldVersion a $newVersion');
    // Aquí se agregarán migraciones cuando sea necesario
  }
  
  // ============================================================
  // Operaciones genéricas
  // ============================================================
  
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }
  
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }
  
  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
  
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }
  
  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }
  
  // ============================================================
  // Operaciones específicas para cartera
  // ============================================================
  
  Future<void> saveCarteraLocal(List<Map<String, dynamic>> cartera) async {
    final db = await database;
    
    // Iniciar transacción
    await db.transaction((txn) async {
      // Limpiar cartera anterior del asesor
      if (cartera.isNotEmpty) {
        final asesorId = cartera.first['asesor_id'];
        await txn.delete(
          DbConstants.tableCartera,
          where: 'asesor_id = ?',
          whereArgs: [asesorId],
        );
      }
      
      // Insertar nueva cartera
      for (final item in cartera) {
        await txn.insert(DbConstants.tableCartera, item);
      }
    });
    
    print('✅ ${cartera.length} registros guardados en cartera_local');
  }
  
  Future<List<Map<String, dynamic>>> getCarteraLocal(String asesorId) async {
    final db = await database;
    return await db.query(
      DbConstants.tableCartera,
      where: 'asesor_id = ?',
      whereArgs: [asesorId],
      orderBy: 'orden_manual ASC, score_prioridad DESC',
    );
  }
  
  Future<void> updateEstadoVisitaLocal(
    String carteraId,
    String estado,
    String resultado,
    String observacion,
  ) async {
    final db = await database;
    await db.update(
      DbConstants.tableCartera,
      {
        'estado_visita': estado,
        'resultado_visita': resultado,
        'observacion_visita': observacion,
        DbConstants.colSyncPending: 1,
        DbConstants.colUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbConstants.colId} = ?',
      whereArgs: [carteraId],
    );
  }
  
  Future<void> updateOrdenManual(String carteraId, int nuevoOrden) async {
    final db = await database;
    await db.update(
      DbConstants.tableCartera,
      {
        'orden_manual': nuevoOrden,
        DbConstants.colUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbConstants.colId} = ?',
      whereArgs: [carteraId],
    );
  }
  
  // ============================================================
  // Cola de sincronización
  // ============================================================
  
  Future<void> addToSyncQueue({
    required String operation,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.insert(DbConstants.tableSyncQueue, {
      'operation': operation, // 'INSERT', 'UPDATE', 'DELETE'
      'table_name': tableName,
      'record_id': recordId,
      'data': data.toString(),
      'attempts': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      DbConstants.tableSyncQueue,
      orderBy: 'created_at ASC',
    );
  }
  
  Future<void> removeFromSyncQueue(int id) async {
    final db = await database;
    await db.delete(
      DbConstants.tableSyncQueue,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> incrementAttempts(int id) async {
    final db = await database;
    await db.update(
      DbConstants.tableSyncQueue,
      {'attemptives': db.rawUpdate('attempts = attempts + 1')},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // ============================================================
  // Clientes
  // ============================================================
  
  Future<void> saveClientesLocal(List<Map<String, dynamic>> clientes) async {
    final db = await database;
    
    await db.transaction((txn) async {
      for (final cliente in clientes) {
        await txn.insert(
          DbConstants.tableClientes,
          cliente,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
  
  Future<Map<String, dynamic>?> getClienteLocal(String clienteId) async {
    final db = await database;
    final result = await db.query(
      DbConstants.tableClientes,
      where: '${DbConstants.colId} = ?',
      whereArgs: [clienteId],
    );
    return result.isNotEmpty ? result.first : null;
  }
  
  // ============================================================
  // Scores
  // ============================================================
  
  Future<void> saveScoresLocal(List<Map<String, dynamic>> scores) async {
    final db = await database;
    
    await db.transaction((txn) async {
      for (final score in scores) {
        await txn.insert(
          DbConstants.tableScores,
          score,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
  
  Future<Map<String, dynamic>?> getScoreLocal(String clienteId) async {
    final db = await database;
    final result = await db.query(
      DbConstants.tableScores,
      where: '${DbConstants.colId} = ?',
      whereArgs: [clienteId],
    );
    return result.isNotEmpty ? result.first : null;
  }
}