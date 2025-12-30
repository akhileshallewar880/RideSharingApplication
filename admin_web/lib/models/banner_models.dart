import '../core/utils/datetime_parser.dart';

class Banner {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? actionUrl;
  final String actionType;
  final String? actionText;
  final int displayOrder;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String targetAudience;
  final int impressionCount;
  final int clickCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Banner({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.actionUrl,
    required this.actionType,
    this.actionText,
    required this.displayOrder,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.targetAudience,
    required this.impressionCount,
    required this.clickCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      actionType: json['actionType'] ?? 'none',
      actionText: json['actionText'],
      displayOrder: json['displayOrder'],
      startDate: DateTimeParser.parse(json['startDate']),
      endDate: DateTimeParser.parse(json['endDate']),
      isActive: json['isActive'],
      targetAudience: json['targetAudience'] ?? 'all',
      impressionCount: json['impressionCount'] ?? 0,
      clickCount: json['clickCount'] ?? 0,
      createdAt: DateTimeParser.parse(json['createdAt']),
      updatedAt: DateTimeParser.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionType': actionType,
      'actionText': actionText,
      'displayOrder': displayOrder,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'targetAudience': targetAudience,
      'impressionCount': impressionCount,
      'clickCount': clickCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double get clickThroughRate {
    if (impressionCount == 0) return 0.0;
    return (clickCount / impressionCount) * 100;
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && startDate.isBefore(now) && endDate.isAfter(now);
  }
}

class CreateBannerRequest {
  final String title;
  final String? description;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionType;
  final String? actionText;
  final int displayOrder;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? targetAudience;

  CreateBannerRequest({
    required this.title,
    this.description,
    this.imageUrl,
    this.actionUrl,
    this.actionType = 'none',
    this.actionText,
    this.displayOrder = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.targetAudience = 'all',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionType': actionType,
      'actionText': actionText,
      'displayOrder': displayOrder,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'targetAudience': targetAudience,
    };
  }
}

class UpdateBannerRequest {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionType;
  final String? actionText;
  final int? displayOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isActive;
  final String? targetAudience;

  UpdateBannerRequest({
    this.title,
    this.description,
    this.imageUrl,
    this.actionUrl,
    this.actionType,
    this.actionText,
    this.displayOrder,
    this.startDate,
    this.endDate,
    this.isActive,
    this.targetAudience,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (actionUrl != null) data['actionUrl'] = actionUrl;
    if (actionType != null) data['actionType'] = actionType;
    if (actionText != null) data['actionText'] = actionText;
    if (displayOrder != null) data['displayOrder'] = displayOrder;
    if (startDate != null) data['startDate'] = startDate!.toIso8601String();
    if (endDate != null) data['endDate'] = endDate!.toIso8601String();
    if (isActive != null) data['isActive'] = isActive;
    if (targetAudience != null) data['targetAudience'] = targetAudience;
    return data;
  }
}

class BannerListResponse {
  final bool success;
  final List<Banner> data;
  final BannerPagination pagination;

  BannerListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory BannerListResponse.fromJson(Map<String, dynamic> json) {
    return BannerListResponse(
      success: json['success'],
      data: (json['data'] as List).map((e) => Banner.fromJson(e)).toList(),
      pagination: BannerPagination.fromJson(json['pagination']),
    );
  }
}

class BannerPagination {
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  BannerPagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory BannerPagination.fromJson(Map<String, dynamic> json) {
    return BannerPagination(
      currentPage: json['currentPage'],
      pageSize: json['pageSize'],
      totalCount: json['totalCount'],
      totalPages: json['totalPages'],
    );
  }
}
