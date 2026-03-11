import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seiyun_reports_app/screens/report/viewmodel/report_viewmodel.dart';
import 'package:seiyun_reports_app/core/theme/app_theme.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'نفايات',
      'label': 'نفايات',
      'icon': Icons.delete_outline,
      'color': Color(0xFF27ae60),
      'bg': Color(0xFFe8f5e9),
    },
    {
      'id': 'بناء',
      'label': 'بناء وصيانة',
      'icon': Icons.construction,
      'color': Color(0xFFe67e22),
      'bg': Color(0xFFfff3e0),
    },
    {
      'id': 'إنارة',
      'label': 'إنارة',
      'icon': Icons.lightbulb_outline,
      'color': Color(0xFFf1c40f),
      'bg': Color(0xFFfef9e7),
    },
    {
      'id': 'مياه',
      'label': 'مياه',
      'icon': Icons.opacity,
      'color': Color(0xFF3498db),
      'bg': Color(0xFFebf5fb),
    },
    {
      'id': 'حدائق',
      'label': 'حدائق',
      'icon': Icons.park_outlined,
      'color': Color(0xFF1abc9c),
      'bg': Color(0xFFeafff5),
    },
    {
      'id': 'أخرى',
      'label': 'أخرى',
      'icon': Icons.help_outline,
      'color': Color(0xFF95a5a6),
      'bg': Color(0xFFf4f6f7),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final reportVM = context.watch<ReportViewModel>();

    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: categories.map((cat) {
        bool isSelected = reportVM.selectedCategory == cat['id'];
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 50 - 30) / 3, // الحساب لضمان عرض 3 عناصر في الصف
          child: GestureDetector(
            onTap: () => reportVM.setCategory(cat['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppTheme.accentGreen : Theme.of(context).dividerColor.withOpacity(0.1),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: (cat['bg'] as Color).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: cat['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    cat['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleSmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
