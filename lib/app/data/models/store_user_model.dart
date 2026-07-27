class StoreUserModel {
  // Backend role values (uppercase)
  static const String roleOwner  = 'OWNER';
  static const String roleAdmin  = 'ADMIN';
  static const String roleViewer = 'VIEWER';
  static const String roleMember = 'MEMBER';

  final String id;
  final String email;
  final String name;
  final String role; // OWNER | ADMIN | MEMBER
  final String storeId;
  final String? avatarUrl;
  final bool isActive;
  final bool isOnline;
  final DateTime? lastActiveAt;
  final DateTime createdAt;
  /// Permisos del miembro (products, redemption_codes, analytics, team, settings).
  /// OWNER y ADMIN reciben hoy el set completo; VIEWER/MEMBER, uno más corto.
  final List<String> permissions;
  /// Email de quien invitó al miembro. `null` para el OWNER (no fue invitado).
  final String? invitedBy;

  StoreUserModel({
    required this.id,
    required this.email,
    this.name = '',
    required this.role,
    required this.storeId,
    this.avatarUrl,
    this.isActive = true,
    this.isOnline = false,
    this.lastActiveAt,
    required this.createdAt,
    this.permissions = const [],
    this.invitedBy,
  });

  String get displayName {
    if (name.isNotEmpty) return name;
    return email.contains('@') ? email.split('@').first : email;
  }

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  /// Etiqueta de rol localizada para mostrar en la UI.
  String get roleLabel {
    switch (role.toUpperCase()) {
      case roleOwner:
        return 'Propietario';
      case roleAdmin:
        return 'Administrador';
      case roleViewer:
        return 'Visualizador';
      case roleMember:
        return 'Miembro';
      case 'MANAGER':
        return 'Manager';
      case 'VALIDATOR':
      case 'VALIDADOR':
        return 'Validador';
      case 'STORE_ADMIN':
        return 'Administrador';
      case 'STORE_VIEWER':
        return 'Visualizador';
      default:
        return role;
    }
  }

  String get presenceLabel {
    if (isOnline) return 'En línea';
    if (lastActiveAt != null) {
      final diff = DateTime.now().difference(lastActiveAt!);
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    }
    return 'Desconectado';
  }

  bool get isOwner => role.toUpperCase() == roleOwner;
  bool get isAdmin => role.toUpperCase() == roleAdmin || isOwner;
  bool get canBeRemoved => !isOwner;

  factory StoreUserModel.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    final String email;
    final String name;
    final String id;
    final String? avatarUrl;

    if (userRaw is Map) {
      id = (userRaw['id'] ?? json['id'] ?? '').toString();
      email = (userRaw['email'] ?? '').toString();
      final fn = (userRaw['first_name'] ?? '').toString().trim();
      final ln = (userRaw['last_name'] ?? '').toString().trim();
      name = [fn, ln].where((s) => s.isNotEmpty).join(' ').trim().isNotEmpty
          ? [fn, ln].where((s) => s.isNotEmpty).join(' ')
          : (userRaw['name'] ?? userRaw['username'] ?? '').toString();
      avatarUrl = userRaw['avatar']?.toString() ?? userRaw['photo']?.toString();
    } else {
      // El endpoint de miembros usa `user_id`; otros usan `id`; y Django a veces
      // aplana con doble guion bajo (`user__id`), como en store_memberships.
      id = (json['id'] ?? json['user_id'] ?? json['user__id'] ?? '').toString();
      email = (json['email'] ?? json['user__email'] ?? '').toString();
      name = (json['name'] ??
              json['full_name'] ??
              json['user__full_name'] ??
              json['user__name'] ??
              '')
          .toString();
      avatarUrl = json['avatar']?.toString() ?? json['avatar_url']?.toString();
    }

    final storeRaw = json['store'];
    final storeId = storeRaw is Map
        ? (storeRaw['id'] ?? '').toString()
        : (json['store_id'] ?? json['storeId'] ?? storeRaw ?? '').toString();

    return StoreUserModel(
      id: id,
      email: email,
      name: name,
      role: (json['role'] ?? '').toString(),
      storeId: storeId,
      avatarUrl: avatarUrl,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      isOnline: json['is_online'] as bool? ?? false,
      lastActiveAt: DateTime.tryParse(
          (json['last_active_at'] ?? json['lastActiveAt'] ?? '').toString()),
      permissions: json['permissions'] is List
          ? (json['permissions'] as List).map((e) => e.toString()).toList()
          : const [],
      invitedBy: json['invited_by']?.toString(),
      createdAt: DateTime.tryParse((json['created_at'] ??
                  json['createdAt'] ??
                  json['created'] ??
                  json['joined_at'] ??
                  '')
              .toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'storeId': storeId,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
