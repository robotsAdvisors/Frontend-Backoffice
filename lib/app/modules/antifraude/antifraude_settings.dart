import 'package:flutter/material.dart';

class AntifraudeSettings extends StatefulWidget {
  const AntifraudeSettings({super.key});

  @override
  State<AntifraudeSettings> createState() => _AntifraudeSettingsState();
}

class _AntifraudeSettingsState extends State<AntifraudeSettings> {
  double limiteDiario = 5;
  double radioCobertura = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración Antifraude")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Límite diario de operaciones: ${limiteDiario.toInt()}"),
            Slider(
              value: limiteDiario,
              min: 1,
              max: 20,
              divisions: 19,
              label: limiteDiario.toInt().toString(),
              onChanged: (value) => setState(() => limiteDiario = value),
            ),
            const SizedBox(height: 20),
            Text("Radio de cobertura (m): ${radioCobertura.toInt()}"),
            Slider(
              value: radioCobertura,
              min: 100,
              max: 2000,
              divisions: 19,
              label: radioCobertura.toInt().toString(),
              onChanged: (value) => setState(() => radioCobertura = value),
            ),
          ],
        ),
      ),
    );
  }
}
