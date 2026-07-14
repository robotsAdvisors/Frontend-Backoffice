import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final response = await _apiService.getTickets(); // deberías implementar este método en ApiService
    setState(() {
      _tickets = response.data;
    });
  }

  void _approveTicket(int id) async {
    await _apiService.approveTicket(id); // implementar en ApiService
    _loadTickets();
  }

  void _rejectTicket(int id) async {
    await _apiService.rejectTicket(id); // implementar en ApiService
    _loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tickets pendientes")),
      body: _tickets.isEmpty
          ? const Center(child: Text("No hay tickets"))
          : ListView.builder(
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                return Card(
                  child: ListTile(
                    title: Text("Tienda: ${ticket["store_name"]}"),
                    subtitle: Text("Campo: ${ticket["field"]} | Nuevo valor: ${ticket["new_value"]}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _approveTicket(ticket["id"]),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectTicket(ticket["id"]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
