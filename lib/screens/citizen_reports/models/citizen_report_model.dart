class CitizenReportModel {
  final int id;
  final String title;
  final String description;
  final String status;
  final int viewsCount;
  final int commentsCount;
  final int likesCount;
  final bool isLiked;
  final String reportImage;
  final String? imageAfterProcessing;
  final String createdAt;
  final String userName;
  final String userProfile;

  CitizenReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.viewsCount,
    required this.commentsCount,
    this.likesCount = 0,
    this.isLiked = false,
    required this.reportImage,
    this.imageAfterProcessing,
    required this.createdAt,
    required this.userName,
    required this.userProfile,
  });

  factory CitizenReportModel.fromJson(Map<String, dynamic> json) {
    return CitizenReportModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      status: json['status'] ?? "",
      viewsCount:
          json['views'] != null
              ? int.tryParse(json['views'].toString()) ?? 0
              : 0,
      commentsCount:
          json['comments'] != null
              ? int.tryParse(json['comments'].toString()) ?? 0
              : 0,
      likesCount:
          json['likes'] != null
              ? int.tryParse(json['likes'].toString()) ?? 0
              : 0,
      isLiked: json['is_liked'] ?? false,
      reportImage: json['report_image'] ?? "",
      imageAfterProcessing: json['Image_after_processing'],
      createdAt: json['created_at'] ?? "",
      userName: json['user_name'] ?? "مواطن",
      userProfile: json['user_profile'] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'viewsCount': viewsCount,
      'commentsCount': commentsCount,
      'likesCount': likesCount,
      'isLiked': isLiked ? 1 : 0,
      'report_image': reportImage,
      'imageAfterProcessing': imageAfterProcessing,
      'created_at': createdAt,
      'user_name': userName,
      'user_profile': userProfile,
    };
  }

  factory CitizenReportModel.fromMap(Map<String, dynamic> map) {
    return CitizenReportModel(
      id: map['id'] ?? 0,
      title: map['title'] ?? "",
      description: map['description'] ?? "",
      status: map['status'] ?? "",
      viewsCount:
          map['viewsCount'] != null
              ? int.tryParse(map['viewsCount'].toString()) ?? 0
              : 0,
      commentsCount:
          map['commentsCount'] != null
              ? int.tryParse(map['commentsCount'].toString()) ?? 0
              : 0,
      likesCount:
          map['likesCount'] != null
              ? int.tryParse(map['likesCount'].toString()) ?? 0
              : 0,
      isLiked: map['isLiked'] == 1 || map['isLiked'] == true,
      reportImage: map['report_image'] ?? "",
      imageAfterProcessing: map['imageAfterProcessing'],
      createdAt: map['created_at'] ?? "",
      userName: map['user_name'] ?? "مواطن",
      userProfile: map['user_profile'] ?? "",
    );
  }

  CitizenReportModel copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    int? viewsCount,
    int? commentsCount,
    int? likesCount,
    bool? isLiked,
    String? reportImage,
    String? imageAfterProcessing,
    String? createdAt,
    String? userName,
    String? userProfile,
  }) {
    return CitizenReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      viewsCount: viewsCount ?? this.viewsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      reportImage: reportImage ?? this.reportImage,
      imageAfterProcessing: imageAfterProcessing ?? this.imageAfterProcessing,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}
