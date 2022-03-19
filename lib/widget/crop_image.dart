import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CropImage extends StatelessWidget {
  CropImage({
    Key? key,
    required this.image,
    int? width,
    int? height,
    int srcX = 0,
    int srcY = 0,
    int? srcWidth,
    int? srcHeight,
  })  : assert((srcWidth ?? 0) >= 0),
        assert((srcHeight ?? 0) >= 0),
        src = ui.Rect.fromLTWH(
          srcX.toDouble(),
          srcY.toDouble(),
          (srcWidth ?? image.width).toDouble(),
          (srcHeight ?? image.height).toDouble(),
        ),
        dst = ui.Rect.fromLTWH(
          0,
          0,
          (width ?? image.width).toDouble(),
          (height ?? image.height).toDouble(),
        ),
        super(key: key);
  final ui.Image image;
  final Rect src;
  final Rect dst;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: Size(dst.width, dst.height),
        painter: _CropImagePainter(
          image: image,
          src: src,
          dst: dst,
        ),
      ),
    );
  }
}

class _CropImagePainter extends CustomPainter {
  final Paint mainPaint = Paint()..isAntiAlias = true;
  final ui.Image image;
  final Rect src;
  final Rect dst;
  _CropImagePainter({
    required this.image,
    required this.src,
    required this.dst,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      src,
      dst,
      mainPaint,
    );
    // final span = TextSpan(text: 'Yrfc');
    // TextPainter tp = TextPainter(
    //     text: span,
    //     textAlign: TextAlign.left,
    //     textDirection: TextDirection.ltr);
    // tp.layout();
    // tp.paint(canvas, Offset(5.0, 5.0));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
