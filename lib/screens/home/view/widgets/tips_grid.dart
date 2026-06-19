import 'package:flutter/material.dart';
import 'package:seiyun_reports_app/screens/news_tips/view/news_tips_screen.dart';

class TipsGrid extends StatelessWidget {
  const TipsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tipCard("كيف تقدم بلاغاً فعالاً؟", Icons.lightbulb_outline, context),
        const SizedBox(width: 15),
        _tipCard("أوقات الاستجابة المتوقعة", Icons.access_time, context),
      ],
    );
  }

  Widget _tipCard(String title, IconData icon, BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewsTipsScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.orange, size: 28),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
