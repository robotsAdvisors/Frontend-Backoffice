import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/support_ticket_model.dart';
import '../../../data/models/ticket_category_model.dart';
import '../controllers/support_controller.dart';
import 'backoffice_sidebar.dart';

class SupportTicketsView extends StatefulWidget {
  const SupportTicketsView({super.key});

  @override
  State<SupportTicketsView> createState() => _SupportTicketsViewState();
}

class _SupportTicketsViewState extends State<SupportTicketsView> {
  static const Color _purple      = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _bg          = Color(0xFFF8F7FF);

  late final SupportController _ctrl;

  final _searchCtrl  = TextEditingController();
  final _composeCtrl = TextEditingController();
  final _scrollCtrl  = ScrollController();
  bool _isInternal   = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl   = Get.find<SupportController>();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _composeCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), () {
      _ctrl.searchQuery.value = v.trim();
      _ctrl.applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(children: [
        BackofficeSidebar(current: 'tickets'),
        Expanded(
          child: Row(children: [
            SizedBox(width: 380, child: _ticketList()),
            Expanded(child: _ticketDetail()),
          ]),
        ),
      ]),
    );
  }

  // ─── SIDEBAR ──────────────────────────────────────────────────────────────

  // ─── LEFT: TICKET LIST ─────────────────────────────────────────────────────

  Widget _ticketList() {
    return Container(
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
          child: Row(children: [
            const Expanded(child: Text('Gestión de Tickets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: Color(0xFF111827)))),
            ElevatedButton.icon(
              onPressed: () => _showNewTicketDialog(context),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('Nuevo Ticket',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ]),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SizedBox(height: 34,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar tickets, usuario...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey.shade400),
                filled: true, fillColor: const Color(0xFFF5F5F5), isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none)),
            ),
          ),
        ),
        // Filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Obx(() => Row(children: [
            // Status
            Expanded(child: _filterDrop<String>(
              value: _ctrl.statusFilter.value.isEmpty
                  ? 'all' : _ctrl.statusFilter.value,
              items: const {
                'all':        'Estado',
                'open':       'Abierto',
                'pending':    'Pendiente',
                'prioritized':'Priorizado',
                'escalated':  'Escalado',
                'resolved':   'Resuelto',
                'closed':     'Cerrado',
              },
              onChanged: (v) {
                _ctrl.statusFilter.value = v == 'all' ? '' : (v ?? '');
                _ctrl.applyFilters();
              },
            )),
            const SizedBox(width: 6),
            // Category — from backend GET /admin/ticket-categories/
            Expanded(child: _filterDrop<String>(
              value: _ctrl.categoryFilter.value.isEmpty
                  ? 'all' : _ctrl.categoryFilter.value,
              items: {
                'all': 'Categoría',
                for (final c in _ctrl.categories) c.name: c.name,
              },
              onChanged: (v) {
                _ctrl.categoryFilter.value = v == 'all' ? '' : (v ?? '');
                _ctrl.applyFilters();
              },
            )),
            const SizedBox(width: 6),
            // Priority
            Expanded(child: _filterDrop<String>(
              value: _ctrl.priorityFilter.value.isEmpty
                  ? 'all' : _ctrl.priorityFilter.value,
              items: const {
                'all':    'Prioridad',
                'LOW':    'Baja',
                'MEDIUM': 'Media',
                'HIGH':   'Alta',
              },
              onChanged: (v) {
                _ctrl.priorityFilter.value = v == 'all' ? '' : (v ?? '');
                _ctrl.applyFilters();
              },
            )),
            const SizedBox(width: 6),
            // Date chip
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(primary: _purple)),
                    child: child!),
                );
                if (picked != null) {
                  _ctrl.dateFilter.value =
                      '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
                  _ctrl.applyFilters();
                }
              },
              child: Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _ctrl.dateFilter.value.isNotEmpty
                      ? _purpleLight : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today_outlined, size: 13,
                      color: _ctrl.dateFilter.value.isNotEmpty
                          ? _purple : Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _ctrl.dateFilter.value.isNotEmpty
                        ? _ctrl.dateFilter.value.substring(5) // MM-DD
                        : 'Fecha',
                    style: TextStyle(fontSize: 11,
                        color: _ctrl.dateFilter.value.isNotEmpty
                            ? _purple : Colors.grey.shade600)),
                  if (_ctrl.dateFilter.value.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        _ctrl.dateFilter.value = '';
                        _ctrl.applyFilters();
                      },
                      child: const Icon(Icons.close, size: 11, color: _purple)),
                  ],
                ]),
              )),
            ),
          ])),  // end Obx Row
        ),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            border: Border(
              top: BorderSide(color: Color(0xFFF3F4F6)),
              bottom: BorderSide(color: Color(0xFFF3F4F6)))),
          child: const Row(children: [
            Expanded(flex: 4, child: Text('TICKET',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: Colors.grey, letterSpacing: 0.6))),
            Expanded(flex: 3, child: Text('USUARIO',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: Colors.grey, letterSpacing: 0.6))),
            SizedBox(width: 72, child: Text('CATEGORÍA',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: Colors.grey, letterSpacing: 0.6))),
          ]),
        ),
        // Ticket rows
        Expanded(
          child: Obx(() {
            if (_ctrl.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = _ctrl.tickets.toList();
            if (items.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay tickets que coincidan.',
                    style: TextStyle(color: Colors.grey))));
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
              itemBuilder: (_, i) => _ticketRow(items[i]),
            );
          }),
        ),
      ]),
    );
  }

  Widget _ticketRow(SupportTicketModel t) {
    return Obx(() {
      final isSelected = _ctrl.selectedTicket.value?.id == t.id;
      final initials = t.userName.split(' ')
          .where((w) => w.isNotEmpty).take(2)
          .map((w) => w[0]).join().toUpperCase();
      return GestureDetector(
        onTap: () => _ctrl.selectTicket(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: isSelected ? _purpleLight.withValues(alpha: 0.5) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 4, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#${t.code}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: isSelected ? _purple : const Color(0xFF374151))),
              const SizedBox(height: 2),
              Text(t.title, style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
            Expanded(flex: 3, child: Row(children: [
              CircleAvatar(radius: 13, backgroundColor: _purpleLight,
                  child: Text(initials.isEmpty ? '?' : initials,
                      style: const TextStyle(fontSize: 9,
                          fontWeight: FontWeight.w700, color: _purple))),
              const SizedBox(width: 6),
              Expanded(child: Text(t.userName,
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                  overflow: TextOverflow.ellipsis)),
            ])),
            SizedBox(width: 72, child: _categoryPill(t.category)),
          ]),
        ),
      );
    });
  }

  Widget _filterDrop<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value, isDense: true, isExpanded: true,
          style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
          icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
          items: items.entries.map((e) => DropdownMenuItem<T>(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis, maxLines: 1),
          )).toList(),
          onChanged: onChanged),
      ),
    );
  }

  // ─── RIGHT: TICKET DETAIL ──────────────────────────────────────────────────

  Widget _ticketDetail() {
    return Obx(() {
      final ticket = _ctrl.selectedTicket.value;
      if (ticket == null) return _emptyState();
      return Column(children: [
        _detailHeader(ticket),
        Expanded(
          child: _ctrl.isLoadingDetail.value
              ? const Center(child: CircularProgressIndicator())
              : _conversationArea(ticket),
        ),
        _composeArea(ticket),
      ]);
    });
  }

  Widget _emptyState() {
    return Container(
      color: _bg,
      child: const Center(child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.support_agent_outlined, size: 56,
              color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text('Selecciona un ticket para ver el detalle',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF))),
          SizedBox(height: 6),
          Text('Haz clic en cualquier ticket de la lista.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      )),
    );
  }

  Widget _detailHeader(SupportTicketModel ticket) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('#${ticket.code}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: Color(0xFF111827))),
          const SizedBox(width: 8),
          _statusBadge(ticket.status),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 18),
            onPressed: () {}, padding: EdgeInsets.zero,
            constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          Obx(() => PopupMenuButton<String>(
            onSelected: (action) => _handleHeaderAction(action, ticket),
            enabled: !_ctrl.isActing.value,
            icon: const Icon(Icons.more_vert, size: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'escalate',
                  child: Text('Escalar', style: TextStyle(fontSize: 13))),
              const PopupMenuItem(value: 'close',
                  child: Text('Cerrar ticket', style: TextStyle(fontSize: 13))),
              const PopupMenuItem(value: 'reassign',
                  child: Text('Reasignar', style: TextStyle(fontSize: 13))),
            ],
          )),
        ]),
        const SizedBox(height: 4),
        Text(ticket.title,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.person_outline, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            ticket.userExternalId.isNotEmpty
                ? '${ticket.userName} (ID: ${ticket.userExternalId})'
                : ticket.userName,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 16),
          const Icon(Icons.schedule_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text('Ticket creado el ${_fmtDateTime(ticket.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ]),
    );
  }

  void _handleHeaderAction(String action, SupportTicketModel ticket) {
    switch (action) {
      case 'escalate': _ctrl.escalateTicket(); break;
      case 'close':    _ctrl.closeTicket(); break;
      case 'reassign': _showReassignDialog(context, ticket); break;
    }
  }

  Widget _conversationArea(SupportTicketModel ticket) {
    final msgs = ticket.messages;
    if (msgs.isEmpty && ticket.description.isNotEmpty) {
      // Fabricate opening message from description when no messages loaded yet
      final opener = TicketMessageModel(
        id: '__desc__',
        senderName: ticket.userName,
        senderRole: 'user',
        body: ticket.description,
        isInternal: false,
        createdAt: ticket.createdAt,
      );
      return _messageList([opener]);
    }
    return _messageList(msgs);
  }

  Widget _messageList(List<TicketMessageModel> msgs) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut);
      }
    });
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      itemCount: msgs.length,
      itemBuilder: (_, i) => _messageBubble(msgs[i]),
    );
  }

  Widget _messageBubble(TicketMessageModel msg) {
    final isUser    = msg.senderRole == 'user';
    final isInternal = msg.isInternal;
    final initials  = msg.senderName.split(' ')
        .where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0]).join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: isUser
              ? _purple
              : isInternal
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF059669),
          child: Text(initials.isEmpty ? '?' : initials,
              style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: Colors.white))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(msg.senderName,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              const SizedBox(width: 8),
              if (isInternal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('Nota Interna',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280)))),
              const Spacer(),
              Text(_fmtTime(msg.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isInternal
                    ? const Color(0xFFF9FAFB)
                    : isUser
                        ? const Color(0xFFF5F3FF)
                        : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isInternal
                      ? const Color(0xFFE5E7EB)
                      : isUser
                          ? const Color(0xFFDDD6FE)
                          : const Color(0xFFE5E7EB))),
              child: Text(msg.body,
                  style: const TextStyle(fontSize: 13,
                      color: Color(0xFF374151), height: 1.5)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _composeArea(SupportTicketModel ticket) {
    final isClosed = ticket.status == 'closed' || ticket.status == 'resolved';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Toggle: Respuesta Visible | Nota Interna
        Row(children: [
          _toggleBtn('Respuesta Visible', !_isInternal,
              () => setState(() => _isInternal = false)),
          const SizedBox(width: 6),
          _toggleBtn('Nota Interna', _isInternal,
              () => setState(() => _isInternal = true)),
        ]),
        const SizedBox(height: 10),
        // Text field
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(children: [
            TextField(
              controller: _composeCtrl,
              enabled: !isClosed,
              maxLines: 3, minLines: 2,
              decoration: InputDecoration(
                hintText: isClosed
                    ? 'Ticket cerrado'
                    : 'Escribe tu respuesta...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.all(12),
                border: InputBorder.none),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(children: [
                const Spacer(),
                Obx(() => IconButton(
                  icon: _ctrl.isSending.value
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.send_rounded, size: 18,
                          color: isClosed ? Colors.grey : _purple),
                  onPressed: isClosed || _ctrl.isSending.value ? null : () async {
                    final body = _composeCtrl.text.trim();
                    if (body.isEmpty) return;
                    await _ctrl.sendMessage(body, isInternal: _isInternal);
                    _composeCtrl.clear();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints())),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        // Actions row
        Row(children: [
          _actionBtn(Icons.swap_horiz, 'Reasignar',
              onTap: () => _showReassignDialog(context, ticket)),
          const SizedBox(width: 8),
          _actionBtn(Icons.arrow_upward_rounded, 'Escalar',
              onTap: _ctrl.escalateTicket, color: const Color(0xFFD97706)),
          const Spacer(),
          Obx(() => ElevatedButton.icon(
            onPressed: isClosed || _ctrl.isActing.value ? null : () async {
              final body = _composeCtrl.text.trim();
              if (body.isNotEmpty) {
                await _ctrl.sendMessage(body, isInternal: _isInternal);
                _composeCtrl.clear();
              }
              await _ctrl.closeTicket();
            },
            icon: _ctrl.isActing.value
                ? const SizedBox(width: 13, height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline, size: 15, color: Colors.white),
            label: const Text('Enviar y Cerrar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isClosed ? Colors.grey.shade300 : _purple,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          )),
        ]),
      ]),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _purple : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey.shade600))),
    );
  }

  Widget _actionBtn(IconData icon, String label,
      {required VoidCallback onTap, Color color = const Color(0xFF374151)}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // ─── DIALOGS ──────────────────────────────────────────────────────────────

  void _showNewTicketDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    TicketCategoryModel? selCategory;
    String selPriority = 'MEDIUM';

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _purple, width: 1.4)),
        );

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(t,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
        );

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(children: [
                    Icon(Icons.add_circle_outline, color: _purple, size: 20),
                    SizedBox(width: 8),
                    Text('Nuevo Ticket',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827))),
                  ]),
                  const SizedBox(height: 16),
                  label('Título'),
                  TextField(
                      controller: titleCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: deco('Asunto del ticket')),
                  const SizedBox(height: 12),
                  label('Descripción'),
                  TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: deco('Detalle del problema')),
                  const SizedBox(height: 12),
                  label('Email del usuario'),
                  TextField(
                      controller: userCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 14),
                      decoration: deco('correo@ejemplo.com')),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Categoría'),
                          DropdownButtonFormField<TicketCategoryModel>(
                            initialValue: selCategory,
                            isExpanded: true,
                            hint: Text(
                                _ctrl.categories.isEmpty
                                    ? 'Sin categorías'
                                    : 'Opcional',
                                style: const TextStyle(fontSize: 13)),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF111827)),
                            decoration: deco(''),
                            items: _ctrl.categories
                                .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.name,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) =>
                                setDlgState(() => selCategory = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Prioridad'),
                          DropdownButtonFormField<String>(
                            initialValue: selPriority,
                            isExpanded: true,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF111827)),
                            decoration: deco(''),
                            items: const [
                              DropdownMenuItem(
                                  value: 'LOW',
                                  child: Text('Baja',
                                      style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(
                                  value: 'MEDIUM',
                                  child: Text('Media',
                                      style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(
                                  value: 'HIGH',
                                  child: Text('Alta',
                                      style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (v) => setDlgState(
                                () => selPriority = v ?? 'MEDIUM'),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancelar')),
                      const SizedBox(width: 8),
                      Obx(() => ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            onPressed: _ctrl.isCreating.value
                                ? null
                                : () async {
                                    if (titleCtrl.text.trim().isEmpty ||
                                        userCtrl.text.trim().isEmpty) {
                                      Get.snackbar('Faltan datos',
                                          'El título y el email del usuario son obligatorios',
                                          snackPosition: SnackPosition.BOTTOM);
                                      return;
                                    }
                                    final ok = await _ctrl.createTicket(
                                      title: titleCtrl.text,
                                      description: descCtrl.text,
                                      userEmail: userCtrl.text.trim(),
                                      priority: selPriority,
                                      categoryId: selCategory?.id,
                                    );
                                    if (ok && ctx.mounted) {
                                      Navigator.of(ctx).pop();
                                    }
                                  },
                            child: _ctrl.isCreating.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Crear Ticket',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReassignDialog(BuildContext context, SupportTicketModel ticket) {
    // GET /admin/agents/ → dropdown de agentes staff activos
    AgentModel? selected;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.swap_horiz, color: _purple, size: 20),
            SizedBox(width: 8), Text('Reasignar Ticket'),
          ]),
          content: SizedBox(width: 340, child: Column(
              mainAxisSize: MainAxisSize.min, children: [
            if (_ctrl.agents.isEmpty)
              const Text('Sin agentes disponibles.',
                  style: TextStyle(color: Colors.grey))
            else
              DropdownButtonFormField<AgentModel>(
                initialValue: selected,
                hint: const Text('Seleccionar agente',
                    style: TextStyle(fontSize: 13)),
                decoration: const InputDecoration(isDense: true),
                items: _ctrl.agents.map((a) => DropdownMenuItem(
                    value: a,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(a.fullName.isNotEmpty ? a.fullName : a.email,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        if (a.fullName.isNotEmpty)
                          Text(a.email,
                              style: const TextStyle(fontSize: 10,
                                  color: Colors.grey)),
                      ],
                    ))).toList(),
                onChanged: (v) => setDlgState(() => selected = v),
              ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: selected == null ? null : () {
                Navigator.of(ctx).pop();
                _ctrl.reassignTicket(selected!.id, selected!.toString());
              },
              child: const Text('Reasignar')),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Widget _categoryPill(String category) {
    // Lookup color from GET /admin/ticket-categories/ (loaded in _ctrl.categories)
    final match = _ctrl.categories.cast<TicketCategoryModel?>().firstWhere(
        (c) => c?.name.toLowerCase() == category.toLowerCase(),
        orElse: () => null);
    final Color fg;
    final Color bg;
    final String label;
    if (match != null) {
      fg    = match.flutterColor;
      bg    = match.flutterColor.withValues(alpha: 0.12);
      label = match.name;
    } else {
      // Fallback static palette while categories load
      switch (category.toLowerCase()) {
        case 'puntos':
          bg = const Color(0xFFEDE9FE); fg = _purple;                  label = 'Puntos'; break;
        case 'cuenta':
          bg = const Color(0xFFECFDF5); fg = const Color(0xFF059669);  label = 'Cuenta'; break;
        case 'pagos':
          bg = const Color(0xFFFFF7ED); fg = const Color(0xFFD97706);  label = 'Pagos';  break;
        case 'legal':
          bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626);  label = 'Legal';  break;
        case 'kyc': case 'kybc':
          bg = const Color(0xFFEFF6FF); fg = const Color(0xFF2563EB);  label = 'KYC';    break;
        default:
          bg = const Color(0xFFF3F4F6); fg = const Color(0xFF6B7280);
          label = category.isNotEmpty ? category : 'Otro';             break;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 9,
          fontWeight: FontWeight.w700, color: fg),
          overflow: TextOverflow.ellipsis));
  }

  Widget _statusBadge(String status) {
    final Color bg; final Color fg; final String label;
    switch (status.toLowerCase()) {
      case 'open':
        bg = const Color(0xFFEFF6FF); fg = const Color(0xFF2563EB); label = 'Abierto'; break;
      case 'pending':
        bg = const Color(0xFFFFF7ED); fg = const Color(0xFFD97706); label = 'Pendiente'; break;
      case 'prioritized':
        bg = const Color(0xFFF5F3FF); fg = _purple;                 label = 'Priorizando'; break;
      case 'escalated':
        bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626); label = 'Escalado'; break;
      case 'resolved':
        bg = const Color(0xFFECFDF5); fg = const Color(0xFF059669); label = 'Resuelto'; break;
      case 'closed':
        bg = const Color(0xFFF3F4F6); fg = const Color(0xFF6B7280); label = 'Cerrado'; break;
      default:
        bg = const Color(0xFFF3F4F6); fg = Colors.grey;             label = status; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 9,
          fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.5)));
  }

  String _fmtDateTime(DateTime d) {
    final local = d.toLocal();
    const m = ['', 'Ene','Feb','Mar','Abr','May','Jun',
                'Jul','Ago','Sep','Oct','Nov','Dic'];
    final time = '${local.hour.toString().padLeft(2,'0')}:'
                 '${local.minute.toString().padLeft(2,'0')}';
    return '${local.day}/${m[local.month]}/${local.year} - $time';
  }

  String _fmtTime(DateTime d) {
    final local = d.toLocal();
    return '${local.hour.toString().padLeft(2,'0')}:'
           '${local.minute.toString().padLeft(2,'0')}';
  }

}
