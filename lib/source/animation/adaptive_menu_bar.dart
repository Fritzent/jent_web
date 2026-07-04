import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jent_web/gen/assets.gen.dart';

class AdaptiveMenuBar extends StatefulWidget {
  final ImageProvider backgroundImage;

  const AdaptiveMenuBar({
    super.key,
    required this.backgroundImage,
  });

  @override
  State<AdaptiveMenuBar> createState() => _AdaptiveMenuBarState();
}

class _AdaptiveMenuBarState extends State<AdaptiveMenuBar> {
  Color _adaptiveColor = const Color(0xAA3B4948);
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  @override
  void didUpdateWidget(covariant AdaptiveMenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backgroundImage != widget.backgroundImage) {
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    final stream = widget.backgroundImage.resolve(
      const ImageConfiguration(),
    );

    late ImageStreamListener listener;

    listener = ImageStreamListener((info, _) async {
      final image = info.image;

      final byteData = await image.toByteData(
        format: ImageByteFormat.rawRgba,
      );

      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      int r = 0, g = 0, b = 0, count = 0;

      final width = image.width;
      const sampleHeight = 50;

      for (int y = 0; y < sampleHeight; y += 5) {
        for (int x = 0; x < width; x += 10) {
          final index = (y * width + x) * 4;

          r += bytes[index];
          g += bytes[index + 1];
          b += bytes[index + 2];
          count++;
        }
      }

      final avg = Color.fromARGB(
        255,
        r ~/ count,
        g ~/ count,
        b ~/ count,
      );

      final brightness = avg.computeLuminance();

      if (mounted) {
        setState(() {
          _isDark = brightness < 0.5;

          _adaptiveColor = Color.alphaBlend(
            Colors.black.withAlpha(38),
            avg.withAlpha(165),
          );
        });
      }

      stream.removeListener(listener);
    });

    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isDark
        ? Colors.white
        : Colors.black87;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),
        child: Container(
          alignment: Alignment.center,
          height: 38,
          decoration: BoxDecoration(
            color: _adaptiveColor.withAlpha(198),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 20),
              Assets.icJustLogo.image(
                color: textColor,
              ),
              const SizedBox(width: 20),
              Text(
                'Pritjent',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 24),
              Text('File', style: TextStyle(color: textColor)),
              const SizedBox(width: 24),
              Text('Edit', style: TextStyle(color: textColor)),
              const SizedBox(width: 24),
              Text('View', style: TextStyle(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}