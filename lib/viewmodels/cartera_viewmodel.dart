import 'package:flutter/material.dart';
import '../models/client_model.dart';

class CarteraViewModel extends ChangeNotifier {
  List<Client> _clients = [];
  List<Client> get clients => _clients;

  int get totalVisits => _clients.where((c) => c.status == 'pendiente').length;
  int get completedVisits => _clients.where((c) => c.status == 'visitado').length;

  CarteraViewModel() {
    _loadHardcodedData();
  }

  void _loadHardcodedData() {
    _clients = [
      Client(
        id: '1',
        name: 'Ana Gómez',
        document: '12345678',
        managementType: 'renovacion',
        status: 'pendiente',
        phone: '987654321',
        address: 'Av. Principal 123, Lima',
        debtAmount: 2500.00,
      ),
      Client(
        id: '2',
        name: 'Luis Torres',
        document: '87654321',
        managementType: 'nuevo',
        status: 'pendiente',
        phone: '987654322',
        address: 'Calle Los Pinos 456, Lima',
        debtAmount: 0.00,
      ),
      Client(
        id: '3',
        name: 'María López',
        document: '11223344',
        managementType: 'cobranza',
        status: 'visitado',
        phone: '987654323',
        address: 'Jr. Las Flores 789, Lima',
        debtAmount: 5000.00,
      ),
      Client(
        id: '4',
        name: 'José Ramírez',
        document: '44332211',
        managementType: 'renovacion',
        status: 'pendiente',
        phone: '987654324',
        address: 'Av. Universitaria 1011, Lima',
        debtAmount: 3200.00,
      ),
      Client(
        id: '5',
        name: 'Carla Rojas',
        document: '55667788',
        managementType: 'nuevo',
        status: 'pendiente',
        phone: '987654325',
        address: 'Calle Los Álamos 2022, Lima',
        debtAmount: 0.00,
      ),
      Client(
        id: '6',
        name: 'Roberto Díaz',
        document: '99887766',
        managementType: 'cobranza',
        status: 'pendiente',
        phone: '987654326',
        address: 'Av. Colonial 3033, Lima',
        debtAmount: 7800.00,
      ),
    ];
  }

  void markAsVisited(String clientId) {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index != -1) {
      _clients[index] = Client(
        id: _clients[index].id,
        name: _clients[index].name,
        document: _clients[index].document,
        managementType: _clients[index].managementType,
        status: 'visitado',
        phone: _clients[index].phone,
        address: _clients[index].address,
        debtAmount: _clients[index].debtAmount,
      );
      notifyListeners();
    }
  }
}