import 'package:flutter/material.dart';
import 'package:seiyun_reports_app/screens/Report.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(),
                    const SizedBox(height: 20),
                    _buildNextPickupCard(),
                    const SizedBox(height: 20),
                    _buildOrderServiceBanner(),
                    const SizedBox(height: 25),
                    _buildSectionHeader("البلاغات الأخيرة", "عرض الكل"),
                    const SizedBox(height: 15),
                    _buildRecentReportsList(),
                    const SizedBox(height: 25),
                    _buildSectionHeader("الأخبار والتحديثات", "عرض الكل"),
                    const SizedBox(height: 15),
                    _buildNewsList(),
                    const SizedBox(height: 25),
                    const Text("نصائح مفيدة", style: sectionTitleStyle),
                    const SizedBox(height: 15),
                    _buildTipsGrid(),
                    const SizedBox(height: 100), // مساحة للزر العائم
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
         // Navigator.pushNamed(context, '/report');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportScreen()),
          );
        },
        backgroundColor: const Color(0xFF27ae60),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // الجزء العلوي: الترحيب والبحث
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2ecc71), Color(0xFF1b5e20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("أهلاً، محمد", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 5),
                      const Text("👋", style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const Text("حي القرن، سيئون", style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              Stack(
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white, size: 30),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: "ابحث في الخدمات...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white70),
              ),
            ),
          )
        ],
      ),
    );
  }

  // بطاقات الإحصائيات (البلاغات النشطة والمكتملة)
  Widget _buildStatsCards() {
    return Row(
      children: [
        _statCard("14", "بلاغات نشطة", const Color(0xFFfee2e2), const Color(0xFF991b1b)),
        const SizedBox(width: 15),
        _statCard("64", "بلاغ تم إنجازه", const Color(0xFFe0f2fe), const Color(0xFF075985)),
      ],
    );
  }

  Widget _statCard(String val, String label, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          border: const Border(bottom: BorderSide(color: Color(0xFFd4af37), width: 3)),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // بطاقة موعد الرفع القادم
  Widget _buildNextPickupCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("موعد الرفع القادم", style: TextStyle(fontSize: 13, color: Colors.grey)),
                SizedBox(height: 5),
                Text("الأحد: 6:00 - 8:00 صباحاً", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
            child: const Text("غداً", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          const Icon(Icons.timer_outlined, color: Color(0xFF27ae60), size: 35),
        ],
      ),
    );
  }

  // بانر طلب الخدمات
  Widget _buildOrderServiceBanner() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF27ae60), Color(0xFF2c3e50)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("اطلب الآن", style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text("الخدمات التي تحتاجها", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.print_outlined, color: Colors.white, size: 30),
        ],
      ),
    );
  }

  // هيدر الأقسام (عرض الكل)
  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: sectionTitleStyle),
        Text(action, style: const TextStyle(color: Color(0xFF27ae60), fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // قائمة البلاغات الأخيرة
  Widget _buildRecentReportsList() {
    final reports = [
      {"title": "تسرب مياه في شارع الجزائر", "date": "2023-11-25", "status": "قيد المعالجة"},
      {"title": "إنارة عامة متعطلة", "date": "2023-11-24", "status": "جديد"},
      {"title": "حاوية ممتلئة - حي الوحدة", "date": "2023-11-23", "status": "قيد المعالجة"},
    ];
    return Column(
      children: reports.map((r) => _reportItem(r)).toList(),
    );
  }

  Widget _reportItem(Map<String, String> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: const Text("عرض", style: TextStyle(fontSize: 11, color: Colors.brown)),
              )
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.blue),
                  const SizedBox(width: 5),
                  Text(data['status']!, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                ],
              ),
              Text(data['date']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  // قائمة الأخبار
  Widget _buildNewsList() {
    return Column(
      children: [
        _newsItem("توسعة خدمات النظافة في الأحياء الجديدة", "2023-11-25", Icons.cleaning_services),
        _newsItem("تحديث مواعيد جمع النفايات", "2023-11-24", Icons.event_available),
      ],
    );
  }

  Widget _newsItem(String title, String date, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.brown, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // شبكة النصائح
  Widget _buildTipsGrid() {
    return Row(
      children: [
        _tipCard("كيف تقدم بلاغاً فعالاً؟", Icons.lightbulb_outline),
        const SizedBox(width: 15),
        _tipCard("أوقات الاستجابة المتوقعة", Icons.access_time),
      ],
    );
  }

  Widget _tipCard(String title, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Icon(icon, color: Colors.orange, size: 28),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // شريط التنقل السفلي
  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, "الرئيسية", true),
            _navItem(Icons.map_outlined, "الخريطة", false),
            const SizedBox(width: 40), // مساحة للزر العائم
            _navItem(Icons.assignment_outlined, "بلاغاتي", false),
            _navItem(Icons.person_outline, "الملف الشخصي", false),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? const Color(0xFF27ae60) : Colors.grey, size: 24),
        Text(label, style: TextStyle(color: isActive ? const Color(0xFF27ae60) : Colors.grey, fontSize: 10)),
      ],
    );
  }
}

const sectionTitleStyle = TextStyle(fontSize: 16, color: Color(0xFF0f172a), fontWeight: FontWeight.bold);