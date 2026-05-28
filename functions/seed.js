// functions/seed.js
const admin = require('firebase-admin');
const fs = require('fs');

// Inicializar Firebase Admin
const serviceAccount = require('./serviceAccountKey.json'); // Lo descargarás

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ============================================================
// DATOS DE PRUEBA
// ============================================================

// 1. USUARIOS
const usuarios = [
  {
    id: 'user_asesor_001',
    email: 'jessica.quispe@crediscotia.pe',
    nombre: 'Jessica',
    apellido: 'Quispe Huanca',
    rol: 'asesor',
    activo: true,
    createdAt: new Date()
  },
  {
    id: 'user_asesor_002',
    email: 'mario.ccanto@crediscotia.pe',
    nombre: 'Mario',
    apellido: 'Ccanto Paucar',
    rol: 'asesor',
    activo: true,
    createdAt: new Date()
  },
  {
    id: 'user_cliente_001',
    email: 'rosa.condori@gmail.com',
    nombre: 'Rosa',
    apellido: 'Condori Mamani',
    rol: 'cliente',
    activo: true,
    createdAt: new Date()
  },
  {
    id: 'user_cliente_002',
    email: 'juan.huanca@gmail.com',
    nombre: 'Juan',
    apellido: 'Huanca Quispe',
    rol: 'cliente',
    activo: true,
    createdAt: new Date()
  },
  {
    id: 'user_cliente_003',
    email: 'maria.paucar@gmail.com',
    nombre: 'María',
    apellido: 'Paucar Flores',
    rol: 'cliente',
    activo: true,
    createdAt: new Date()
  }
];

// 2. ASESORES
const asesores = [
  {
    id: 'asesor_001',
    userId: 'user_asesor_001',
    agenciaId: 'agencia_hyo_01',
    codigoAsesor: 'ASE-001',
    especialidad: 'microempresa',
    zonaAsignada: 'Huancayo centro, Cercado, San Carlos',
    activo: true,
    metaVisitasMes: 80,
    metaCreditosMes: 25,
    metaMontoMes: 180000,
    visitasMesActual: 52,
    creditosMesActual: 16,
    montoMesActual: 112000
  },
  {
    id: 'asesor_002',
    userId: 'user_asesor_002',
    agenciaId: 'agencia_hyo_02',
    codigoAsesor: 'ASE-002',
    especialidad: 'microempresa',
    zonaAsignada: 'El Tambo, Huancán, Pilcomayo',
    activo: true,
    metaVisitasMes: 80,
    metaCreditosMes: 25,
    metaMontoMes: 180000,
    visitasMesActual: 61,
    creditosMesActual: 19,
    montoMesActual: 148000
  }
];

// 3. CLIENTES PERFIL
const clientesPerfil = [
  {
    id: 'user_cliente_001',
    nombres: 'Rosa',
    apellidos: 'Condori Mamani',
    dni: '12345678',
    tipoNegocio: 'bodega',
    antiguedadNegocio: 48,
    localPropio: true,
    zonaNegocio: 'urbano',
    ingresoMensualEst: 3500,
    gastoMensualEst: 1800,
    deudaActual: 5000,
    entidadesDeuda: 1,
    estadoCliente: 'activo'
  },
  {
    id: 'user_cliente_002',
    nombres: 'Juan',
    apellidos: 'Huanca Quispe',
    dni: '87654321',
    tipoNegocio: 'ferreteria',
    antiguedadNegocio: 72,
    localPropio: true,
    zonaNegocio: 'urbano',
    ingresoMensualEst: 7200,
    gastoMensualEst: 3500,
    deudaActual: 15000,
    entidadesDeuda: 2,
    estadoCliente: 'activo'
  },
  {
    id: 'user_cliente_003',
    nombres: 'María',
    apellidos: 'Paucar Flores',
    dni: '11223344',
    tipoNegocio: 'restaurante',
    antiguedadNegocio: 36,
    localPropio: true,
    zonaNegocio: 'urbano',
    ingresoMensualEst: 4800,
    gastoMensualEst: 2500,
    deudaActual: 8000,
    entidadesDeuda: 1,
    estadoCliente: 'activo'
  }
];

