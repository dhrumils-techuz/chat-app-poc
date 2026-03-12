class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final itemsList = json['items'] as List? ?? json['data'] as List? ?? [];
    final total = json['totalCount'] as int? ??
        json['total'] as int? ??
        itemsList.length;
    final currentPage = json['page'] as int? ?? 1;
    final size = json['pageSize'] as int? ?? json['limit'] as int? ?? 20;
    final more = json['hasMore'] as bool? ?? (currentPage * size < total);

    return PaginatedResponse(
      items: itemsList
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      totalCount: total,
      page: currentPage,
      pageSize: size,
      hasMore: more,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'items': items.map((e) => toJsonT(e)).toList(),
      'totalCount': totalCount,
      'page': page,
      'pageSize': pageSize,
      'hasMore': hasMore,
    };
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get currentItemCount => items.length;
  bool get isFirstPage => page <= 1;
  int get totalPages => (totalCount / pageSize).ceil();
}
