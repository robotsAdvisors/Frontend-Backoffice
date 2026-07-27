import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../../utils/api_config.dart';
import '../../../components/custom_snackbar.dart';
import '../../../data/models/support_ticket_model.dart';
import '../../../data/models/ticket_category_model.dart';
import '../../../data/services/http/api_client.dart';

class AgentModel {
  final String id;
  final String email;
  final String fullName;
  const AgentModel({required this.id, required this.email, required this.fullName});
  factory AgentModel.fromJson(Map<String, dynamic> json) => AgentModel(
        id: (json['id'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        fullName: (json['full_name'] ?? json['name'] ?? json['email'] ?? '').toString(),
      );
  @override
  String toString() => fullName.isNotEmpty ? fullName : email;
}

class SupportController extends GetxController {
  final RxList<SupportTicketModel>  tickets    = <SupportTicketModel>[].obs;
  final RxList<TicketCategoryModel> categories = <TicketCategoryModel>[].obs;
  final RxList<AgentModel>          agents     = <AgentModel>[].obs;

  final Rx<SupportTicketModel?> selectedTicket = Rx<SupportTicketModel?>(null);

  final RxBool isLoading        = false.obs;
  final RxBool isLoadingDetail  = false.obs;
  final RxBool isLoadingMeta    = false.obs; // categories + agents
  final RxBool isSending        = false.obs;
  final RxBool isActing         = false.obs;
  final RxBool isCreating       = false.obs;

  // Filters — all passed server-side to GET /admin/tickets/
  final RxString statusFilter   = ''.obs;
  final RxString categoryFilter = ''.obs;
  final RxString priorityFilter = ''.obs;
  final RxString dateFilter     = ''.obs;   // YYYY-MM-DD
  final RxString searchQuery    = ''.obs;   // server-side search

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalCount  = 0.obs;
  static const int _pageSize = 20;

  final _dio = ApiClient.instance.dio;

  @override
  void onInit() {
    super.onInit();
    _loadMeta();
    loadTickets();
  }

  // ─── Meta (categories + agents) ────────────────────────────────────────────

  Future<void> _loadMeta() async {
    isLoadingMeta.value = true;
    try {
      final results = await Future.wait([
        _dio.get(ApiConfig.adminTicketCategories),
        _dio.get(ApiConfig.adminAgents),
      ]);

      final catData = results[0].data;
      if (catData is List) {
        categories.assignAll(catData
            .whereType<Map>()
            .map((m) => TicketCategoryModel.fromJson(Map<String, dynamic>.from(m))));
      }

      final agentData = results[1].data;
      if (agentData is List) {
        agents.assignAll(agentData
            .whereType<Map>()
            .map((m) => AgentModel.fromJson(Map<String, dynamic>.from(m))));
      } else if (agentData is Map) {
        final items = agentData['results'] ?? agentData['data'] ?? [];
        if (items is List) {
          agents.assignAll(items
              .whereType<Map>()
              .map((m) => AgentModel.fromJson(Map<String, dynamic>.from(m))));
        }
      }
    } catch (_) {
      // Keep empty lists — UI shows fallback
    } finally {
      isLoadingMeta.value = false;
    }
  }

  // ─── List ──────────────────────────────────────────────────────────────────

  Future<void> loadTickets({int page = 1}) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final resp = await _dio.get(
        ApiConfig.adminTickets,
        queryParameters: {
          'page':      page,
          'page_size': _pageSize,
          if (statusFilter.value.isNotEmpty)   'status':   statusFilter.value,
          if (categoryFilter.value.isNotEmpty) 'category': categoryFilter.value,
          if (priorityFilter.value.isNotEmpty) 'priority': priorityFilter.value,
          if (dateFilter.value.isNotEmpty)     'date':     dateFilter.value,
          if (searchQuery.value.isNotEmpty)    'search':   searchQuery.value,
        },
      );
      final data = resp.data;
      List<dynamic> items;
      if (data is Map) {
        items = (data['results'] ?? data['data'] ?? []) as List;
        totalCount.value =
            (data['count'] ?? data['total'] ?? items.length) as int;
      } else if (data is List) {
        items = data;
        totalCount.value = items.length;
      } else {
        items = [];
      }
      final parsed = items
          .whereType<Map>()
          .map((m) => SupportTicketModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      if (page == 1) {
        tickets.assignAll(parsed);
      } else {
        tickets.addAll(parsed);
      }
      currentPage.value = page;
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['detail'] ?? e.message ?? 'Error de red')
          : (e.message ?? 'Error de red');
      CustomSnackBar.showCustomErrorSnackBar(title: 'Error', message: msg.toString());
    } catch (_) {
      // Silently keep previous data
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> applyFilters() async {
    currentPage.value = 1;
    await loadTickets(page: 1);
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  Future<bool> createTicket({
    required String title,
    required String description,
    required String userEmail,
    required String priority,
    int? categoryId,
    String? storeId,
  }) async {
    if (isCreating.value) return false;
    isCreating.value = true;
    try {
      final resp = await _dio.post(
        ApiConfig.adminTicketsCreate,
        data: {
          'title':       title.trim(),
          'description': description.trim(),
          'user_email':  userEmail.trim(),
          'priority':    priority,
          if (categoryId != null) 'category_id': categoryId,
          if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
        },
      );
      if (resp.data is Map) {
        final ticket = SupportTicketModel.fromJson(
            Map<String, dynamic>.from(resp.data as Map));
        tickets.insert(0, ticket);
        totalCount.value++;
        CustomSnackBar.showCustomSnackBar(
            title: 'Ticket creado', message: '#${ticket.code} creado correctamente.');
        return true;
      }
      return false;
    } catch (e) {
      // Usa el contrato de error del backend ({error_code, message, details})
      // y muestra el detalle por campo, para saber exactamente qué rechaza.
      final ex = toApiException(e);
      final detail = ex.details.isNotEmpty
          ? ex.details.entries.map((x) {
              final v = x.value;
              return '${x.key}: ${v is List ? v.join(', ') : v}';
            }).join('  ·  ')
          : '';
      CustomSnackBar.showCustomErrorSnackBar(
          title: 'Error al crear',
          message: detail.isNotEmpty ? '${ex.message}\n$detail' : ex.message);
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  // ─── Detail ────────────────────────────────────────────────────────────────

  Future<void> selectTicket(SupportTicketModel ticket) async {
    selectedTicket.value = ticket;
    if (ticket.messages.isEmpty) await _loadMessages(ticket.id);
  }

  Future<void> _loadMessages(String ticketId) async {
    if (isLoadingDetail.value) return;
    isLoadingDetail.value = true;
    try {
      final resp = await _dio.get(ApiConfig.adminTicketDetail(ticketId));
      if (resp.data is Map) {
        final full = SupportTicketModel.fromJson(
            Map<String, dynamic>.from(resp.data as Map));
        selectedTicket.value = full;
        final idx = tickets.indexWhere((t) => t.id == ticketId);
        if (idx != -1) tickets[idx] = full;
      }
    } catch (_) {
      // Keep partial data
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ─── Send message ──────────────────────────────────────────────────────────

  Future<void> sendMessage(String body, {required bool isInternal}) async {
    final ticket = selectedTicket.value;
    if (ticket == null || body.trim().isEmpty || isSending.value) return;
    isSending.value = true;
    try {
      final resp = await _dio.post(
        ApiConfig.adminTicketMessages(ticket.id),
        data: {'body': body.trim(), 'is_internal': isInternal},
      );
      if (resp.data is Map) {
        final msg = TicketMessageModel.fromJson(
            Map<String, dynamic>.from(resp.data as Map));
        selectedTicket.value =
            ticket.copyWith(messages: [...ticket.messages, msg]);
      }
    } catch (e) {
      final ex = toApiException(e);
      CustomSnackBar.showCustomErrorSnackBar(
        title: 'Error',
        message: ex.isUnavailable
            ? 'El envío de mensajes aún no está disponible.'
            : ex.message,
      );
    } finally {
      isSending.value = false;
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  // Las rutas de acción dedicadas (/escalate/, /close/, /reassign/) no existen en
  // el backend; el cambio de estado y de asignación se hace vía el PATCH del
  // detalle (`AdminTicketDetailView`), que sí está expuesto.
  Future<void> escalateTicket() async {
    final ticket = selectedTicket.value;
    if (ticket == null || isActing.value) return;
    isActing.value = true;
    try {
      await _dio.patch(
        ApiConfig.adminTicketDetail(ticket.id),
        data: {'status': 'escalated'},
      );
      selectedTicket.value = ticket.copyWith(status: 'escalated');
      _syncStatus(ticket.id, 'escalated');
      CustomSnackBar.showCustomSnackBar(
          title: 'Escalado', message: 'Ticket escalado correctamente.');
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
          title: 'Error', message: toApiException(e).message);
    } finally {
      isActing.value = false;
    }
  }

  Future<void> closeTicket() async {
    final ticket = selectedTicket.value;
    if (ticket == null || isActing.value) return;
    isActing.value = true;
    try {
      await _dio.patch(
        ApiConfig.adminTicketDetail(ticket.id),
        data: {'status': 'closed'},
      );
      selectedTicket.value = ticket.copyWith(status: 'closed');
      _syncStatus(ticket.id, 'closed');
      CustomSnackBar.showCustomSnackBar(title: 'Cerrado', message: 'Ticket cerrado.');
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
          title: 'Error', message: toApiException(e).message);
    } finally {
      isActing.value = false;
    }
  }

  Future<void> reassignTicket(String agentId, String agentName) async {
    final ticket = selectedTicket.value;
    if (ticket == null || agentId.isEmpty || isActing.value) return;
    isActing.value = true;
    try {
      await _dio.patch(
        ApiConfig.adminTicketDetail(ticket.id),
        data: {'assigned_to': agentId},
      );
      // Relee el detalle para reflejar el nuevo responsable en la vista.
      await _loadMessages(ticket.id);
      CustomSnackBar.showCustomSnackBar(
          title: 'Reasignado', message: 'Ticket reasignado a $agentName.');
    } catch (e) {
      CustomSnackBar.showCustomErrorSnackBar(
          title: 'Error', message: toApiException(e).message);
    } finally {
      isActing.value = false;
    }
  }

  void _syncStatus(String id, String status) {
    final idx = tickets.indexWhere((t) => t.id == id);
    if (idx != -1) tickets[idx] = tickets[idx].copyWith(status: status);
  }
}
