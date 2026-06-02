class UbicacionModel {
  final String clienteId;
  final String nombre;
  final double latitud;
  final double longitud;
  final String prioridad;
  final String tipoGestion;
  final String direccion;
  bool visitado;

  UbicacionModel({
    required this.clienteId,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    required this.prioridad,
    required this.tipoGestion,
    required this.direccion,
    this.visitado = false,
  });
}