class DbConstants {
  static const String databaseName = 'fuerza_ventas.db';
  static const int databaseVersion = 1;
  
  // Tablas
  static const String tableCartera = 'cartera_local';
  static const String tableClientes = 'clientes_local';
  static const String tableScores = 'scores_local';
  static const String tableSyncQueue = 'sync_queue';
  
  // Columnas comunes
  static const String colId = 'id';
  static const String colSyncPending = 'sync_pending';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  
  // Crear tablas
  static const String createCarteraTable = '''
    CREATE TABLE $tableCartera (
      $colId TEXT PRIMARY KEY,
      asesor_id TEXT NOT NULL,
      cliente_id TEXT NOT NULL,
      cliente_nombre TEXT NOT NULL,
      cliente_dni TEXT NOT NULL,
      tipo_gestion TEXT NOT NULL,
      prioridad TEXT NOT NULL,
      score_prioridad INTEGER DEFAULT 0,
      estado_visita TEXT DEFAULT 'pendiente',
      monto_solicitado REAL DEFAULT 0,
      orden_manual INTEGER DEFAULT 0,
      $colSyncPending INTEGER DEFAULT 0,
      $colCreatedAt INTEGER,
      $colUpdatedAt INTEGER
    )
  ''';
  
  static const String createClientesTable = '''
    CREATE TABLE $tableClientes (
      $colId TEXT PRIMARY KEY,
      nombres TEXT NOT NULL,
      apellidos TEXT NOT NULL,
      dni TEXT NOT NULL,
      tipo_negocio TEXT,
      ingreso_mensual_est REAL DEFAULT 0,
      gasto_mensual_est REAL DEFAULT 0,
      deuda_actual REAL DEFAULT 0,
      $colSyncPending INTEGER DEFAULT 0,
      $colCreatedAt INTEGER,
      $colUpdatedAt INTEGER
    )
  ''';
  
  static const String createScoresTable = '''
    CREATE TABLE $tableScores (
      $colId TEXT PRIMARY KEY,
      score REAL DEFAULT 0,
      segmento TEXT DEFAULT 'C',
      monto_max_sugerido REAL DEFAULT 0,
      $colSyncPending INTEGER DEFAULT 0,
      $colCreatedAt INTEGER,
      $colUpdatedAt INTEGER
    )
  ''';
  
  static const String createSyncQueueTable = '''
    CREATE TABLE $tableSyncQueue (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      operation TEXT NOT NULL,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      data TEXT NOT NULL,
      attempts INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL
    )
  ''';
}