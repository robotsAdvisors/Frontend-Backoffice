/// Envelope paginado del backend (DRF): `{results, meta:{total, page, last_page}}`.
/// Se toleran también las claves `data` / `lastPage` por compatibilidad.
class PageMeta {
  final int total;
  final int page;
  final int lastPage;

  const PageMeta({this.total = 0, this.page = 1, this.lastPage = 1});

  factory PageMeta.fromJson(Map<String, dynamic> json) {
    return PageMeta(
      total: _toInt(json['total']),
      page: _toInt(json['page'], fallback: 1),
      // El backend serializa `last_page` (snake_case); se acepta también
      // `lastPage` por si algún endpoint lo devuelve ya en camelCase.
      lastPage: _toInt(json['last_page'] ?? json['lastPage'], fallback: 1),
    );
  }

  bool get hasMore => page < lastPage;
}

class Paginated<T> {
  final List<T> data;
  final PageMeta meta;

  const Paginated({required this.data, required this.meta});

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    // El backend pagina como `{results, meta}` (DRF); se acepta también `data`
    // por compatibilidad con endpoints que devuelvan ese envelope.
    final raw = (json['results'] as List?) ?? (json['data'] as List?) ?? const [];
    final metaRaw = Map<String, dynamic>.from(
      (json['meta'] as Map?) ?? const {},
    );
    return Paginated<T>(
      data: raw
          .whereType<Map>()
          .map((e) => itemFromJson(Map<String, dynamic>.from(e)))
          .toList(),
      meta: PageMeta.fromJson(metaRaw),
    );
  }
}

int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}