// 4. MOVIMIENTOS MENSUALES
const movimientos = [
  // Rosa Condori - 6 meses
  { clienteId: 'user_cliente_001', periodo: '2025-03', totalCreditos: 3800, totalDebitos: 1900, saldoPromedio: 1400, numTransacciones: 20, numPagosPuntual: 3, numPagosTardio: 0 },
  { clienteId: 'user_cliente_001', periodo: '2025-02', totalCreditos: 3500, totalDebitos: 1800, saldoPromedio: 1200, numTransacciones: 18, numPagosPuntual: 3, numPagosTardio: 0 },
  { clienteId: 'user_cliente_001', periodo: '2025-01', totalCreditos: 3600, totalDebitos: 1750, saldoPromedio: 1300, numTransacciones: 19, numPagosPuntual: 3, numPagosTardio: 0 },
  // Juan Huanca
  { clienteId: 'user_cliente_002', periodo: '2025-03', totalCreditos: 7500, totalDebitos: 3600, saldoPromedio: 3800, numTransacciones: 30, numPagosPuntual: 4, numPagosTardio: 0 },
  { clienteId: 'user_cliente_002', periodo: '2025-02', totalCreditos: 7000, totalDebitos: 3500, saldoPromedio: 3500, numTransacciones: 28, numPagosPuntual: 4, numPagosTardio: 0 },
  // María Paucar
  { clienteId: 'user_cliente_003', periodo: '2025-03', totalCreditos: 5000, totalDebitos: 2600, saldoPromedio: 2200, numTransacciones: 24, numPagosPuntual: 3, numPagosTardio: 0 }
];

// 5. FICHAS DE CAMPO
const fichasCampo = [
  {
    asesorId: 'asesor_001',
    clienteUserId: 'user_cliente_001',
    latitud: -12.0653,
    longitud: -75.2049,
    distrito: 'Huancayo',
    tipoVisita: 'renovacion',
    negocioNombre: 'Bodega Rosita',
    negocioRubro: 'bodega',
    ingresoDeclarado: 3500,
    gastoDeclarado: 1800,
    montoSolicitado: 8000,
    observaciones: 'Cliente solicita ampliación para stock',
    estadoFicha: 'completada',
    scoreObtenido: 85
  }
];

// 6. RUTAS PLANIFICADAS
const rutas = [
  {
    asesorId: 'asesor_001',
    fechaRuta: new Date(),
    clienteUserId: 'user_cliente_001',
    tipoVisita: 'renovacion',
    montoEstimado: 8000,
    horaSugerida: '08:30',
    estado: 'pendiente',
    cargadoAutomatico: true
  },
  {
    asesorId: 'asesor_001',
    fechaRuta: new Date(),
    clienteUserId: 'user_cliente_002',
    tipoVisita: 'renovacion',
    montoEstimado: 25000,
    horaSugerida: '10:00',
    estado: 'pendiente',
    cargadoAutomatico: true
  }
];

// ============================================================
// FUNCIÓN PRINCIPAL PARA CARGAR DATOS
// ============================================================
async function seedData() {
  console.log('🚀 Iniciando carga de datos a Firestore...\n');

  try {
    // 1. Cargar usuarios
    console.log('📝 Cargando usuarios...');
    for (const user of usuarios) {
      await db.collection('usuarios').doc(user.id).set(user);
      console.log(`  ✅ Usuario: ${user.nombre} ${user.apellido}`);
    }

    // 2. Cargar asesores
    console.log('\n📝 Cargando asesores...');
    for (const asesor of asesores) {
      await db.collection('asesores').doc(asesor.id).set(asesor);
      console.log(`  ✅ Asesor: ${asesor.codigoAsesor}`);
    }

    // 3. Cargar perfiles de clientes
    console.log('\n📝 Cargando perfiles de clientes...');
    for (const cliente of clientesPerfil) {
      await db.collection('clientes_perfil').doc(cliente.id).set(cliente);
      console.log(`  ✅ Cliente: ${cliente.nombres} ${cliente.apellidos}`);
    }

    // 4. Cargar movimientos (subcolecciones)
    console.log('\n📝 Cargando movimientos...');
    for (const movimiento of movimientos) {
      const movId = `${movimiento.periodo}_${Date.now()}`;
      await db
        .collection('clientes')
        .doc(movimiento.clienteId)
        .collection('movimientos')
        .doc(movId)
        .set(movimiento);
      console.log(`  ✅ Movimiento: ${movimiento.clienteId} - ${movimiento.periodo}`);
    }

    // 5. Cargar fichas de campo
    console.log('\n📝 Cargando fichas de campo...');
    for (const ficha of fichasCampo) {
      const docRef = await db.collection('fichas_campo').add({
        ...ficha,
        createdAt: new Date()
      });
      console.log(`  ✅ Ficha: ${docRef.id}`);
    }

    // 6. Cargar rutas
    console.log('\n📝 Cargando rutas planificadas...');
    for (const ruta of rutas) {
      const docRef = await db.collection('rutas').add({
        ...ruta,
        cargadoAt: new Date()
      });
      console.log(`  ✅ Ruta: ${docRef.id}`);
    }

    console.log('\n🎉 ¡CARGA COMPLETADA EXITOSAMENTE!');
    console.log('\n📊 Resumen:');
    console.log(`   - Usuarios: ${usuarios.length}`);
    console.log(`   - Asesores: ${asesores.length}`);
    console.log(`   - Clientes: ${clientesPerfil.length}`);
    console.log(`   - Movimientos: ${movimientos.length}`);
    console.log(`   - Fichas: ${fichasCampo.length}`);
    console.log(`   - Rutas: ${rutas.length}`);

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Ejecutar
seedData();