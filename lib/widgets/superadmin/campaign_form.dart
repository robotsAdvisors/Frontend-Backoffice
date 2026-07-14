import 'package:flutter/material.dart';

class CampaignForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final Function()? onDelete;
  final Function()? onCancel;
  final Function()? onInsertImage;

  const CampaignForm({
    Key? key,
    required this.onSubmit,
    this.onDelete,
    this.onCancel,
    this.onInsertImage,
  }) : super(key: key);

  @override
  State<CampaignForm> createState() => _CampaignFormState();
}

class _CampaignFormState extends State<CampaignForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _productController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Nombre de campaña"),
          ),
          TextField(
            controller: _discountController,
            decoration: const InputDecoration(labelText: "Descuento (%)"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _startDateController,
            decoration: const InputDecoration(labelText: "Fecha inicio"),
          ),
          TextField(
            controller: _endDateController,
            decoration: const InputDecoration(labelText: "Fecha fin"),
          ),
          TextField(
            controller: _productController,
            decoration: const InputDecoration(labelText: "Producto"),
          ),
          const SizedBox(height: 20),

          // ─── BLOQUE DE BOTONES EN UNA LÍNEA ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón Subir imagen
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: const Text("Subir imagen",
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  onPressed: widget.onInsertImage,
                ),
              ),
              const SizedBox(width: 8),

              // Botón Subir publicación
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    widget.onSubmit({
                      "name": _nameController.text,
                      "discount": _discountController.text,
                      "start_date": _startDateController.text,
                      "end_date": _endDateController.text,
                      "product": _productController.text,
                    });
                  },
                  child: const Text("Subir publicación",
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),

              // Botón Cancelar
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: widget.onCancel,
                  child: const Text("Cancelar",
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),

              // Botón Eliminar publicación
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: widget.onDelete,
                  child: const Text("Eliminar publicación",
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
