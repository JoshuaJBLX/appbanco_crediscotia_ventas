import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class ClienteDetailScreen extends StatelessWidget {
  final String clienteId;

  const ClienteDetailScreen({super.key, required this.clienteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Cliente'),
        backgroundColor: CrediscotiaTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('clientes_perfil')
            .doc(clienteId)
            .get(),
        builder: (context, perfilSnapshot) {
          if (perfilSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!perfilSnapshot.hasData || !perfilSnapshot.data!.exists) {
            return const Center(child: Text('Cliente no encontrado'));
          }

          final perfilData = perfilSnapshot.data!.data() as Map<String, dynamic>;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('scores')
                .doc(clienteId)
                .get(),
            builder: (context, scoreSnapshot) {
              double score = 0;
              String segmento = 'Sin evaluar';
              
              if (scoreSnapshot.hasData && scoreSnapshot.data!.exists) {
                final scoreData = scoreSnapshot.data!.data() as Map<String, dynamic>?;
                if (scoreData != null) {
                  final scoreValue = scoreData['score'];
                  if (scoreValue is int) {
                    score = scoreValue.toDouble();
                  } else if (scoreValue is double) {
                    score = scoreValue;
                  } else if (scoreValue is num) {
                    score = scoreValue.toDouble();
                  }
                  segmento = scoreData['segmento']?.toString() ?? 'Sin evaluar';
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreCard(score, segmento),
                    const SizedBox(height: 16),
                    _buildInfoCard(perfilData),
                    const SizedBox(height: 16),
                    _buildFinancialCard(perfilData),
                    const SizedBox(height: 16),
                    _buildActionsCard(context, score),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScoreCard(double score, String segmento) {
    Color scoreColor;
    if (score >= 85) {
      scoreColor = Colors.green;
    } else if (score >= 70) {
      scoreColor = Colors.lightGreen;
    } else if (score >= 50) {
      scoreColor = Colors.orange;
    } else if (score >= 30) {
      scoreColor = Colors.deepOrange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor, scoreColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Score Crediticio',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            score.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Segmento $segmento',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> data) {
    // Conversión segura de valores
    final nombres = data['nombres']?.toString() ?? '';
    final apellidos = data['apellidos']?.toString() ?? '';
    final dni = data['dni']?.toString() ?? '---';
    final tipoNegocio = data['tipoNegocio']?.toString() ?? '---';
    final zonaNegocio = data['zonaNegocio']?.toString() ?? '---';
    final antiguedad = _toInt(data['antiguedadNegocio']);
    final localPropio = data['localPropio'] == true;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: CrediscotiaTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Información Personal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Nombre completo', '$nombres $apellidos'),
            _buildInfoRow('DNI', dni),
            _buildInfoRow('Tipo de negocio', tipoNegocio),
            _buildInfoRow('Zona', zonaNegocio),
            _buildInfoRow('Antigüedad', '$antiguedad meses'),
            _buildInfoRow('Local propio', localPropio ? 'Sí' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(Map<String, dynamic> data) {
    // Conversión segura a double
    final ingreso = _toDouble(data['ingresoMensualEst']);
    final gasto = _toDouble(data['gastoMensualEst']);
    final deuda = _toDouble(data['deudaActual']);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_money, color: CrediscotiaTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Información Financiera',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Ingreso mensual', 'S/ ${ingreso.toStringAsFixed(2)}'),
            _buildInfoRow('Gasto mensual', 'S/ ${gasto.toStringAsFixed(2)}'),
            _buildInfoRow('Capacidad de pago', 'S/ ${(ingreso - gasto).toStringAsFixed(2)}',
                highlight: true),
            _buildInfoRow('Deuda actual', 'S/ ${deuda.toStringAsFixed(2)}'),
            _buildInfoRow('Ratio deuda/ingreso', 
                ingreso > 0 ? '${((deuda / ingreso) * 100).toStringAsFixed(1)}%' : 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, double score) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            if (score >= 50)
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidad en desarrollo')),
                  );
                },
                icon: const Icon(Icons.credit_score),
                label: const Text('Evaluar Crédito'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CrediscotiaTheme.primary,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidad en desarrollo')),
                );
              },
              icon: const Icon(Icons.description),
              label: const Text('Crear Ficha de Campo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? CrediscotiaTheme.primary : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper para conversión segura a double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0.0;
  }
  
  // Helper para conversión segura a int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return 0;
  }
}