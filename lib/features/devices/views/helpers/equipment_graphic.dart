import 'package:flutter/material.dart';

/// Equipment categories for visual rendering
enum EquipmentVisualType {
  fixedCamera,
  ptzCamera,
  bulletCamera,
  nvrDvr,
  networkSwitch,
  router,
  fiberLink,
  upsPower,
  accessControl,
  ledTv,
  defaultHardware;

  static EquipmentVisualType detect(String name) {
    final n = name.toLowerCase();
    if (n.contains('ptz')) return EquipmentVisualType.ptzCamera;
    if (n.contains('anpr') ||
        n.contains('lpr') ||
        n.contains('thermal') ||
        n.contains('bullet')) {
      return EquipmentVisualType.bulletCamera;
    }
    if (n.contains('fixed') ||
        n.contains('dome') ||
        n.contains('cctv') ||
        n.contains('camera')) {
      return EquipmentVisualType.fixedCamera;
    }
    if (n.contains('nvr') ||
        n.contains('dvr') ||
        n.contains('recorder') ||
        n.contains('storage')) {
      return EquipmentVisualType.nvrDvr;
    }
    if (n.contains('switch') || n.contains('lan')) {
      return EquipmentVisualType.networkSwitch;
    }
    if (n.contains('router') || n.contains('gateway') || n.contains('wifi')) {
      return EquipmentVisualType.router;
    }
    if (n.contains('fiber') ||
        n.contains('optical') ||
        n.contains('link') ||
        n.contains('cable')) {
      return EquipmentVisualType.fiberLink;
    }
    if (n.contains('tv') ||
        n.contains('led') ||
        n.contains('display') ||
        n.contains('monitor') ||
        n.contains('screen')) {
      return EquipmentVisualType.ledTv;
    }
    if (n.contains('ups') || n.contains('power') || n.contains('battery')) {
      return EquipmentVisualType.upsPower;
    }
    if (n.contains('access') ||
        n.contains('door') ||
        n.contains('gate') ||
        n.contains('biometric') ||
        n.contains('entry')) {
      return EquipmentVisualType.accessControl;
    }
    return EquipmentVisualType.defaultHardware;
  }

  /// Whether this hardware represents a network link (e.g. Active/Down instead of Online/Offline)
  static bool isLink(String name) {
    final n = name.toLowerCase();
    return n.contains('fiber') ||
        n.contains('optical') ||
        n.contains('link') ||
        n.contains('cable');
  }
}

/// Renders a high-fidelity visual graphic for equipment, mirroring the web dashboard SVG illustrations.
/// If [imageUrl] is present, attempts to load the network image with fallback to the custom vector graphic.
class EquipmentGraphic extends StatelessWidget {
  final String hardwareTypeName;
  final String? imageUrl;
  final double size;

  const EquipmentGraphic({
    super.key,
    required this.hardwareTypeName,
    this.imageUrl,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final visualType = EquipmentVisualType.detect(hardwareTypeName);

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildVectorGraphic(visualType),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildVectorGraphic(visualType);
  }

  Widget _buildVectorGraphic(EquipmentVisualType type) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EquipmentCustomPainter(type),
        size: Size(size, size),
      ),
    );
  }
}

class _EquipmentCustomPainter extends CustomPainter {
  final EquipmentVisualType type;

  _EquipmentCustomPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64.0;
    canvas.save();
    canvas.scale(scale, scale);

