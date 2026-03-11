import 'package:flutter/material.dart';

class MapMarkerItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MapMarkerItem({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Icon(icon, color: color, size: 30),
        ],
      ),
    );
  }
}
