import 'package:flutter/material.dart';

// تعريف الألوان الأساسية
const primaryGreen = Color(0xFF2E7D32);
const accentGreen = Color(0xFF81C784);
const primaryBrown = Color(0xFF5D4037);

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // عرض الصفحات
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: const [
              OnboardingContent(
                icon: Icons.eco_rounded,
                title: 'مرحباً بك في عالم الاستدامة!',
                description: 'رحلتك نحو غدٍ أفضل تبدأ من هنا. لنعمل معاً من أجل كوكبنا.',
                iconColor: accentGreen,
              ),
              OnboardingContent(
                icon: Icons.public_rounded,
                title: 'حافظ على بيئتنا',
                description: 'كل عمل صغير يحدث فرقاً كبيراً. اجعل بصمتك خضراء دائماً.',
                iconColor: primaryGreen,
              ),
              OnboardingContent(
                icon: Icons.recycling_rounded,
                title: 'شارك في التغيير',
                description: 'انضم إلى مجتمعنا وكن جزءاً من الحل لا المشكلة.',
                iconColor: primaryBrown,
              ),
            ],
          ),

          // مؤشر الصفحات المخصص (بديل للمكتبة المعطلة)
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => buildDot(index)),
            ),
          ),

          // الأزرار السفلية
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _pageController.jumpToPage(2);
                  },
                  child: Text(
                    _currentPage == 2 ? "" : "تخطي",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == 2) {
                      // الانتقال لصفحة التسجيل (SignupScreen)
                      print("الانتقال لصفحة التسجيل");
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _currentPage == 2 ? "لنبدأ" : "التالي",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء النقطة الخاصة بالمؤشر
  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 10,
      width: _currentPage == index ? 25 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index ? primaryGreen : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  const OnboardingContent({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: iconColor),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}