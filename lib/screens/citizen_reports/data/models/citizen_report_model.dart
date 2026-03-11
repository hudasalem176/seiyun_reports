class CitizenReportModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String date;
  final String status; // 'جديد', 'قيد المعالجة', 'تم الإنجاز'
  final String imageUrl;
  final String category;
  final String authorName;
  final String authorImageUrl;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final bool isLiked;
  final String? adminReply;
  final double latitude;
  final double longitude;

  CitizenReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.status,
    required this.imageUrl,
    required this.category,
    required this.authorName,
    required this.authorImageUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.isLiked = false,
    this.adminReply,
    this.latitude = 15.9429,
    this.longitude = 48.7844,
  });

  CitizenReportModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? date,
    String? status,
    String? imageUrl,
    String? category,
    String? authorName,
    String? authorImageUrl,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    bool? isLiked,
    String? adminReply,
    double? latitude,
    double? longitude,
  }) {
    return CitizenReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      authorName: authorName ?? this.authorName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isLiked: isLiked ?? this.isLiked,
      adminReply: adminReply ?? this.adminReply,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
