const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// ============================================================
// FUNCIÓN 1: Calcular Score automáticamente
// ============================================================
exports.calcularScoreTransaccional = functions.firestore
    .document('clientes/{clienteId}/movimientos/{movimientoId}')
    .onWrite(async (change, context) => {
        const clienteId = context.params.clienteId;
        console.log(`Calculando score para: ${clienteId}`);
        
        try {
            // Obtener movimientos (últimos 6 meses)
            const movimientosSnap = await db
                .collection('clientes')
                .doc(clienteId)
                .collection('movimientos')
                .orderBy('periodo', 'desc')
                .limit(6)
                .get();
            
            const movimientos = movimientosSnap.docs.map(d => d.data());
            
            // Obtener perfil
            const perfilDoc = await db.collection('clientes_perfil').doc(clienteId).get();
            if (!perfilDoc.exists) return null;
            const perfil = perfilDoc.data();
            
            // Calcular
            const features = calcularFeatures(movimientos, perfil);
            const score = calcularScore(features);
            const segmentoInfo = determinarSegmento(score);
            const montoMax = calcularMontoMax(features.capacidadPago, score);
            
            // Guardar resultado
            await db.collection('scores').doc(clienteId).set({
                score: score,
                segmento: segmentoInfo.segmento,
                recomendacion: segmentoInfo.recomendacion,
                montoMaxSugerido: montoMax,
                features: features,
                calculadoAt: admin.firestore.FieldValue.serverTimestamp()
            });
            
            console.log(`✅ Score ${score} para ${clienteId}`);
            return { success: true };
        } catch (error) {
            console.error('Error:', error);
            return null;
        }
    });

