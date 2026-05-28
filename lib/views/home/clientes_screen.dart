import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'cliente_detail_screen.dart';

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clientes_perfil')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final clientes = snapshot.data!.docs;

          if (clientes.isEmpty) {
            return const Center(
              child: Text('No hay clientes registrados'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              final data = cliente.data() as Map<String, dynamic>;
              
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('scores')
                    .doc(cliente.id)
                    .get(),
                builder: (context, scoreSnapshot) {
                  double score = 0;
                  String segmento = 'Sin evaluar';
                  
                  if (scoreSnapshot.hasData && scoreSnapshot.data!.exists) {
                    final scoreData = scoreSnapshot.data!.data() as Map<String, dynamic>?;
                    if (scoreData != null) {
                      // 👇 CONVERSIÓN SEGURA a double
                      final scoreValue = scoreData['score'];
                      if (scoreValue is int) {
                        score = scoreValue.toDouble();
                      } else if (scoreValue is double) {
                        score = scoreValue;
                      } else if (scoreValue is num) {
                        score = scoreValue.toDouble();
                      } else {
                        score = 0.0;
                      }
                      segmento = scoreData['segmento']?.toString() ?? 'Sin evaluar';
                    }
                  }
                  
                  // 👇 CONVERSIÓN SEGURA del ingreso
                  double ingreso = 0;
                  final ingresoValue = data['ingresoMensualEst'];
                  if (ingresoValue is int) {
                    ingreso = ingresoValue.toDouble();
                  } else if (ingresoValue is double) {
                    ingreso = ingresoValue;
                  } else if (ingresoValue is num) {
                    ingreso = ingresoValue.toDouble();
                  } else {
                    ingreso = 0.0;
                  }
                  
                  return _buildClienteCard(
                    context: context,
                    id: cliente.id,
                    nombre: '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}',
                    dni: data['dni']?.toString() ?? '---',
                    tipoNegocio: data['tipoNegocio']?.toString() ?? '---',
                    ingreso: ingreso,
                    score: score,
                    segmento: segmento,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildClienteCard({
    required BuildContext context,
    required String id,
    required String nombre,
    required String dni,
    required String tipoNegocio,
    required double ingreso,
    required double score,
    required String segmento,
  }) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClienteDetailScreen(clienteId: id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: CrediscotiaTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: CrediscotiaTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.badge, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'DNI: $dni',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.store, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              tipoNegocio,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scoreColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          score.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          segmento,
                          style: TextStyle(
                            fontSize: 10,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    icon: Icons.attach_money,
                    label: 'Ingreso: S/ ${ingreso.toStringAsFixed(0)}',
                  ),
                  _buildInfoChip(
                    icon: Icons.trending_up,
                    label: segmento == 'A' ? 'Cliente Premium' : 'Cliente Regular',
                    color: scoreColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}