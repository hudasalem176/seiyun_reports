import 'package:flutter/material.dart';

// نماذج البيانات لتمثيل ما سيصل من Laravel
class NewsModel {
  final String tag;
  final String title;
  final String desc;
  final String time;
  final String date;
  NewsModel({required this.tag, required this.title, required this.desc, required this.time, required this.date});
}

class TipModel {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  TipModel({required this.title, required this.desc, required this.icon, required this.color});
}

class NewsTipsPage extends StatefulWidget {
  const NewsTipsPage({super.key});

  @override
  State<NewsTipsPage> createState() => _NewsTipsPageState();
}

class _NewsTipsPageState extends State<NewsTipsPage> {
  bool isNewsSelected = true;

  // هذه القوائم ستكون فارغة في البداية وتُعبأ بعد جلب البيانات من الـ API
  List<NewsModel> newsList = [
    NewsModel(
      tag: "مبادرات",
      title: "إطلاق برنامج 'المدينة الخضراء 2025'",
      desc: "البلدية تعلن عن مبادرة جديدة لزيادة المساحات الخضراء وتحسين جودة الهواء.",
      time: "3 دقائق",
      date: "2025/11/28",
    ),
    NewsModel(
      tag: "إنجازات",
      title: "نجاح تجربة الفصل من المصدر في 5 أحياء",
      desc: "ارتفاع نسبة إعادة التدوير بنسبة 40% في الأحياء التجريبية.",
      time: "5 دقائق",
      date: "2025/11/26",
    ),
  ];

  List<TipModel> tipsList = [
    TipModel(
      title: "كيفية فصل النفايات بشكل صحيح",
      desc: "افصل البلاستيك والورق والمعادن عن النفايات العضوية لتسهيل إعادة التدوير.",
      icon: Icons.recycling,
      color: Colors.green,
    ),
    TipModel(
      title: "استخدام الأكياس القابلة لإعادة الاستخدام",
      desc: "استبدل الأكياس البلاستيكية بأكياس قماشية قابلة للاستخدام المتكرر.",
      icon: Icons.shopping_bag_outlined,
      color: Colors.teal,
    ),
    TipModel(
      title: "تقليل استهلاك المياه",
      desc: "استخدم المياه الرمادية لري النباتات وتنظيف الممرات الخارجية.",
      icon: Icons.water_drop_outlined,
      color: Colors.blue,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // هنا يتم استدعاء دالة جلب البيانات من Laravel مستقبلاً
    // _fetchDataFromLaravel();
  }

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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEnvironmentalStats(),
                    const SizedBox(height: 25),
                    if (isNewsSelected) ...[
                      _buildSectionHeader("أهم الأخبار"),
                      ...newsList.map((news) => _buildNewsCard(news)).toList(),
                    ] else ...[
                      _buildSectionHeader("نصائح بيئية"),
                      ...tipsList.map((tip) => _buildTipItem(tip)).toList(),
                    ],
                    const SizedBox(height: 25),
                    _buildCallToActionCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

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
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text("الأخبار والنصائح",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _toggleBtn("الأخبار", isNewsSelected, () => setState(() => isNewsSelected = true)),
                _toggleBtn("النصائح", !isNewsSelected, () => setState(() => isNewsSelected = false)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? const Color(0xFF1b5e20) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnvironmentalStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("إنجازاتنا البيئية", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(
          children: [
            _statBox("12,500", "أطنان تم تدويرها", Icons.rebase_edit, Colors.green),
            const SizedBox(width: 10),
            _statBox("3,200", "أشجار تم زراعتها", Icons.park_outlined, Colors.teal),
            const SizedBox(width: 10),
            _statBox("850K", "لتر ماء تم توفيره", Icons.opacity, Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _statBox(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsModel news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Icon(Icons.image_outlined, size: 50, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(news.tag, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Text(news.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(news.desc, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(news.time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 15),
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(news.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined, size: 20)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border, size: 20)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("اقرأ المزيد", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTipItem(TipModel tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tip.color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: tip.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(tip.icon, color: tip.color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(tip.desc, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCallToActionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF27ae60), Color(0xFF14532d)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco_outlined, color: Colors.white, size: 40),
          const SizedBox(height: 15),
          const Text("كن جزءاً من التغيير", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "ساهم في تحسين البيئة وابدأ بتطبيق هذه النصائح اليوم في منزلك.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("ابدأ الآن", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}