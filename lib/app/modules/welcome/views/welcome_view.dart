import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../components/custom_button.dart';
import '../../../routes/app_pages.dart';
import '../controllers/welcome_controller.dart';

class WelcomeView extends GetView<WelcomeController> {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32.h),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/vectors/letdem_logo.svg',
                          width: 200.w,
                          height: 48.h,
                          fit: BoxFit.contain,
                        ).animate().fade().slideY(
                              duration: 300.ms,
                              begin: -1,
                              curve: Curves.easeInSine,
                            ),
                        28.verticalSpace,
                        Text(
                          'Bienvenido a Letdem',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 24.sp,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fade().slideY(
                              duration: 300.ms,
                              begin: -1,
                              curve: Curves.easeInSine,
                            ),
                        12.verticalSpace,
                        Text(
                          'Tu marketplace de productos frescos con beneficios, redemptionCodes y experiencia personalizada.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15.sp,
                            height: 1.5,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fade().slideY(
                              duration: 300.ms,
                              begin: 1,
                              curve: Curves.easeInSine,
                            ),
                        36.verticalSpace,
                        CustomButton(
                          text: 'Comenzar',
                          onPressed: () => Get.offNamed(Routes.LOGIN),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          radius: 14.r,
                          verticalPadding: 16.h,
                        ).animate().fade().slideY(
                              duration: 300.ms,
                              begin: 1,
                              curve: Curves.easeInSine,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
