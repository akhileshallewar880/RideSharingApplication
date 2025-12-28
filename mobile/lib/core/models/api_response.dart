/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'errors': errors,
    };
  }

  bool get isSuccess => success;
  bool get hasErrors => errors != null && errors!.isNotEmpty;
}

/// Pagination response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta pagination;

  PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      items: (json['items'] as List?)
              ?.map((item) => fromJsonT(item))
              .toList() ??
          [],
      pagination: PaginationMeta.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// Pagination metadata
class PaginationMeta {
  final int currentPage;
  final int itemsPerPage;
  final int totalItems;
  final int totalPages;

  PaginationMeta({
    required this.currentPage,
    required this.itemsPerPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['currentPage'] ?? 1,
      itemsPerPage: json['itemsPerPage'] ?? 10,
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}
