import 'package:flutter/material.dart';
import '../data/models/citizen_report_model.dart';

class CitizenReportsViewModel extends ChangeNotifier {
  List<CitizenReportModel> _reports = [];
  List<CitizenReportModel> get reports => _reports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  CitizenReportsViewModel() {
    _fetchReports();
  }

  void _fetchReports() {
    _isLoading = true;
    notifyListeners();

    // Mock data for now
    _reports = [
      CitizenReportModel(
        id: '1',
        title: 'تراكم القمامة في شارع الجزائر',
        description: 'الحاوية في نهاية الشارع ممتلئة بشكل كامل منذ 3 أيام والنفايات بدأت تتراكم حولها',
        location: 'شارع الجزائر بجانب سوق النساء',
        date: '2025-11-26 09:30',
        status: 'تم الإنجاز',
        imageUrl: 'https://images.unsplash.com/photo-1530587191325-3db32d826c18?q=80&w=1000&auto=format&fit=crop',
        category: 'البيئة',
        authorName: 'خلود عصام',
        authorImageUrl: 'https://i.pravatar.cc/150?u=1',
        likesCount: 245,
        commentsCount: 9,
        sharesCount: 34,
        viewsCount: 1200,
        isLiked: true,
        adminReply: 'تم توجيه فريق النظافة للموقع وسيتم الانتهاء من التنظيف قبل نهاية اليوم.',
        latitude: 15.9430,
        longitude: 48.7845,
      ),
      CitizenReportModel(
        id: '2',
        title: 'عطل في إنارة الشارع العام',
        description: 'توجد أكثر من 5 أعمدة إنارة لا تعمل في المربع الخامس مما يسبب ظلام دامس في المساء',
        location: 'حي القرن - المربع الخامس',
        date: '2025-11-25 18:45',
        status: 'قيد المعالجة',
        imageUrl: 'https://images.unsplash.com/photo-1517487881594-2787fef5ebf7?q=80&w=1000&auto=format&fit=crop',
        category: 'الكهرباء',
        authorName: 'عبدالله صالح',
        authorImageUrl: 'https://i.pravatar.cc/150?u=2',
        likesCount: 120,
        commentsCount: 5,
        sharesCount: 12,
        viewsCount: 540,
        isLiked: false,
        latitude: 15.9450,
        longitude: 48.7880,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void toggleLike(String reportId) {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      _reports[index] = report.copyWith(
        isLiked: !report.isLiked,
        likesCount: report.isLiked ? report.likesCount - 1 : report.likesCount + 1,
      );
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<CitizenReportModel> get filteredReports {
    if (_searchQuery.isEmpty) return _reports;
    return _reports.where((r) => 
      r.title.contains(_searchQuery) || 
      r.description.contains(_searchQuery) ||
      r.location.contains(_searchQuery)
    ).toList();
  }

  int get totalReports => _reports.length;
  int get resolvedReports => _reports.where((r) => r.status == 'تم الإنجاز').length;
  int get activeReports => _reports.where((r) => r.status != 'تم الإنجاز').length;
  
  double get resolutionRate {
    if (_reports.isEmpty) return 0.0;
    return (resolvedReports / totalReports) * 100;
  }
}
