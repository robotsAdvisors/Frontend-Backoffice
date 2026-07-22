import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/general_admin_controller.dart';

class CampaniasView extends StatelessWidget {
  final GeneralAdminController controller = Get.find<GeneralAdminController>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController();
  final TextEditingController startDateCtrl = TextEditingController();
  final TextEditingController endDateCtrl = TextEditingController();
  final TextEditingController productCtrl = TextEditingController();

  final RxList<XFile> productImages = <XFile>[].obs;

  Future<void> pickDate(BuildContext context, TextEditingController target) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      target.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      productImages.assignAll(picked);
    }
  }

  void submitCampaign() async {
    if (nameCtrl.text.trim().isEmpty ||
        discountCtrl.text.trim().isEmpty ||
        startDateCtrl.text.isEmpty ||
        endDateCtrl.text.isEmpty ||
        productCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'Completa todos los campos obligatorios');
      return;
    }

    final payload = {
      'name': nameCtrl.text.trim(),
      'discount': int.tryParse(discountCtrl.text.trim()) ?? 0,
      'start_date': startDateCtrl.text,
      'end_date': endDateCtrl.text,
      'product': productCtrl.text.trim(),
      'images': productImages.map((img) => img.path).toList(),
    };

    await controller.createCampaign(payload);
    cancelCampaign();
  }

  void cancelCampaign() {
    nameCtrl.clear();
    discountCtrl.clear();
    startDateCtrl.clear();
    endDateCtrl.clear();
    productCtrl.clear();
    productImages.clear();
  }

  void showDeleteDialog(BuildContext context) {
    final deleteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar campaña'),
        content: TextField(
          controller: deleteCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre de la campaña',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = deleteCtrl.text.trim();
              if (name.isEmpty) {
                Get.snackbar('Error', 'Ingresa el nombre de la campaña');
                return;
              }
              await controller.deleteCampaignByName(name);
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lilacColor = Colors.purple;

    return Scaffold(
      appBar: AppBar(title: const Text('Campañas Promocionales')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de campaña',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Descuento (%)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startDateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Fecha inicio',
                          border: OutlineInputBorder(),
                        ),
                        onTap: () => pickDate(context, startDateCtrl),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endDateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Fecha fin',
                          border: OutlineInputBorder(),
                        ),
                        onTap: () => pickDate(context, endDateCtrl),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: productCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Producto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  return Column(
                    children: [
                      if (productImages.isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: productImages
                                .map((img) => Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Image.file(File(img.path)),
                                    ))
                                .toList(),
                          ),
                        ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lilacColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: pickImages,
                        icon: const Icon(Icons.upload),
                        label: const Text('Subir fotos del producto'),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lilacColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: submitCampaign,
                      child: const Text('Subir campaña'),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: lilacColor,
                        side: BorderSide(color: lilacColor),
                      ),
                      onPressed: cancelCampaign,
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lilacColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => showDeleteDialog(context),
                      child: const Text('Eliminar campaña'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.campaigns.isEmpty) {
                return const Center(child: Text('No hay campañas publicadas.'));
              }
              return ListView.builder(
                itemCount: controller.campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = controller.campaigns[index];
                  final images = (campaign['images'] ?? []) as List;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(campaign['name'] ?? 'Sin nombre'),
                      subtitle: Text(
                        'Producto: ${campaign['product']} | '
                        'Descuento: ${campaign['discount']}% | '
                        '${campaign['start_date']} → ${campaign['end_date']}',
                      ),
                      isThreeLine: true,
                      trailing: images.isNotEmpty
                          ? SizedBox(
                              width: 80,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: images
                                    .map((path) => Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Image.file(File(path)),
                                        ))
                                    .toList(),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
