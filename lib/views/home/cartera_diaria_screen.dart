import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/cartera_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../auth/login_oficial_screen.dart';

class CarteraDiariaScreen extends StatelessWidget {
  const CarteraDiariaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarteraViewModel(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Consumer<CarteraViewModel>(
          builder: (context, vm, _) {
            return Column(
              children: [
                // Header con gradiente rojo
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [CrediscotiaTheme.primary, Color(0xFFCC0000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.work,
                                      color: CrediscotiaTheme.primary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Oficial de Crédito',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Bienvenido',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Colors.white),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoginOficialScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          // Tarjeta de resumen
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  Icons.pending_actions,
                                  '${vm.totalVisits}',
                                  'Pendientes',
                                  Colors.white,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSummaryCard(
                                  Icons.check_circle,
                                  '${vm.completedVisits}',
                                  'Visitados',
                                  Colors.white,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSummaryCard(
                                  Icons.people,
                                  '${vm.clients.length}',
                                  'Total',
                                  Colors.white,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Título de la lista
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Clientes asignados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hoy',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Lista de clientes
                Expanded(
                  child: vm.clients.isEmpty
                      ? const Center(
                          child: Text('No hay clientes asignados'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: vm.clients.length,
                          itemBuilder: (context, index) {
                            final client = vm.clients[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    _showClientDetailDialog(context, client);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: client
                                                    .getManagementColor()
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                client.getManagementIcon(),
                                                color: client
                                                    .getManagementColor(),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    client.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: client
                                                          .getManagementColor()
                                                          .withValues(alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      client
                                                          .getManagementText(),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: client
                                                            .getManagementColor(),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (client.status == 'pendiente')
                                              ElevatedButton(
                                                onPressed: () =>
                                                    _confirmVisit(
                                                        context, vm, client),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      CrediscotiaTheme.primary,
                                                  foregroundColor:
                                                      Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: const Text('Visitar'),
                                              )
                                            else
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      size: 16,
                                                      color: Colors.green
                                                          .shade700,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Visitado',
                                                      style: TextStyle(
                                                        color: Colors.green
                                                            .shade700,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.phone,
                                                size: 14,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              client.phone,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(Icons.document_scanner,
                                                size: 14,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              'DNI: ${client.document}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (client.managementType ==
                                                'cobranza' &&
                                            client.debtAmount > 0)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: CrediscotiaTheme.primary
                                                    .withValues(alpha: 0.05),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.attach_money,
                                                    size: 14,
                                                    color: CrediscotiaTheme
                                                        .primary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Deuda: S/ ${client.debtAmount.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: CrediscotiaTheme
                                                          .primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    IconData icon,
    String value,
    String label,
    Color textColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmVisit(BuildContext context, CarteraViewModel vm, client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Confirmar Visita'),
          content: Text('¿Desea marcar como visitado a ${client.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                vm.markAsVisited(client.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${client.name} marcado como visitado',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CrediscotiaTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showClientDetailDialog(BuildContext context, client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: client.getManagementColor().withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  client.getManagementIcon(),
                  color: client.getManagementColor(),
                ),
              ),
              const SizedBox(width: 12),
              Text(client.name),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.badge, 'DNI', client.document),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.phone, 'Teléfono', client.phone),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.location_on, 'Dirección', client.address),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.category,
                'Tipo de gestión',
                client.getManagementText(),
              ),
              if (client.debtAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildDetailRow(
                    Icons.attach_money,
                    'Monto de deuda',
                    'S/ ${client.debtAmount.toStringAsFixed(2)}',
                    isDebt: true,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {bool isDebt = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isDebt ? FontWeight.bold : FontWeight.normal,
                  color: isDebt ? CrediscotiaTheme.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}