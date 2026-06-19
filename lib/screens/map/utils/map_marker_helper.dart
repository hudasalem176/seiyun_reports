import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerHelper {
  /// يرسم ماركرًا احترافيًا على شكل Pin مع ظل وأيقونة بداخله مع تدرج لوني
  static Future<BitmapDescriptor> buildPinMarker({
    required IconData icon,
    required Color color,
    required Color iconColor,
    double size = 120,
  }) async {
    final double totalHeight = size * 1.4;
    final double radius = size / 2;
    final double cx = radius;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);


    // ── رسم الـ Pin Path الاحترافي ────────────────
    final Path pinPath = Path();
    // نقطة البداية (الرأس العلوي)
    pinPath.moveTo(cx, 0);
    // القوس العلوي (الدائري)
    pinPath.addArc(Rect.fromLTWH(0, 0, size, size), -math.pi, math.pi);
    // رسم الجوانب التي تلتقي في الأسفل (شكل قطرة)
    pinPath.lineTo(cx, totalHeight - 10);
    pinPath.close();

    // تدرج لوني للماركر
    final Paint pinPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, 0),
            Offset(cx, totalHeight),
            [color, color.withValues(alpha: 0.85)],
          )
          ..style = PaintingStyle.fill;

    canvas.drawPath(pinPath, pinPaint);

    // إضافة حدود بيضاء خفيفة (Stroke) لزيادة الوضوح
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── الدائرة البيضاء الداخلية ──────────────────
    final double innerR = radius * 0.65;
    final Offset center = Offset(cx, radius);
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // ظل داخلي خفيف للدائرة البيضاء
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── رسم الأيقونة ────────────────────────────
    final TextPainter tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: innerR * 1.2,
          fontFamily: icon.fontFamily,
          color: iconColor,
          package: icon.fontPackage,
        ),
      ),
    )..layout();

    tp.paint(canvas, Offset(cx - tp.width / 2, radius - tp.height / 2));

    final ui.Image image = await recorder.endRecording().toImage(
      size.toInt(),
      totalHeight.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> buildCircleMarker({
    required IconData icon,
    required Color color,
    required Color iconColor,
    double size = 140,
  }) async {
    final double radius = size / 2;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // ظل
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(
      Offset(radius, radius + 3),
      radius * 0.85,
      shadowPaint,
    );

    // إطار أبيض
    canvas.drawCircle(
      Offset(radius, radius),
      radius * 0.9,
      Paint()..color = Colors.white,
    );

    // الدائرة الملونة
    canvas.drawCircle(
      Offset(radius, radius),
      radius * 0.78,
      Paint()..color = color,
    );

    // الأيقونة
    final TextPainter tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.55,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: iconColor,
        ),
      ),
    )..layout();

    tp.paint(
      canvas,
      Offset(
        radius - tp.width / 2,
        radius - tp.height / 2,
      ),
    );

    final ui.Image image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );

    final data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.fromBytes(
      data!.buffer.asUint8List(),
    );
  }

  /// الدالة القديمة — متوافقة مع الكود السابق
  static Future<BitmapDescriptor> getMarkerIconFromIcon(
    IconData iconData,
    Color color,
    double size,
  ) => buildCircleMarker(
    icon: iconData,
    color: color,
    iconColor: Colors.white,
    size: size,
  );
}
