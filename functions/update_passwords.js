// functions/update_passwords.js
const admin = require('firebase-admin');
const crypto = require('crypto');

// Usar el archivo de credenciales
const serviceAccount = require('./serviceAccountKey.json');

// Inicializar con las credenciales
if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

// Función para hashear contraseña
function hashPassword(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

// Usuarios y sus contraseñas
const usuariosConPassword = [
  { userId: 'user_asesor_001', password: '123456', codigo: 'ASE-001' },
  { userId: 'user_asesor_002', password: '123456', codigo: 'ASE-002' },
  // Agregar clientes si también quieren tener contraseña
  { userId: 'user_cliente_001', password: 'cliente123', codigo: 'CLIENTE-001' },
];

async function updatePasswords() {
  console.log('🔐 Actualizando contraseñas en Firestore...\n');

  for (const user of usuariosConPassword) {
    try {
      const passwordHash = hashPassword(user.password);
      
      // Verificar si el usuario existe
      const userDoc = await db.collection('usuarios').doc(user.userId).get();
      
      if (!userDoc.exists) {
        console.log(`⚠️ Usuario ${user.userId} no existe, omitiendo...`);
        continue;
      }
      
      await db.collection('usuarios').doc(user.userId).update({
        passwordHash: passwordHash,
        hasPassword: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`✅ Usuario: ${user.userId} (${user.codigo}) - Contraseña hasheada`);
    } catch (error) {
      console.error(`❌ Error con ${user.userId}:`, error.message);
    }
  }

  console.log('\n🎉 Todas las contraseñas han sido actualizadas!');
  console.log('\n📝 Credenciales de prueba:');
  usuariosConPassword.forEach(u => {
    console.log(`   ${u.codigo} / ${u.password}`);
  });
}

// Ejecutar
updatePasswords().catch(console.error);