import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StockLevelInput extends StatefulWidget {
  final int initialValue;
  final Function(int) onChanged;

  const StockLevelInput({
    Key? key,
    this.initialValue = 0,
    required this.onChanged,
  }) : super(key: key);

  @override
  _StockLevelInputState createState() => _StockLevelInputState();
}

class _StockLevelInputState extends State<StockLevelInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  void _increment() {
    int value = int.tryParse(_controller.text) ?? 0;
    final newValue = value + 1;
    _controller.text = newValue.toString();
    widget.onChanged(newValue);
  }

  void _decrement() {
    int value = int.tryParse(_controller.text) ?? 0;
    if (value > 0) {
      final newValue = value - 1;
      _controller.text = newValue.toString();
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.remove), onPressed: _decrement),
        SizedBox(
          width: 70,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              final parsed = int.tryParse(val) ?? 0;
              widget.onChanged(parsed);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.add), onPressed: _increment),
      ],
    );
  }
}
