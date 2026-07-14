import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({Key? key}) : super(key: key);

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _disputes = [];

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    final response = await _apiService.getDisputes(); // implementar en ApiService
    setState(() {
      _disputes = response.data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Disputas Stripe")),
      body: _disputes.isEmpty
          ? const Center(child: Text("No hay disputas registradas"))
          : ListView.builder(
              itemCount: _disputes.length,
              itemBuilder: (context, index) {
                final dispute = _disputes[index];
                return Card(
                  child: ListTile(
                    title: Text("Pago ID: ${dispute["payment_id"]}"),
                    subtitle: Text("Estado: ${dispute["status"]}"),
                    trailing: Text("Monto: ${dispute["amount"]}"),
                  ),
                );
              },
            ),
    );
  }
}
