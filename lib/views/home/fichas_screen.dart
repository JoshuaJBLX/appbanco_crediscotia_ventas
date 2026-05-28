import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class FichasScreen extends StatelessWidget {
  const FichasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: _getAsesorId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final asesorId = snapshot.data ?? '';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('fichas_campo')
                .where('asesorId', isEqualTo: asesorId)
                .snapshots(),
            builder: (context, fichasSnapshot) {
              if (fichasSnapshot.hasError) {
                return Center(child: Text('Error: ${fichasSnapshot.error}'));
              }

              if (fichasSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final fichas = fichasSnapshot.data!.docs;

              if (fichas.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay fichas registradas',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: fichas.length,
                itemBuilder: (context, index) {
                  final ficha = fichas[index];
                  final data = ficha.data() as Map<String, dynamic>;
                  return _buildFichaCard(context, data, ficha.id);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Funcionalidad en desarrollo')),
          );
        },
        backgroundColor: CrediscotiaTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<String> _getAsesorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('asesor_id') ?? '';
  }

  Widget _buildFichaCard(BuildContext context, Map<String, dynamic> data, String id) {
    Color estadoColor;
    switch (data['estadoFicha']) {
      case 'completada':
        estadoColor = Colors.green;
        break;
      case 'sincronizada':
        estadoColor = Colors.blue;
        break;
      case 'borrador':
        estadoColor = Colors.orange;
        break;
      default:
        estadoColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description,
                    color: estadoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['negocioNombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['tipoVisita'] ?? 'prospeccion',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['estadoFicha'] ?? 'borrador',
                    style: TextStyle(
                      fontSize: 11,
                      color: estadoColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Monto: S/ ${(data['montoSolicitado'] ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                if (data['scoreObtenido'] != null)
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Score: ${(data['scoreObtenido'] ?? 0).toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}