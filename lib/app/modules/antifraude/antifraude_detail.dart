import 'package:flutter/material.dart';

class AntifraudeDetail extends StatelessWidget {
  const AntifraudeDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de Publicación Sospechosa")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Usuario: User123", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Modalidad: PA-02"),
            const Text("Ubicación: Zona aproximada"),
            const Text("Tiempo: 5 min"),
            const Text("Fiabilidad: Baja"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/antifraude/actions'),
              child: const Text("Acciones sobre informador"),
            ),
          ],
        ),
      ),
    );
  }
}
