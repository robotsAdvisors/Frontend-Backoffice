import 'package:flutter/material.dart';

/// Campo numérico reutilizable
class CampoNumero extends StatelessWidget {
  final String label;
  final int valorInicial;
  final Function(int) onChanged;

  const CampoNumero({
    super.key,
    required this.label,
    required this.valorInicial,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: valorInicial.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        onChanged: (val) {
          final parsed = int.tryParse(val) ?? valorInicial;
          onChanged(parsed);
        },
      ),
    );
  }
}

/// Switch reutilizable para reglas antifraude
class CampoSwitch extends StatelessWidget {
  final String label;
  final bool valorInicial;
  final Function(bool) onChanged;

  const CampoSwitch({
    super.key,
    required this.label,
    required this.valorInicial,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      value: valorInicial,
      onChanged: onChanged,
    );
  }
}
