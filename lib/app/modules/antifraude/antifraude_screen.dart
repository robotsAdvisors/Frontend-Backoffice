import 'package:flutter/material.dart';

class AntifraudeScreen extends StatelessWidget {
  const AntifraudeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final publicaciones = [
      {"usuario": "User123", "modalidad": "PA-02", "estado": "Sospechosa"},
      {"usuario": "User456", "modalidad": "PA-03", "estado": "Sospechosa"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Gestión Antifraude")),
      body: ListView.builder(
        itemCount: publicaciones.length,
        itemBuilder: (context, index) {
          final pub = publicaciones[index];
          return Card(
            child: ListTile(
              title: Text("Usuario: ${pub['usuario']}"),
              subtitle: Text("Modalidad: ${pub['modalidad']}"),
              trailing: Text(pub['estado']!),
              onTap: () => Navigator.pushNamed(context, '/antifraude/detail'),
            ),
          );
        },
      ),
    );
  }
}
