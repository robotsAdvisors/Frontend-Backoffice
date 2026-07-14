import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart'; // importa tus rutas

class SidebarButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const SidebarButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<SidebarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final lilacColor = Colors.purple;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: _isHovered ? lilacColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: _isHovered ? lilacColor : Colors.grey),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isHovered ? lilacColor : Colors.black,
                  fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SidebarButton(
            label: 'Dashboard',
            icon: Icons.dashboard,
            onTap: () => Get.toNamed(Routes.DASHBOARD),
          ),
          SidebarButton(
            label: 'Tiendas',
            icon: Icons.store,
            onTap: () => Get.toNamed(Routes.STORES),
          ),
          SidebarButton(
            label: 'Comercios',
            icon: Icons.business,
            onTap: () => Get.toNamed(Routes.COMMERCE),
          ),
          SidebarButton(
            label: 'Legal',
            icon: Icons.gavel,
            onTap: () => Get.toNamed(Routes.LEGAL),
          ),
          SidebarButton(
            label: 'KYBC',
            icon: Icons.verified_user,
            onTap: () => Get.toNamed(Routes.KYBC),
          ),
          SidebarButton(
            label: 'Políticas',
            icon: Icons.policy,
            onTap: () => Get.toNamed(Routes.POLICIES),
          ),
          SidebarButton(
            label: 'Pagos',
            icon: Icons.payment,
            onTap: () => Get.toNamed(Routes.PAYMENTS),
          ),
          SidebarButton(
            label: 'Soporte',
            icon: Icons.support_agent,
            onTap: () => Get.toNamed(Routes.SUPPORT),
          ),
          SidebarButton(
            label: 'Tickets',
            icon: Icons.confirmation_number,
            onTap: () => Get.toNamed(Routes.TICKETS),
          ),
          SidebarButton(
            label: 'Campañas',
            icon: Icons.campaign,
            onTap: () => Get.toNamed(Routes.CAMPAIGNS),
          ),
        ],
      ),
    );
  }
}
