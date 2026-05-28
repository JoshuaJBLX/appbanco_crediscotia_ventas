import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreModel {
  final String userId;
  final double score;
  final String segmento;
  final String recomendacion;
  final double montoMaxSugerido;
  final DateTime calculadoAt;

  ScoreModel({
    required this.userId,
    required this.score,
    required this.segmento,
    required this.recomendacion,
    required this.montoMaxSugerido,
    required this.calculadoAt,
  });

  factory ScoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScoreModel(
      userId: doc.id,
      score: (data['score'] ?? 0).toDouble(),
      segmento: data['segmento'] ?? 'C',
      recomendacion: data['recomendacion'] ?? 'evaluar_presencial',
      montoMaxSugerido: (data['montoMaxSugerido'] ?? 0).toDouble(),
      calculadoAt: (data['calculadoAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}