    switch (type) {
      case EquipmentVisualType.fixedCamera:
        _drawFixedCamera(canvas);
        break;
      case EquipmentVisualType.ptzCamera:
        _drawPtzCamera(canvas);
        break;
      case EquipmentVisualType.bulletCamera:
        _drawBulletCamera(canvas);
        break;
      case EquipmentVisualType.nvrDvr:
        _drawNvrDvr(canvas);
        break;
      case EquipmentVisualType.networkSwitch:
        _drawNetworkSwitch(canvas);
        break;
      case EquipmentVisualType.router:
        _drawRouter(canvas);
        break;
      case EquipmentVisualType.fiberLink:
        _drawFiberLink(canvas);
        break;
      case EquipmentVisualType.upsPower:
        _drawUpsPower(canvas);
        break;
      case EquipmentVisualType.accessControl:
        _drawAccessControl(canvas);
        break;
      case EquipmentVisualType.ledTv:
        _drawLedTv(canvas);
        break;
      case EquipmentVisualType.defaultHardware:
        _drawDefaultHardware(canvas);
        break;
    }

    canvas.restore();
  }

  // 1. Fixed / Dome Camera
  void _drawFixedCamera(Canvas canvas) {
    // Base ring mount
    final basePaint1 = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(32, 46), width: 44, height: 14),
      basePaint1,
    );
    final basePaint2 = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(32, 44), width: 40, height: 12),
      basePaint2,
    );

    // Eyeball / sphere housing with gradient
    final sphereCenter = const Offset(32, 30);
    const sphereRadius = 18.0;
    const sphereGradient = RadialGradient(
      center: Alignment(-0.1, -0.35),
      radius: 0.9,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFE2E8F0),
        Color(0xFF94A3B8),
      ],
      stops: [0.0, 0.65, 1.0],
    );
    final spherePaint = Paint()
      ..shader = sphereGradient.createShader(
        Rect.fromCircle(center: sphereCenter, radius: sphereRadius),
      );
    canvas.drawCircle(sphereCenter, sphereRadius, spherePaint);

    final sphereBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(sphereCenter, sphereRadius, sphereBorder);

    // Front bezel ring
    final bezelPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(28, 32), width: 22, height: 22),
      bezelPaint,
    );
    final bezelStroke = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(28, 32), width: 22, height: 22),
      bezelStroke,
    );

    // Lens elements
    canvas.drawCircle(const Offset(28, 32), 7, Paint()..color = const Color(0xFF020617));
    canvas.drawCircle(const Offset(28, 32), 4.5, Paint()..color = const Color(0xFF1E3A8A));

    // Sapphire lens flare
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(26, 30), width: 4, height: 2.4),
      Paint()..color = const Color(0xE660A5FA),
    );
    canvas.drawCircle(
      const Offset(31, 34),
      0.8,
      Paint()..color = const Color(0xB393C5FD),
    );

    // Red status LED
    canvas.drawCircle(
      const Offset(20, 24),
      1.2,
      Paint()..color = const Color(0xD9EF4444),
    );
  }

  // 2. PTZ Camera
  void _drawPtzCamera(Canvas canvas) {
    // Ceiling mount plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(22, 6, 20, 4), const Radius.circular(2)),
      Paint()..color = const Color(0xFFCBD5E1),
    );
    canvas.drawRect(
      const Rect.fromLTWH(27, 10, 10, 5),
      Paint()..color = const Color(0xFF94A3B8),
    );

    // Upper casing
    final upperPath = Path()
      ..moveTo(21, 24)
      ..lineTo(21, 17)
      ..cubicTo(21, 15.5, 22.5, 14.5, 24, 14.5)
      ..lineTo(40, 14.5)
      ..cubicTo(41.5, 14.5, 43, 15.5, 43, 17)
      ..lineTo(43, 24)
      ..close();
    canvas.drawPath(upperPath, Paint()..color = const Color(0xFFF1F5F9));
    canvas.drawPath(
      upperPath,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Rotating sphere body
    final sphereCenter = const Offset(32, 36);
    const sphereRadius = 16.0;
    const ptzGrad = RadialGradient(
      center: Alignment(-0.25, -0.375),
      radius: 0.9,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFE2E8F0),
        Color(0xFF94A3B8),
      ],
      stops: [0.0, 0.7, 1.0],
    );
    canvas.drawCircle(
      sphereCenter,
      sphereRadius,
      Paint()..shader = ptzGrad.createShader(Rect.fromCircle(center: sphereCenter, radius: sphereRadius)),
    );
    canvas.drawCircle(
      sphereCenter,
      sphereRadius,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Dark optical lens circle
    canvas.drawCircle(
      const Offset(32, 38),
      9,
      Paint()..color = const Color(0xFF090D16),
    );
    canvas.drawCircle(
      const Offset(32, 38),
      9,
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(const Offset(32, 38), 5.5, Paint()..color = const Color(0xFF1E3A8A));
    canvas.drawCircle(const Offset(32, 38), 3.0, Paint()..color = const Color(0xFF020617));

    // Lens reflection
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(30.5, 36), width: 3, height: 1.8),
      Paint()..color = const Color(0xE693C5FD),
    );

    // IR dots
    canvas.drawCircle(const Offset(26, 32), 1.0, Paint()..color = const Color(0xBFEF4444));
    canvas.drawCircle(const Offset(38, 32), 1.0, Paint()..color = const Color(0xBFEF4444));
  }

  // 3. Bullet / ANPR Camera
  void _drawBulletCamera(Canvas canvas) {
    // Wall mount
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(52, 24, 4, 18), const Radius.circular(2)),
      Paint()..color = const Color(0xFF94A3B8),
    );
    canvas.drawRect(const Rect.fromLTWH(44, 33, 8, 4), Paint()..color = const Color(0xFFCBD5E1));
    canvas.drawCircle(const Offset(44, 35), 3, Paint()..color = const Color(0xFF64748B));

    // Bracket arm
    canvas.drawLine(
      const Offset(44, 35),
      const Offset(34, 30),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );

    // Sunshield visor
    final visorPath = Path()
      ..moveTo(6, 23)
      ..lineTo(38, 19)
      ..cubicTo(39.5, 18.8, 40.8, 19.8, 41, 21.2)
      ..lineTo(41.6, 26)
      ..lineTo(8, 28)
      ..close();
    canvas.drawPath(visorPath, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawPath(
      visorPath,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Cylindrical body
    const bodyRect = Rect.fromLTWH(9, 26, 30, 15);
    final bodyGrad = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
      stops: [0.0, 0.6, 1.0],
    ).createShader(bodyRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      Paint()..shader = bodyGrad,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Front lens glass
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(9, 33.5), width: 6, height: 15),
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(9, 33.5), width: 6, height: 15),
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(9, 33.5), width: 3, height: 8),
      Paint()..color = const Color(0xFF1E3A8A),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(8.5, 32), width: 1.6, height: 3),
      Paint()..color = const Color(0xE693C5FD),
    );
  }

  // 4. NVR / DVR
  void _drawNvrDvr(Canvas canvas) {
    const outerRect = Rect.fromLTWH(6, 22, 52, 22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    const innerRect = Rect.fromLTWH(8, 24, 48, 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF1E293B),
    );

    // Power dial / LED
    canvas.drawCircle(const Offset(16, 33), 4.5, Paint()..color = const Color(0xFF020617));
    canvas.drawCircle(
      const Offset(16, 33),
      4.5,
      Paint()
        ..color = const Color(0xFF475569)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawCircle(const Offset(16, 33), 2.5, Paint()..color = const Color(0xCC06B6D4));

    // Status LEDs
    canvas.drawCircle(const Offset(26, 33), 1.5, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(const Offset(31, 33), 1.5, Paint()..color = const Color(0xFF3B82F6));

    // Drive bays / vents
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(40, 30, 10, 3), const Radius.circular(0.5)),
      Paint()..color = const Color(0xFF020617),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(40, 35, 10, 1.5), const Radius.circular(0.5)),
      Paint()..color = const Color(0xFF475569),
    );
  }

  // 5. Network Switch
  void _drawNetworkSwitch(Canvas canvas) {
    const outerRect = Rect.fromLTWH(6, 20, 52, 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF312E81),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF4338CA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    const innerRect = Rect.fromLTWH(8, 22, 48, 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF1E1B4B),
    );

    final portPaint = Paint()..color = const Color(0xFF818CF8);
    const xs = [12.0, 18.0, 24.0, 30.0, 36.0, 42.0, 48.0];

    for (int i = 0; i < xs.length; i++) {
      final x = xs[i];
      // Row 1 ports
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 25, 4, 4), const Radius.circular(0.8)),
        portPaint,
      );
      canvas.drawCircle(
        Offset(x + 2, 24),
        0.8,
        Paint()..color = (i % 2 == 0) ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
      );

      // Row 2 ports
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 33, 4, 4), const Radius.circular(0.8)),
        portPaint,
      );
      canvas.drawCircle(
        Offset(x + 2, 38),
        0.8,
        Paint()..color = (i % 3 == 0) ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
      );
    }
  }

  // 6. Router
  void _drawRouter(Canvas canvas) {
    // Antennas
    final antennaPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(20, 32), const Offset(16, 14), antennaPaint);
    canvas.drawLine(const Offset(44, 32), const Offset(48, 14), antennaPaint);
    canvas.drawCircle(const Offset(16, 14), 1.5, Paint()..color = const Color(0xFF334155));
    canvas.drawCircle(const Offset(48, 14), 1.5, Paint()..color = const Color(0xFF334155));

    // Chassis body
    const bodyRect = Rect.fromLTWH(8, 30, 48, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // LED strip
    const stripRect = Rect.fromLTWH(12, 34, 40, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stripRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF1E293B),
    );

    // Green LEDs
    final greenLed = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(const Offset(18, 38), 1.2, greenLed);
    canvas.drawCircle(const Offset(23, 38), 1.2, greenLed);
    canvas.drawCircle(const Offset(28, 38), 1.2, greenLed);
    canvas.drawCircle(const Offset(33, 38), 1.2, greenLed);
    // Cyan and Blue LEDs
    canvas.drawCircle(const Offset(38, 38), 1.2, Paint()..color = const Color(0xFF06B6D4));
    canvas.drawCircle(const Offset(43, 38), 1.2, Paint()..color = const Color(0xFF3B82F6));
  }

  // 7. Fiber Link
  void _drawFiberLink(Canvas canvas) {
    // Connector sleeve on bottom left
    final sleevePath = Path()
      ..moveTo(12, 48)
      ..lineTo(21, 57)
      ..cubicTo(22.5, 58.5, 25, 58.5, 26.5, 57)
      ..lineTo(31, 52.5)
      ..lineTo(16.5, 38)
      ..lineTo(12, 42.5)
      ..cubicTo(10.5, 44, 10.5, 46.5, 12, 48)
      ..close();
    canvas.drawPath(sleevePath, Paint()..color = const Color(0xFF1E293B));
    canvas.drawPath(
      sleevePath,
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawLine(
      const Offset(19, 41),
      const Offset(29, 51),
      Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Glowing fiber strands
    final strandPaint1 = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final strandPaint2 = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final strandPaint3 = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final p1 = Path()..moveTo(26, 40)..cubicTo(32, 38, 41, 27, 45, 15);
    final p2 = Path()..moveTo(25, 38)..cubicTo(32, 33, 38, 22, 40, 11);
    final p3 = Path()..moveTo(24, 36)..cubicTo(28, 29, 32, 17, 33, 9);
    final p4 = Path()..moveTo(28, 42)..cubicTo(37, 42, 46, 34, 52, 21);
    final p5 = Path()..moveTo(30, 44)..cubicTo(41, 45, 49, 39, 55, 29);

    canvas.drawPath(p1, strandPaint1);
    canvas.drawPath(p2, strandPaint2);
    canvas.drawPath(p3, strandPaint3);
    canvas.drawPath(p4, strandPaint1);
    canvas.drawPath(p5, strandPaint3);

    // Glowing tips
    const tips = [
      Offset(45, 15),
      Offset(40, 11),
      Offset(33, 9),
      Offset(52, 21),
      Offset(55, 29),
    ];
    for (final tip in tips) {
      canvas.drawCircle(tip, 2.2, Paint()..color = const Color(0xFF7DD3FC));
      canvas.drawCircle(tip, 1.2, Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  // 8. UPS / Power
  void _drawUpsPower(Canvas canvas) {
    // Red battery pack body
    const bodyRect = Rect.fromLTWH(18, 14, 28, 38);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFFDC2626),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFEF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Beveled display window
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(22, 18, 20, 14), const Radius.circular(2)),
      Paint()..color = const Color(0xFF991B1B),
    );

    // Yellow lightning bolt
    final bolt = Path()
      ..moveTo(33, 21)
      ..lineTo(29, 26)
      ..lineTo(33, 26)
      ..lineTo(31, 31)
      ..lineTo(37, 25)
      ..lineTo(33, 25)
      ..close();
    canvas.drawPath(bolt, Paint()..color = const Color(0xFFFEF08A));

    // Bottom status vents
    final ventPaint = Paint()
      ..color = const Color(0xFF7F1D1D)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(23, 38), const Offset(41, 38), ventPaint);
    canvas.drawLine(const Offset(23, 42), const Offset(41, 42), ventPaint);

    // Status LED
    canvas.drawCircle(const Offset(32, 47), 1.5, Paint()..color = const Color(0xFF22C55E));
  }

  // 9. Access Control
  void _drawAccessControl(Canvas canvas) {
    // Outer door frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(14, 10, 36, 46), const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFFF8FAFC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Open door swinging inward
    final doorPath = Path()
      ..moveTo(28, 12)
      ..lineTo(46, 16)
      ..lineTo(46, 50)
      ..lineTo(28, 54)
      ..close();
    canvas.drawPath(doorPath, Paint()..color = const Color(0xE6F8FAFC));

    // Door lock / handle
    canvas.drawCircle(const Offset(32, 34), 1.5, Paint()..color = const Color(0xFF0F172A));

    // Floor threshold
    canvas.drawLine(
      const Offset(10, 56),
      const Offset(54, 56),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  // 10. LED TV
  void _drawLedTv(Canvas canvas) {
    // Screen frame
    const frameRect = Rect.fromLTWH(8, 14, 48, 32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner screen
    const screenRect = Rect.fromLTWH(11, 17, 42, 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(screenRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF0F172A),
    );

    // Radar / screen glow
    canvas.drawCircle(const Offset(32, 30), 7, Paint()..color = const Color(0x4D0284C7));
    canvas.drawCircle(
      const Offset(32, 30),
      5,
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(const Offset(32, 30), 2, Paint()..color = const Color(0xFF38BDF8));

    // Stand & base
    canvas.drawRect(const Rect.fromLTWH(28, 46, 8, 4), Paint()..color = const Color(0xFF64748B));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(22, 50, 20, 3), const Radius.circular(1.5)),
      Paint()..color = const Color(0xFF475569),
    );
  }

  // 11. Default Hardware
  void _drawDefaultHardware(Canvas canvas) {
    const chipRect = Rect.fromLTWH(12, 14, 40, 36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chipRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chipRect, const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFF3B82F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(const Offset(32, 30), 8, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(
      const Offset(32, 30),
      8,
      Paint()
        ..color = const Color(0xFF60A5FA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(const Offset(32, 30), 3, Paint()..color = const Color(0xFF60A5FA));

    canvas.drawCircle(const Offset(22, 42), 1.5, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(const Offset(28, 42), 1.5, Paint()..color = const Color(0xFF3B82F6));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(36, 41, 8, 2), const Radius.circular(1)),
      Paint()..color = const Color(0xFF64748B),
    );
  }

  @override
  bool shouldRepaint(covariant _EquipmentCustomPainter oldDelegate) => oldDelegate.type != type;
}
