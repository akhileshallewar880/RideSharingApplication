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
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'],
      targetAudience: json['targetAudience'] ?? 'all',
      impressionCount: json['impressionCount'] ?? 0,
      clickCount: json['clickCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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

  bool get hasAction => actionType != 'none' && actionUrl != null;
}

class BannerListResponse {
  final bool success;
  final List<Banner> data;
  final int count;

  BannerListResponse({
    required this.success,
    required this.data,
    required this.count,
  });

  factory BannerListResponse.fromJson(Map<String, dynamic> json) {
    return BannerListResponse(
      success: json['success'],
      data: (json['data'] as List).map((e) => Banner.fromJson(e)).toList(),
      count: json['count'] ?? 0,
    );
  }
}
