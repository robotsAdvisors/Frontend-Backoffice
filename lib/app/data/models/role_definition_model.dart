class RoleDefinitionModel {
  final String role;
  final String label;
  final List<String> permissions; // slugs: products, redemption_codes, analytics, team, settings
  final bool assignable;

  const RoleDefinitionModel({
    required this.role,
    required this.label,
    required this.permissions,
    required this.assignable,
  });

  factory RoleDefinitionModel.fromJson(Map<String, dynamic> json) {
    return RoleDefinitionModel(
      role:        (json['role']  ?? '').toString(),
      label:       (json['label'] ?? '').toString(),
      permissions: (json['permissions'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      assignable:  json['assignable'] as bool? ?? false,
    );
  }

  bool hasPermission(String slug) => permissions.contains(slug);
}

/// Slugs que devuelve el backend y su representación en la UI.
class RolePermissionSlug {
  static const products        = 'products';
  static const redemptionCodes = 'redemption_codes';
  static const analytics       = 'analytics';
  static const team            = 'team';
  static const settings        = 'settings';

  static String toLabel(String slug) => switch (slug) {
    products        => 'Productos y stock',
    redemptionCodes => 'Canjes y códigos',
    analytics => 'Historial y estadísticas',
    team      => 'Gestión de equipo',
    settings  => 'Configuración fiscal',
    _         => slug,
  };
}
