import 'package:flutter/material.dart';

class PickupTipsCard extends StatelessWidget {
  const PickupTipsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4).withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFBC02D).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBC02D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tips_and_updates, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'نصائح وإرشادات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFD48100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipRow('يرجى وضع أكياس النفايات في الحاوية قبل موعد الرفع بنصف ساعة.'),
          _buildTipRow('تأكد من إغلاق أكياس النفايات جيداً لمنع تسرب الروائح أو النفايات.'),
          _buildTipRow('ساهم معنا في نظافة مدينتك عبر الالتزام بالمواعيد المحددة.'),
        ],
      ),
    );
  }

  Widget _buildTipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFFBC02D),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5D4037),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
