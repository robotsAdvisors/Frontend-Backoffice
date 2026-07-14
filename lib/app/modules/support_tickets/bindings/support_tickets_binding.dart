import 'package:get/get.dart';
import '../controllers/support_controller.dart';

class SupportTicketsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupportController>(() => SupportController());
  }
}
