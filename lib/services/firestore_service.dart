import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asesor_model.dart';
import '../models/cliente_perfil_model.dart';
import '../models/ficha_campo_model.dart';
import '../models/score_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ ASESORES ============
  static Future<AsesorModel?> getAsesorByCodigo(String codigo) async {
    final query = await _firestore
        .collection('asesores')
        .where('codigoAsesor', isEqualTo: codigo)
        .where('activo', isEqualTo: true)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    return AsesorModel.fromFirestore(query.docs.first);
  }

  static Future<Map<String, dynamic>?> getDashboardAsesor(String asesorId) async {
    final asesorDoc = await _firestore.collection('asesores').doc(asesorId).get();
    if (!asesorDoc.exists) return null;
    
    final asesor = AsesorModel.fromFirestore(asesorDoc);
    
    // Visitas de hoy
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    
    final visitasHoy = await _firestore
        .collection('fichas_campo')
        .where('asesorId', isEqualTo: asesorId)
        .where('createdAt', isGreaterThanOrEqualTo: inicioDia)
        .where('createdAt', isLessThan: finDia)
        .get();
    
    return {
      'asesor': asesor,
      'visitasHoy': visitasHoy.docs.length,
      'visitasCompletadas': visitasHoy.docs.where((v) => v['estadoFicha'] == 'completada').length,
    };
  }

  // ============ CLIENTES Y SCORES ============
  static Future<List<Map<String, dynamic>>> getClientesConScore() async {
    // Obtener todos los perfiles de clientes
    final clientesSnapshot = await _firestore.collection('clientes_perfil').get();
    
    final List<Map<String, dynamic>> resultados = [];
    
    for (final clienteDoc in clientesSnapshot.docs) {
      final perfil = ClientePerfilModel.fromFirestore(clienteDoc);
      
      // Obtener score
      final scoreDoc = await _firestore.collection('scores').doc(clienteDoc.id).get();
      ScoreModel? score;
      if (scoreDoc.exists) {
        score = ScoreModel.fromFirestore(scoreDoc);
      }
      
      resultados.add({
        'id': clienteDoc.id,
        'nombre': perfil.nombreCompleto,
        'dni': perfil.dni,
        'tipoNegocio': perfil.tipoNegocio,
        'zonaNegocio': perfil.zonaNegocio,
        'ingresoMensual': perfil.ingresoMensualEst,
        'score': score?.score,
        'segmento': score?.segmento ?? 'Sin evaluar',
        'montoMaxSugerido': score?.montoMaxSugerido ?? 0,
      });
    }
    
    // Ordenar por score (mayor a menor)
    resultados.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    
    return resultados;
  }

  // ============ FICHAS DE CAMPO ============
  static Future<String> crearFichaCampo(FichaCampoModel ficha) async {
    final docRef = await _firestore.collection('fichas_campo').add({
      ...ficha.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  }

  static Future<List<FichaCampoModel>> getFichasByAsesor(String asesorId) async {
    final snapshot = await _firestore
        .collection('fichas_campo')
        .where('asesorId', isEqualTo: asesorId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => FichaCampoModel.fromFirestore(doc)).toList();
  }

  // ============ EVALUAR CRÉDITO ============
  static Future<Map<String, dynamic>> evaluarCredito(
    String fichaId,
    double monto,
    int plazoMeses,
  ) async {
    // Obtener la ficha
    final fichaDoc = await _firestore.collection('fichas_campo').doc(fichaId).get();
    if (!fichaDoc.exists) {
      return {'exito': false, 'mensaje': 'Ficha no encontrada'};
    }
    
    final ficha = fichaDoc.data()!;
    final clienteId = ficha['clienteUserId'];
    
    if (clienteId == null) {
      return {'exito': false, 'mensaje': 'Cliente no asociado'};
    }
    
    // Obtener score del cliente
    final scoreDoc = await _firestore.collection('scores').doc(clienteId).get();
    if (!scoreDoc.exists) {
      return {'exito': false, 'mensaje': 'Cliente no tiene score calculado'};
    }
    
    final scoreData = scoreDoc.data()!;
    final score = (scoreData['score'] ?? 0).toDouble();
    final montoMax = (scoreData['montoMaxSugerido'] ?? 0).toDouble();
    final segmento = scoreData['segmento'] ?? 'C';
    
    // Calcular cuota (sistema francés)
    const double tem = 1.8; // 1.8% mensual
    final double tasa = tem / 100;
    final double factor = tasa * Math.pow(1 + tasa, plazoMeses) / (Math.pow(1 + tasa, plazoMeses) - 1);
    final double cuota = monto * factor;
    
    // Determinar aprobación
    final bool aprobacionInmediata = score >= 85 && monto <= montoMax;
    final String estado = aprobacionInmediata ? 'pre-aprobado' : 'en_comite';
    final String mensaje = aprobacionInmediata
        ? 'APROBADO: Crédito pre-aprobado'
        : score >= 70
            ? 'EN REVISIÓN: Pasa a aprobación rápida'
            : score >= 50
                ? 'PENDIENTE: Requiere garantías adicionales'
                : 'NO VIABLE: Score insuficiente';
    
    // Guardar pre-aprobación
    await _firestore.collection('creditos_preaprobados').add({
      'fichaId': fichaId,
      'clienteUserId': clienteId,
      'asesorId': ficha['asesorId'],
      'montoPreaprobado': monto,
      'plazoMeses': plazoMeses,
      'tasaMensual': tem,
      'cuotaEstimada': cuota.round(),
      'scoreAprobacion': score,
      'estado': estado,
      'vigenteHasta': DateTime.now().add(const Duration(days: 30)),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Actualizar ficha
    await _firestore.collection('fichas_campo').doc(fichaId).update({
      'estadoFicha': 'completada',
      'scoreObtenido': score,
      'montoSolicitado': monto,
    });
    
    return {
      'exito': true,
      'score': score,
      'segmento': segmento,
      'decision': mensaje,
      'montoMaxAprobable': montoMax,
      'cuotaMensual': cuota.round(),
      'aprobacionInmediata': aprobacionInmediata,
    };
  }

  // ============ RUTAS PLANIFICADAS ============
  static Future<List<Map<String, dynamic>>> getRutasDelDia(String asesorId) async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    
    final snapshot = await _firestore
        .collection('rutas')
        .where('asesorId', isEqualTo: asesorId)
        .where('fechaRuta', isGreaterThanOrEqualTo: inicioDia)
        .where('fechaRuta', isLessThan: finDia)
        .orderBy('horaSugerida')
        .get();
    
    final List<Map<String, dynamic>> rutas = [];
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final clienteId = data['clienteUserId'];
      
      String? clienteNombre;
      double? score;
      String? segmento;
      
      if (clienteId != null) {
        // Obtener nombre del cliente
        final perfilDoc = await _firestore.collection('clientes_perfil').doc(clienteId).get();
        if (perfilDoc.exists) {
          final perfil = perfilDoc.data()!;
          clienteNombre = '${perfil['nombres']} ${perfil['apellidos']}';
        }
        
        // Obtener score
        final scoreDoc = await _firestore.collection('scores').doc(clienteId).get();
        if (scoreDoc.exists) {
          score = scoreDoc.data()?['score']?.toDouble();
          segmento = scoreDoc.data()?['segmento'];
        }
      }
      
      rutas.add({
        'id': doc.id,
        'clienteNombre': clienteNombre ?? data['prospectoNombre'] ?? 'Sin nombre',
        'tipoVisita': data['tipoVisita'],
        'montoEstimado': data['montoEstimado'] ?? 0,
        'horaSugerida': data['horaSugerida'],
        'estado': data['estado'] ?? 'pendiente',
        'score': score,
        'segmento': segmento,
        'latitud': data['latitudCliente'],
        'longitud': data['longitudCliente'],
        'referencia': data['referenciaDir'],
      });
    }
    
    return rutas;
  }

  // ============ ESTADÍSTICAS ============
  static Future<Map<String, dynamic>> getEmbudoColocacion(String asesorId) async {
    final fichas = await _firestore
        .collection('fichas_campo')
        .where('asesorId', isEqualTo: asesorId)
        .get();
    
    final creditos = await _firestore
        .collection('creditos_preaprobados')
        .where('asesorId', isEqualTo: asesorId)
        .get();
    
    return {
      'fichasTotal': fichas.docs.length,
      'completadas': fichas.docs.where((f) => f['estadoFicha'] == 'completada').length,
      'sincronizadas': fichas.docs.where((f) => f['estadoFicha'] == 'sincronizada').length,
      'preAprobados': creditos.docs.where((c) => c['estado'] == 'pre-aprobado').length,
      'aprobados': creditos.docs.where((c) => c['estado'] == 'aprobado').length,
      'desembolsados': creditos.docs.where((c) => c['estado'] == 'desembolsado').length,
      'montoDesembolsado': creditos.docs
          .where((c) => c['estado'] == 'desembolsado')
          .fold(0.0, (sum, doc) => sum + (doc['montoPreaprobado'] ?? 0)),
    };
  }
}

// Helper para cálculos matemáticos
class Math {
  static double pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}