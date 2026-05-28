import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RutasScreen extends StatefulWidget {
  const RutasScreen({super.key});

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  String _asesorId = '';

  @override
  void initState() {
    super.initState();
    _cargarAsesorId();
  }

  Future<void> _cargarAsesorId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _asesorId = prefs.getString('asesor_id') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_asesorId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rutas')
            .where('asesorId', isEqualTo: _asesorId)
            .where('fechaRuta', isGreaterThanOrEqualTo: inicioDia)
            .where('fechaRuta', isLessThan: finDia)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rutas = snapshot.data!.docs;

          if (rutas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay rutas programadas para hoy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rutas.length,
            itemBuilder: (context, index) {
              final ruta = rutas[index];
              final data = ruta.data() as Map<String, dynamic>;
              return _buildRutaCard(context, data, ruta.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildRutaCard(BuildContext context, Map<String, dynamic> data, String id) {
    Color estadoColor;
    switch (data['estado']) {
      case 'pendiente':
        estadoColor = Colors.orange;
        break;
      case 'visitado':
        estadoColor = Colors.green;
        break;
      case 'en_ruta':
        estadoColor = Colors.blue;
        break;
      default:
        estadoColor = Colors.grey;
    }

    String tipoVisitaText = '';
    IconData tipoIcon;
    switch (data['tipoVisita']) {
      case 'renovacion':
        tipoVisitaText = 'Renovación';
        tipoIcon = Icons.autorenew;
        break;
      case 'prospeccion':
        tipoVisitaText = 'Prospección';
        tipoIcon = Icons.person_add;
        break;
      case 'seguimiento':
        tipoVisitaText = 'Seguimiento';
        tipoIcon = Icons.track_changes;
        break;
      default:
        tipoVisitaText = 'Visita';
        tipoIcon = Icons.business;
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
                  child: Icon(tipoIcon, color: estadoColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['clienteNombre'] ?? 'Cliente sin nombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: estadoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tipoVisitaText,
                              style: TextStyle(fontSize: 11, color: estadoColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            data['horaSugerida'] ?? '09:00',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
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
                    data['estado'] ?? 'pendiente',
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
                  'Monto estimado: S/ ${(data['montoEstimado'] ?? 0).toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (data['referenciaDir'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      data['referenciaDir'],
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}