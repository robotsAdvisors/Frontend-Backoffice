import 'package:flutter/material.dart';

class PublicacionesPage extends StatefulWidget {
  const PublicacionesPage({super.key});

  @override
  State<PublicacionesPage> createState() => _PublicacionesPageState();
}

class _PublicacionesPageState extends State<PublicacionesPage> {
  String filtroFuncional = 'Todos';
  String filtroEconomico = 'Todos';
  String filtroGlobal = 'Todas';
  String query = '';
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, String>> publicaciones = [
    {
      'modalidad': 'PA-01',
      'funcional': 'Activa',
      'economico': 'Pagado',
      'informador': 'Juan Pérez',
      'solicitante': 'María Gómez',
      'fecha': '2026-07-23 14:30',
      'stripe': 'ch_1ABCDEF'
    },
    {
      'modalidad': 'PA-02',
      'funcional': 'Inactiva',
      'economico': 'Pendiente',
      'informador': 'Carlos Díaz',
      'solicitante': 'Ana López',
      'fecha': '2026-07-22 10:15',
      'stripe': 'ch_1XYZ123'
    },
  ];

  /// Chip de estado con color e ícono
  Widget estadoChip(String estado) {
    Color color;
    IconData icon;

    switch (estado) {
      case 'Activa':
        color = Colors.green;
        icon = Icons.play_circle_fill;
        break;
      case 'Validada':
        color = Colors.blue;
        icon = Icons.verified;
        break;
      case 'Expirada':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case 'Reembolsada':
        color = Colors.red;
        icon = Icons.reply_all;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(estado),
      backgroundColor: color.withOpacity(0.8),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  /// Ícono diferenciado por modalidad
  Icon modalidadIcon(String modalidad) {
    switch (modalidad) {
      case 'PA-01':
        return const Icon(Icons.local_parking, color: Colors.indigo);
      case 'PA-02':
        return const Icon(Icons.directions_car, color: Colors.teal);
      case 'PA-03':
        return const Icon(Icons.motorcycle, color: Colors.deepPurple);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = publicaciones.where((p) {
      final matchFuncional = filtroFuncional == 'Todos' || p['funcional'] == filtroFuncional;
      final matchEconomico = filtroEconomico == 'Todos' || p['economico'] == filtroEconomico;
      final matchGlobal = filtroGlobal == 'Todas' || p['funcional'] == filtroGlobal;
      final matchBusqueda = query.isEmpty ||
          p['informador']!.toLowerCase().contains(query.toLowerCase()) ||
          p['solicitante']!.toLowerCase().contains(query.toLowerCase()) ||
          p['stripe']!.toLowerCase().contains(query.toLowerCase());
      return matchFuncional && matchEconomico && matchGlobal && matchBusqueda;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Publicaciones de aparcamiento')),
      body: Column(
        children: [
          // Barra de filtros globales y búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: filtroGlobal,
                  items: ['Todas', 'Activas', 'Pendientes de resultado', 'Disputadas', 'Expiradas']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => filtroGlobal = val!),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por informador, solicitante o Stripe',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => query = val),
                  ),
                ),
              ],
            ),
          ),
          // Filtros funcional y económico
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: filtroFuncional,
                  items: ['Todos', 'Activa', 'Inactiva']
                      .map((e) => DropdownMenuItem(value: e, child: Text('Funcional: $e')))
                      .toList(),
                  onChanged: (val) => setState(() => filtroFuncional = val!),
                ),
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: filtroEconomico,
                  items: ['Todos', 'Pagado', 'Pendiente']
                      .map((e) => DropdownMenuItem(value: e, child: Text('Económico: $e')))
                      .toList(),
                  onChanged: (val) => setState(() => filtroEconomico = val!),
                ),
              ],
            ),
          ),
          // Tabla con chips e íconos
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Modalidad')),
                  DataColumn(label: Text('Estado Funcional')),
                  DataColumn(label: Text('Estado Económico')),
                  DataColumn(label: Text('Informador')),
                  DataColumn(label: Text('Solicitante')),
                  DataColumn(label: Text('Fecha/Hora')),
                  DataColumn(label: Text('Stripe Ref')),
                ],
                rows: filtradas.map((p) {
                  return DataRow(
                    onSelectChanged: (_) {
                      // Aquí podés navegar al detalle con GetX o Navigator
                      // Ejemplo: Get.toNamed('/publicacion_detail', arguments: p['stripe']);
                    },
                    cells: [
                      DataCell(Row(
                        children: [
                          modalidadIcon(p['modalidad']!),
                          const SizedBox(width: 6),
                          Text(p['modalidad']!),
                        ],
                      )),
                      DataCell(estadoChip(p['funcional']!)),
                      DataCell(estadoChip(p['economico']!)),
                      DataCell(Text(p['informador']!)),
                      DataCell(Text(p['solicitante']!)),
                      DataCell(Text(p['fecha']!)),
                      DataCell(Text(p['stripe']!)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
