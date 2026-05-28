import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Client {
  final String id;
  final String name;
  final String document;
  final String managementType; // 'renovacion', 'nuevo', 'cobranza'
  final String status; // 'pendiente', 'visitado'
  final String phone;
  final String address;
  final double debtAmount; // Monto de deuda (para cobranza)

  Client({
    required this.id,
    required this.name,
    required this.document,
    required this.managementType,
    required this.status,
    required this.phone,
    required this.address,
    this.debtAmount = 0.0,
  });

  IconData getManagementIcon() {
    switch (managementType) {
      case 'renovacion':
        return Icons.autorenew;
      case 'nuevo':
        return Icons.person_add;
      case 'cobranza':
        return Icons.attach_money;
      default:
        return Icons.person;
    }
  }

  String getManagementText() {
    switch (managementType) {
      case 'renovacion':
        return 'Renovación';
      case 'nuevo':
        return 'Nuevo Cliente';
      case 'cobranza':
        return 'Cobranza';
      default:
        return 'Gestión';
    }
  }

  Color getManagementColor() {
    switch (managementType) {
      case 'renovacion':
        return Colors.orange;
      case 'nuevo':
        return Colors.blue;
      case 'cobranza':
        return CrediscotiaTheme.primary;
      default:
        return Colors.grey;
    }
  }
}