// ============================================================
// FUNCIÓN 2: Evaluar crédito (llamada desde la app)
// ============================================================
exports.evaluarCreditoCampo = functions.https.onCall(async (data, context) => {
    const { fichaId, monto, plazoMeses = 12 } = data;
    
    try {
        const fichaDoc = await db.collection('fichas_campo').doc(fichaId).get();
        if (!fichaDoc.exists) throw new Error('Ficha no encontrada');
        
        const ficha = fichaDoc.data();
        const clienteId = ficha.clienteUserId;
        
        if (!clienteId) throw new Error('Cliente no asociado');
        
        const scoreDoc = await db.collection('scores').doc(clienteId).get();
        if (!scoreDoc.exists) throw new Error('Score no calculado');
        
        const scoreData = scoreDoc.data();
        const score = scoreData.score;
        const montoMax = scoreData.montoMaxSugerido;
        
        // Calcular cuota
        const tasa = 1.8 / 100;
        const factor = tasa * Math.pow(1 + tasa, plazoMeses) / (Math.pow(1 + tasa, plazoMeses) - 1);
        const cuota = Math.round(monto * factor);
        
        const aprobacionInmediata = score >= 85 && monto <= montoMax;
        const estado = aprobacionInmediata ? 'pre-aprobado' : 'en_comite';
        
        let mensaje = '';
        if (aprobacionInmediata) mensaje = 'APROBADO: Crédito pre-aprobado';
        else if (score >= 70) mensaje = 'EN REVISIÓN: Pasa a aprobación rápida';
        else if (score >= 50) mensaje = 'PENDIENTE: Requiere garantías adicionales';
        else mensaje = 'NO VIABLE: Score insuficiente';
        
        // Guardar pre-aprobación
        if (estado !== 'rechazado') {
            await db.collection('creditos_preaprobados').add({
                fichaId: fichaId,
                clienteUserId: clienteId,
                asesorId: ficha.asesorId,
                montoPreaprobado: monto,
                plazoMeses: plazoMeses,
                tasaMensual: 1.8,
                cuotaEstimada: cuota,
                scoreAprobacion: score,
                estado: estado,
                vigenteHasta: new Date(Date.now() + 30 * 86400000),
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        
        await db.collection('fichas_campo').doc(fichaId).update({
            estadoFicha: 'completada',
            scoreObtenido: score,
            montoSolicitado: monto
        });
        
        return {
            exito: true,
            score: score,
            segmento: scoreData.segmento,
            decision: mensaje,
            montoMaxAprobable: montoMax,
            cuotaMensual: cuota,
            aprobacionInmediata: aprobacionInmediata
        };
    } catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});

// ============================================================
// FUNCIONES AUXILIARES
// ============================================================

function calcularFeatures(movimientos, perfil) {
    const saldos = movimientos.slice(0, 3).map(m => m.saldoPromedio || 0);
    const promedioSaldo = saldos.reduce((a, b) => a + b, 0) / (saldos.length || 1);
    
    let totalPuntual = 0, totalTardio = 0;
    movimientos.forEach(m => {
        totalPuntual += m.numPagosPuntual || 0;
        totalTardio += m.numPagosTardio || 0;
    });
    const pctPuntual = (totalPuntual + totalTardio) === 0 ? 0 : 
        (totalPuntual * 100 / (totalPuntual + totalTardio));
    
    const capacidadPago = (perfil.ingresoMensualEst || 0) - (perfil.gastoMensualEst || 0);
    const ratioDeuda = (perfil.ingresoMensualEst || 0) === 0 ? 999 : 
        (perfil.deudaActual || 0) / perfil.ingresoMensualEst;
    
    return {
        promedioSaldo,
        pctPuntual,
        capacidadPago,
        ratioDeuda,
        antiguedad: perfil.antiguedadNegocio || 0
    };
}

function calcularScore(features) {
    let score = 0;
    
    if (features.promedioSaldo >= 5000) score += 15;
    else if (features.promedioSaldo >= 2000) score += 12;
    else if (features.promedioSaldo >= 1000) score += 9;
    else if (features.promedioSaldo >= 500) score += 6;
    else if (features.promedioSaldo >= 200) score += 3;
    
    if (features.pctPuntual >= 95) score += 20;
    else if (features.pctPuntual >= 85) score += 16;
    else if (features.pctPuntual >= 70) score += 12;
    else if (features.pctPuntual >= 50) score += 7;
    else if (features.pctPuntual >= 30) score += 3;
    
    if (features.capacidadPago >= 3000) score += 25;
    else if (features.capacidadPago >= 1500) score += 20;
    else if (features.capacidadPago >= 800) score += 15;
    else if (features.capacidadPago >= 400) score += 9;
    else if (features.capacidadPago >= 100) score += 4;
    
    if (features.ratioDeuda <= 0.3) score += 15;
    else if (features.ratioDeuda <= 0.5) score += 12;
    else if (features.ratioDeuda <= 0.7) score += 8;
    else if (features.ratioDeuda <= 1.0) score += 4;
    else if (features.ratioDeuda <= 1.5) score += 2;
    
    if (features.antiguedad >= 60) score += 10;
    else if (features.antiguedad >= 36) score += 8;
    else if (features.antiguedad >= 24) score += 6;
    else if (features.antiguedad >= 12) score += 4;
    else if (features.antiguedad >= 6) score += 2;
    
    return Math.min(Math.round(score), 100);
}

function determinarSegmento(score) {
    if (score >= 85) return { segmento: 'A', recomendacion: 'pre_aprobado_inmediato' };
    if (score >= 70) return { segmento: 'B', recomendacion: 'aprobacion_rapida' };
    if (score >= 50) return { segmento: 'C', recomendacion: 'evaluar_con_garantias' };
    if (score >= 30) return { segmento: 'D', recomendacion: 'requiere_comite' };
    return { segmento: 'E', recomendacion: 'rechazar' };
}

function calcularMontoMax(capacidadPago, score) {
    if (score >= 85) return capacidadPago * 12 * 0.7;
    if (score >= 70) return capacidadPago * 12 * 0.5;
    if (score >= 50) return capacidadPago * 12 * 0.3;
    return 0;
}