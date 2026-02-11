import 'package:flutter/material.dart';
import 'package:seiyun_reports_app/screens/Report.dart';

// نموذج بيانات البلاغ ليتوافق مع ما سيصل من Laravel
class ReportModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String date;
  final String status; // 'جديد', 'قيد المعالجة', 'تم الإنجاز'
  final String imageUrl;
  final String category;

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.status,
    required this.imageUrl,
    required this.category,
  });
}

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  // هذه القائمة ستُعبأ من الـ API
  // إذا كانت فارغة []، ستظهر واجهة "لا يوجد بلاغات"
  List<ReportModel> reportsList = [
    ReportModel(
      id: "1",
      title: "تراكم القمامة في شارع الجزائر",
      description: "كمية كبيرة من القمامة تحجب المشي على الأرصفة وتسبب روائح كريهة.",
      location: "شارع الجزائر، بجانب سوق النساء",
      date: "2025-12-01",
      status: "قيد المعالجة",
      imageUrl: "https://images.unsplash.com/photo-1530587191325-3db32d826c18?q=80&w=500",
      category: "تراكم نفايات",
    ),
    ReportModel(
      id: "2",
      title: "رمي عشوائي في الحديقة",
      description: "مخلفات بناء مرمية في وسط الحديقة العامة.",
      location: "حديقة سيئون، البوابة الشمالية",
      date: "2025-12-01",
      status: "جديد",
      imageUrl: "https://images.unsplash.com/photo-1611284446314-60a58ac0deb9?q=80&w=500",
      category: "تراكم نفايات",
    ),
  ];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // _fetchReportsFromLaravel();
  }

  // دالة وهمية لمحاكاة جلب البيانات
  Future<void> _fetchReportsFromLaravel() async {
    setState(() => isLoading = true);
    // محاكاة تأخير الشبكة
    await Future.delayed(const Duration(seconds: 2));
    // هنا يتم جلب البيانات وتحديث reportsList
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ecc71)))
                  : reportsList.isEmpty
                  ? _buildEmptyState()
                  : _buildReportsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> const ReportScreen()));
        },
        backgroundColor: const Color(0xFF2ecc71),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2ecc71), Color(0xFF1b5e20)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "بلاغاتي",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "ابحث عن بلاغ...",
                hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white70),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.description_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          const Text(
            "لا توجد بلاغات حالياً",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          const Text(
            "لم تقم بإرسال أي بلاغ بعد.\nيمكنك البدء بالمساهمة في نظافة مدينتك الآن.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text("إرسال بلاغ جديد"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ecc71),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reportsList.length,
      itemBuilder: (context, index) {
        return _buildReportCard(reportsList[index]);
      },
    );
  }

  Widget _buildReportCard(ReportModel report) {
    Color statusColor;
    switch (report.status) {
      case 'قيد المعالجة':
        statusColor = Colors.orange;
        break;
      case 'تم الإنجاز':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  report.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.eco, color: Colors.green[400], size: 14),
                        const SizedBox(width: 5),
                        Text(report.category,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 25),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          report.location,
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(report.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              report.status,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}