class TicketMessageModel {
  final String id;
  final String senderName;
  final String senderRole; // 'user' | 'agent' | 'admin' | 'system'
  final String body;
  final bool isInternal;
  final DateTime createdAt;

  const TicketMessageModel({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.body,
    required this.isInternal,
    required this.createdAt,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final senderName = sender is Map
        ? (sender['name'] ?? sender['username'] ?? 'Agente').toString()
        : (json['sender_name'] ?? 'Agente').toString();
    final senderRole = sender is Map
        ? (sender['role'] ?? 'agent').toString()
        : (json['sender_role'] ?? 'agent').toString();
    return TicketMessageModel(
      id: (json['id'] ?? '').toString(),
      senderName: senderName,
      senderRole: senderRole,
      body: (json['body'] ?? json['content'] ?? '').toString(),
      isInternal: json['is_internal'] == true,
      createdAt: DateTime.tryParse(
              (json['created_at'] ?? json['created'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class SupportTicketModel {
  final String id;
  final String code;       // e.g. "TK-4821"
  final String title;
  final String description;
  final String status;     // 'open' | 'pending' | 'resolved' | 'closed' | 'prioritized' | 'escalated'
  final String category;   // 'puntos' | 'cuenta' | 'pagos' | 'legal' | 'kyc' | 'otro'
  final String priority;   // 'low' | 'normal' | 'high' | 'urgent'
  final String userId;
  final String userName;
  final String userEmail;
  final String userExternalId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketMessageModel> messages;

  const SupportTicketModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    required this.priority,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userExternalId,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final String userName = user is Map
        ? (user['name'] ?? user['full_name'] ??
            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim())
            .toString()
        : (json['user_name'] ?? '').toString();
    final String userEmail = user is Map
        ? (user['email'] ?? '').toString()
        : (json['user_email'] ?? '').toString();
    final String userId = user is Map
        ? (user['id'] ?? '').toString()
        : (json['user_id'] ?? '').toString();
    final String userExternalId = user is Map
        ? (user['external_id'] ?? user['id'] ?? '').toString()
        : userId;

    final rawMsgs = json['messages'];
    final msgs = rawMsgs is List
        ? rawMsgs
            .whereType<Map>()
            .map((m) => TicketMessageModel.fromJson(
                Map<String, dynamic>.from(m)))
            .toList()
        : <TicketMessageModel>[];

    final assignedRaw = json['assigned_to'];
    final String? assignedTo = assignedRaw is Map
        ? (assignedRaw['name'] ?? assignedRaw['username'])?.toString()
        : assignedRaw?.toString();

    return SupportTicketModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? json['ticket_code'] ?? '').toString(),
      title: (json['title'] ?? json['subject'] ?? '').toString(),
      description: (json['description'] ?? json['body'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString(),
      category: (json['category'] ?? 'otro').toString(),
      priority: (json['priority'] ?? 'normal').toString(),
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userExternalId: userExternalId,
      assignedTo: assignedTo,
      createdAt: DateTime.tryParse(
              (json['created_at'] ?? json['created'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
              (json['updated_at'] ?? json['updated'] ?? '').toString()) ??
          DateTime.now(),
      messages: msgs,
    );
  }

  SupportTicketModel copyWith({List<TicketMessageModel>? messages, String? status}) {
    return SupportTicketModel(
      id: id, code: code, title: title, description: description,
      status: status ?? this.status, category: category, priority: priority,
      userId: userId, userName: userName, userEmail: userEmail,
      userExternalId: userExternalId, assignedTo: assignedTo,
      createdAt: createdAt, updatedAt: updatedAt,
      messages: messages ?? this.messages,
    );
  }
}
