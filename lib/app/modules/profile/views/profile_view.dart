import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../components/custom_button.dart';
import '../../../components/custom_form_field.dart';
import '../../../data/models/order_model.dart';
import '../../../routes/app_pages.dart';
import '../../base/controllers/base_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  // ─── helpers ──────────────────────────────────────────────────────────────

  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleDark = Color(0xFF5B21B6);
  static const Color _gold = Color(0xFFFFB300);

  static String _tierLabel(int pts) {
    if (pts >= 10000) return 'Gold Member';
    if (pts >= 5000) return 'Silver Member';
    return 'Bronze Member';
  }

  static Color _tierColor(int pts) {
    if (pts >= 10000) return _gold;
    if (pts >= 5000) return Colors.blueGrey;
    return const Color(0xFFCD7F32);
  }

  static BoxDecoration _card(ThemeData theme) => BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(
              title: Text('Mi perfil', style: theme.textTheme.displaySmall),
              centerTitle: true,
            ),
      body: Column(
        children: [
          _heroBanner(theme),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 24 : 16),
              child: isWide ? _desktopLayout(theme) : _mobileLayout(theme),
            ),
          ),
        ],
      ),
    );
  }

  // ─── hero banner ──────────────────────────────────────────────────────────

  Widget _heroBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_purple, _purpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Obx(() {
        final imageBytes = controller.profileImageBytes;
        final name = controller.customerName.value;
        final pts = Get.isRegistered<BaseController>()
            ? Get.find<BaseController>().userPoints.value
            : 0;
        final tier = _tierLabel(pts);
        final tierColor = _tierColor(pts);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with camera badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 40.r,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                  child: imageBytes == null
                      ? Icon(Icons.person, size: 40.r, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: controller.pickProfileImage,
                    child: CircleAvatar(
                      radius: 12.r,
                      backgroundColor: tierColor,
                      child: Icon(Icons.camera_alt, size: 12.r, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            16.horizontalSpace,
            // Name + tier badge + member since
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name.isEmpty ? 'Usuario' : name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  6.verticalSpace,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: tierColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      tier,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    'Member since Oct 2023',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                  ),
                ],
              ),
            ),
            // Current balance + Redeem Now
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CURRENT BALANCE',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                      letterSpacing: 0.8),
                ),
                4.verticalSpace,
                Text(
                  '$pts PTS',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
                8.verticalSpace,
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _purple,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Redeem Now'),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  // ─── layouts ──────────────────────────────────────────────────────────────

  Widget _desktopLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              _personalInfoCard(theme),
              16.verticalSpace,
              _membershipProgressCard(theme),
              16.verticalSpace,
              _settingsCard(theme),
              16.verticalSpace,
              _actionsCard(theme),
            ],
          ),
        ),
        20.horizontalSpace,
        Expanded(
          child: Column(
            children: [
              _statsRow(theme),
              16.verticalSpace,
              _redemptionHistoryCard(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout(ThemeData theme) {
    return Column(
      children: [
        _personalInfoCard(theme),
        16.verticalSpace,
        _statsRow(theme),
        16.verticalSpace,
        _membershipProgressCard(theme),
        16.verticalSpace,
        _redemptionHistoryCard(theme),
        16.verticalSpace,
        _settingsCard(theme),
        16.verticalSpace,
        _actionsCard(theme),
      ],
    );
  }

  // ─── personal info card ───────────────────────────────────────────────────

  Widget _personalInfoCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _card(theme),
      child: Obx(() {
        final isEditing = controller.isEditingProfile.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (!isEditing)
                  GestureDetector(
                    onTap: controller.startEditingProfile,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryColorDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_outlined,
                          size: 16, color: theme.primaryColor),
                    ),
                  ),
              ],
            ),
            16.verticalSpace,
            if (!isEditing) ...[
              _infoField(theme, Icons.email_outlined, 'Email',
                  controller.userEmail.value),
              10.verticalSpace,
              _infoField(theme, Icons.phone_outlined, 'Phone',
                  controller.customerPhone.value),
              10.verticalSpace,
              _infoField(theme, Icons.location_on_outlined, 'Region',
                  controller.customerAddress.value),
            ] else ...[
              CustomFormField(
                controller: controller.nameController,
                hint: 'Full name',
                maxLines: 1,
              ),
              10.verticalSpace,
              CustomFormField(
                controller: controller.phoneController,
                hint: 'Phone',
                keyboardType: TextInputType.phone,
                maxLines: 1,
              ),
              10.verticalSpace,
              CustomFormField(
                controller: controller.addressController,
                hint: 'Address / Region',
                maxLines: 2,
              ),
              14.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      onPressed: controller.cancelEditingProfile,
                      backgroundColor: theme.primaryColorDark,
                      foregroundColor:
                          theme.appBarTheme.iconTheme?.color ?? Colors.white,
                      radius: 10,
                      verticalPadding: 10,
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: CustomButton(
                      text: 'Save',
                      onPressed: controller.saveCustomerData,
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      radius: 10,
                      verticalPadding: 10,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _infoField(ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primaryColorDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.primaryColor),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
                2.verticalSpace,
                Text(value.isEmpty ? '—' : value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── membership progress card ─────────────────────────────────────────────

  Widget _membershipProgressCard(ThemeData theme) {
    return Obx(() {
      final pts = Get.isRegistered<BaseController>()
          ? Get.find<BaseController>().userPoints.value
          : 0;
      const bronzeMax = 5000;
      const goldMax = 10000;
      final String nextTier;
      final int ptsToNext;
      final double progress;
      if (pts < bronzeMax) {
        nextTier = 'Silver Member';
        ptsToNext = bronzeMax - pts;
        progress = pts / bronzeMax;
      } else if (pts < goldMax) {
        nextTier = 'Gold Member';
        ptsToNext = goldMax - pts;
        progress = (pts - bronzeMax) / (goldMax - bronzeMax);
      } else {
        nextTier = 'Platinum Member';
        ptsToNext = 0;
        progress = 1.0;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _card(theme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Membership Progress',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            16.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Next: $nextTier',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  ptsToNext > 0 ? '$ptsToNext pts left' : 'Max tier',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
            10.verticalSpace,
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: theme.primaryColorDark,
                valueColor: const AlwaysStoppedAnimation<Color>(_purple),
              ),
            ),
            10.verticalSpace,
            Text(
              'Earn more points to unlock exclusive rewards and higher tier benefits.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      );
    });
  }

  // ─── stat cards row ───────────────────────────────────────────────────────

  Widget _statsRow(ThemeData theme) {
    return Obx(() {
      OrdersStats? stats;
      if (Get.isRegistered<HomeController>()) {
        stats = Get.find<HomeController>().ordersStats.value;
      }
      final pts = Get.isRegistered<BaseController>()
          ? Get.find<BaseController>().userPoints.value
          : stats?.currentPoints ?? 0;

      return Row(
        children: [
          Expanded(
            child: _statCard(
              theme,
              'Total Points\nEarned',
              '$pts',
              icon: Icons.stars_rounded,
              iconColor: _purple,
              badge: '+12%',
              badgeColor: Colors.green.shade600,
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: _statCard(
              theme,
              'Rewards\nRedeemed',
              '${stats?.totalOrders ?? 0}',
              icon: Icons.card_giftcard_outlined,
              iconColor: Colors.orange,
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: _statCard(
              theme,
              'Active\nMissions',
              '3',
              icon: Icons.flag_outlined,
              iconColor: Colors.blue,
            ),
          ),
        ],
      );
    });
  }

  Widget _statCard(
    ThemeData theme,
    String label,
    String value, {
    required IconData icon,
    required Color iconColor,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? Colors.green).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                        fontSize: 10,
                        color: badgeColor ?? Colors.green,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          12.verticalSpace,
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          4.verticalSpace,
          Text(label,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }

  // ─── redemption history card ──────────────────────────────────────────────

  Widget _redemptionHistoryCard(ThemeData theme) {
    final rows = [
      ['2024-01-15', 'Coffee RedemptionCode', 'Café Armonía', '-150 pts'],
      ['2024-01-10', 'Discount 20%', 'Tienda Moda', '-300 pts'],
      ['2024-01-05', 'Free Delivery', 'Supermercado X', '-100 pts'],
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _card(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Redemption History',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          16.verticalSpace,
          // Table header
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text('Date',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w600))),
              Expanded(
                  flex: 3,
                  child: Text('Item',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w600))),
              Expanded(
                  flex: 3,
                  child: Text('Store',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w600))),
              Expanded(
                  flex: 2,
                  child: Text('Points Spent',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w600))),
            ],
          ),
          8.verticalSpace,
          Divider(color: theme.dividerColor, height: 1),
          ...rows.map((r) => _historyRow(theme, r[0], r[1], r[2], r[3])),
        ],
      ),
    );
  }

  Widget _historyRow(
      ThemeData theme, String date, String item, String store, String pts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(date, style: theme.textTheme.bodySmall)),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.card_giftcard,
                      size: 12, color: _purple),
                ),
                6.horizontalSpace,
                Expanded(
                    child: Text(item,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(
              flex: 3,
              child: Text(store,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Text(pts,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade400, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── settings card ────────────────────────────────────────────────────────

  Widget _settingsCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _card(theme),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferences',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            16.verticalSpace,
            Text('Language',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor, fontWeight: FontWeight.w600)),
            10.verticalSpace,
            Row(
              children: [
                Expanded(
                    child: _langButton(
                        theme, 'Español', 'es',
                        controller.selectedLanguageCode.value == 'es')),
                10.horizontalSpace,
                Expanded(
                    child: _langButton(
                        theme, 'English', 'en',
                        controller.selectedLanguageCode.value == 'en')),
              ],
            ),
            16.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dark Mode',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    2.verticalSpace,
                    Text(
                      controller.isDarkMode.value ? 'Enabled' : 'Disabled',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
                Switch(
                  value: controller.isDarkMode.value,
                  onChanged: controller.toggleDarkMode,
                  activeThumbColor: theme.primaryColor,
                ),
              ],
            ),
            16.verticalSpace,
            const Divider(height: 1),
            16.verticalSpace,
            GestureDetector(
              onTap: () => Get.toNamed(Routes.PREFERENCES),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined,
                      size: 18, color: _purple),
                  8.horizontalSpace,
                  Expanded(
                    child: Text('Notification Preferences',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _langButton(ThemeData theme, String label, String code, bool selected) {
    return GestureDetector(
      onTap: () => controller.changeLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor : theme.primaryColorDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : (theme.textTheme.bodyMedium?.color ?? Colors.black),
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ─── actions card ─────────────────────────────────────────────────────────

  Widget _actionsCard(ThemeData theme) {
    return Column(
      children: [
        CustomButton(
          text: 'Change Password',
          onPressed: () => Get.toNamed(Routes.CHANGE_PASSWORD),
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          radius: 12,
          verticalPadding: 14,
        ),
        10.verticalSpace,
        CustomButton(
          text: 'Cerrar sesión',
          onPressed: controller.logout,
          backgroundColor: theme.primaryColorDark,
          foregroundColor:
              theme.appBarTheme.iconTheme?.color ?? Colors.white,
          radius: 12,
          verticalPadding: 14,
        ),
        10.verticalSpace,
        CustomButton(
          text: 'Darme de baja',
          onPressed: controller.unsubscribeService,
          backgroundColor: theme.colorScheme.error,
          foregroundColor: Colors.white,
          radius: 12,
          verticalPadding: 14,
        ),
      ],
    );
  }
}
