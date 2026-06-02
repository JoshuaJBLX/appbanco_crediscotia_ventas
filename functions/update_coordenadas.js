const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const coordenadas = {
  'user_cliente_001': {
    lat: -12.0653,
    lng: -75.2049,
    direccion: 'Jr. Ancash 745, Huancayo'
  },
  'user_cliente_002': {
    lat: -12.0445,
    lng: -75.2112,
    direccion: 'Av. Ferrocarril 1250, El Tambo'
  },
  'user_cliente_003': {
    lat: -12.0820,
    lng: -75.2120,
    direccion: 'Jr. Lima 320, Chilca'
  }
};

async function updateCoordenadas() {
  console.log('📍 Actualizando coordenadas de clientes...\n');
  
  for (const [userId, coords] of Object.entries(coordenadas)) {
    await db.collection('clientes_perfil').doc(userId).update({
      lat: coords.lat,
      lng: coords.lng,
      direccion: coords.direccion
    });
    console.log(`✅ Actualizado: ${userId} - ${coords.direccion}`);
  }
  
  console.log('\n🎉 Coordenadas actualizadas correctamente!');
}

updateCoordenadas();