import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/superadmin/campaign_form.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({Key? key}) : super(key: key);

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    final response = await _apiService.getCampaigns();
    setState(() {
      _campaigns = response.data;
    });
  }

  void _createCampaign(Map<String, dynamic> data) async {
    await _apiService.createCampaign(data);
    _loadCampaigns();
  }

  void _deleteCampaign(int id) async {
    await _apiService.deleteCampaign(id);
    _loadCampaigns();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Campañas Promocionales")),
      body: Column(
        children: [
          CampaignForm(
            onSubmit: _createCampaign,
            onCancel: () => Navigator.pop(context),
          ),
          const Divider(),
          Expanded(
            child: _campaigns.isEmpty
                ? const Center(child: Text("No hay campañas publicadas"))
                : ListView.builder(
                    itemCount: _campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = _campaigns[index];
                      return ListTile(
                        title: Text(campaign["name"]),
                        subtitle: Text(
                          "Descuento: ${campaign["discount"]}% | Vigencia: ${campaign["start_date"]} - ${campaign["end_date"]}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCampaign(campaign["id"]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
