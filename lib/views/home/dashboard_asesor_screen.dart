import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/asesor_dashboard_viewmodel.dart';
import '../auth/login_oficial_screen.dart';
import 'rutas_screen.dart';
import 'clientes_screen.dart';
import 'fichas_screen.dart';

class DashboardAsesorScreen extends StatefulWidget {
  const DashboardAsesorScreen({super.key});

  @override
  State<DashboardAsesorScreen> createState() => _DashboardAsesorScreenState();
}

class _DashboardAsesorScreenState extends State<DashboardAsesorScreen> {
  int _selectedIndex = 0;
  String _asesorNombre = '';
  String _asesorId = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosAsesor();
  }

  Future<void> _cargarDatosAsesor() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _asesorNombre = prefs.getString('asesor_nombre') ?? 'Asesor';
      _asesorId = prefs.getString('asesor_id') ?? '';
    });
  }

  final List<Widget> _screens = [
    const DashboardHome(),
    const RutasScreen(),
    const ClientesScreen(),
    const FichasScreen(),
  ];

  final List<String> _titles = [
    'Inicio',
    'Rutas de Hoy',
    'Mis Clientes',
    'Fichas de Campo',
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AsesorDashboardViewModel()..cargarDashboard(_asesorId),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
          backgroundColor: CrediscotiaTheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => _showProfileDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: CrediscotiaTheme.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.route),
              label: 'Rutas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Clientes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'Fichas',
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Perfil del Asesor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Nombre'),
              subtitle: Text(_asesorNombre),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('ID Asesor'),
              subtitle: Text(_asesorId),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea salir?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginOficialScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CrediscotiaTheme.primary,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

// Pantalla de Inicio del Dashboard
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  String _formatNumber(dynamic number) {
    double num;
    if (number == null) {
      num = 0.0;
    } else if (number is int) {
      num = number.toDouble();
    } else if (number is double) {
      num = number;
    } else {
      num = 0.0;
    }
    
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(0)}K';
    }
    return num.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AsesorDashboardViewModel>(context);
    final dashboard = vm.dashboard;

    if (dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Extraer valores con conversión a double
    final metaVisitasMes = (dashboard['metaVisitasMes'] ?? 80).toDouble();
    final visitasMesActual = (dashboard['visitasMesActual'] ?? 0).toDouble();
    final pctVisitas = (dashboard['pctVisitas'] ?? 0).toDouble();
    
    final metaCreditosMes = (dashboard['metaCreditosMes'] ?? 25).toDouble();
    final creditosMesActual = (dashboard['creditosMesActual'] ?? 0).toDouble();
    final pctCreditos = (dashboard['pctCreditos'] ?? 0).toDouble();
    
    final metaMontoMes = (dashboard['metaMontoMes'] ?? 0).toDouble();
    final montoMesActual = (dashboard['montoMesActual'] ?? 0).toDouble();
    final pctMonto = (dashboard['pctMonto'] ?? 0).toDouble();
    
    final visitasHoy = (dashboard['visitasHoy'] ?? 0).toDouble();

    return RefreshIndicator(
      onRefresh: () => vm.cargarDashboard(vm.asesorId),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de bienvenida
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CrediscotiaTheme.primary, Color(0xFFCC0000)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenido',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    vm.nombreAsesor,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vm.codigoAsesor,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Métricas principales
            const Text(
              'Métricas del Mes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Visitas',
                    value: '${visitasMesActual.toInt()}',
                    target: '/ ${metaVisitasMes.toInt()}',
                    icon: Icons.visibility,
                    color: Colors.blue,
                    progress: pctVisitas,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Créditos',
                    value: '${creditosMesActual.toInt()}',
                    target: '/ ${metaCreditosMes.toInt()}',
                    icon: Icons.credit_score,
                    color: Colors.green,
                    progress: pctCreditos,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Monto Colocado',
                    value: 'S/ ${_formatNumber(montoMesActual)}',
                    target: '/ S/ ${_formatNumber(metaMontoMes)}',
                    icon: Icons.attach_money,
                    color: Colors.orange,
                    progress: pctMonto,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Visitas Hoy',
                    value: '${visitasHoy.toInt()}',
                    target: 'pendientes',
                    icon: Icons.today,
                    color: Colors.purple,
                    isToday: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Acciones rápidas
            const Text(
              'Acciones Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.add_location,
                    label: 'Nueva Visita',
                    color: CrediscotiaTheme.primary,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.analytics,
                    label: 'Ver Scoring',
                    color: Colors.blue,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.route,
                    label: 'Ruta de Hoy',
                    color: Colors.green,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.assignment,
                    label: 'Mis Fichas',
                    color: Colors.orange,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String target,
    required IconData icon,
    required Color color,
    double progress = 0,
    bool isToday = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                target,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (!isToday && progress > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.shade200,
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              '${progress.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}