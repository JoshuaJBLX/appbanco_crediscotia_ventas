import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/cartera_viewmodel.dart';
import '../../theme/app_theme.dart';

class CarteraDiariaScreen extends StatefulWidget {
  const CarteraDiariaScreen({super.key});

  @override
  State<CarteraDiariaScreen> createState() => _CarteraDiariaScreenState();
}

class _CarteraDiariaScreenState extends State<CarteraDiariaScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _filterOptions = [
    'Todos',
    'Renovaciones',
    'Nuevas',
    'En mora',
    'Visitados',
  ];
  
  String _selectedFilter = 'Todos';
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarteraViewModel()..cargarDatos(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Consumer<CarteraViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.filteredClients.isEmpty && vm.clients.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay clientes asignados', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildProgressBar(vm),
                _buildFilters(vm),
                _buildSearchBar(vm),
                if (vm.lastSyncTime.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Última actualización: ${vm.lastSyncTime}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => vm.cargarDatos(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vm.filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = vm.filteredClients[index];
                        return _buildClientCard(context, vm, client);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildProgressBar(CarteraViewModel vm) {
    final total = vm.completedVisits + vm.totalVisits;
    final porcentaje = total > 0 ? (vm.completedVisits * 100 / total) : 0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso del día',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${vm.completedVisits} / $total visitados',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CrediscotiaTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: vm.progress,
              backgroundColor: Colors.grey.shade200,
              color: CrediscotiaTheme.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${porcentaje.toStringAsFixed(0)}% completado',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilters(CarteraViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filterOptions.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                  vm.setFilter(filter);
                });
              },
              selectedColor: CrediscotiaTheme.primary.withValues(alpha: 0.2),
              checkmarkColor: CrediscotiaTheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildSearchBar(CarteraViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o últimos 4 dígitos del DNI',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    vm.setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          vm.setSearchQuery(value);
        },
      ),
    );
  }
  
  Widget _buildClientCard(BuildContext context, CarteraViewModel vm, client) {
    final prioridadText = vm.getPrioridadText(client);
    final prioridadColor = vm.getPrioridadColor(client);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: client.getManagementColor().withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      client.getManagementIcon(),
                      color: client.getManagementColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              vm.getCensoredDni(client.document),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: client.getManagementColor().withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                client.getManagementText(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: client.getManagementColor(),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: prioridadColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: prioridadColor),
                    ),
                    child: Text(
                      prioridadText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: prioridadColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (client.debtAmount > 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Deuda pendiente: S/ ${client.debtAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              if (client.status == 'pendiente')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _confirmVisit(context, vm, client),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CrediscotiaTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Marcar como visitado'),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Visitado',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _confirmVisit(BuildContext context, CarteraViewModel vm, client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? observacion;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Confirmar Visita'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Desea marcar como visitado a ${client.name}?'),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (value) => observacion = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                vm.markAsVisited(client.id, observacion: observacion);
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
              Expanded(child: Text(client.name)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
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