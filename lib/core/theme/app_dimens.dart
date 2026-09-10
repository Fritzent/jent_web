import 'package:flutter/material.dart';

class AppDimens {
  // Mail window sizing (fraction of screen, clamped).
  static const double mailWidthFactor = 0.85;
  static const double mailHeightFactor = 0.78;
  static const double mailWidthMin = 360.0;
  static const double mailWidthMax = 920.0;
  static const double mailHeightMin = 420.0;
  static const double mailHeightMax = 640.0;
  static const double mailExpandedWidthMin = 500.0;
  static const double mailExpandedWidthMax = 1200.0;
  static const double mailExpandedHeightMin = 800.0;
  static const double mailExpandedHeightMax = 1200.0;

  // Drag bounds for the floating mail window.
  static const double dragEdgeGrip = 80.0;
  static const double dragMinY = 38.0;
  static const double dragBottomMargin = 44.0;

  // Window chrome.
  static const double titleBarHeight = 44.0;
  static const double trafficLightSize = 13.0;
  static const double trafficLightGlyphSize = 9.0;

  // Radii.
  static const double dockRadius = 28.0;
  static const double tooltipRadius = 14.0;
  static const double windowRadius = 12.0;
  static const double buttonRadius = 8.0;
  static const double dockIconRadius = 14.0;

  // Font sizes.
  static const double bodyFontSize = 15.0;
  static const double tooltipFontSize = 12.0;
  static const double welcomeFontSize = 32.0;
  static const double helloFontSize = 96.0;
  static const double helloHandFontSize = 112.0;
  static const double helloRise = 64.0;
  static const double helloExitLift = 48.0;

  // Music player.
  static const double musicPlayerWidth = 420.0;
  static const double musicPlayerHeight = 200.0;
  static const double musicPlayerRadius = 18.0;
  static const double musicPlayerArtwork = 150.0;
  static const double musicPlayerVinyl = 106.0;
  static const double musicMiniVinyl = 24.0;
  static const double musicPlayerVinylHole = 22.0;
  static const double musicChromeHeight = 30.0;
  static const double musicChromeLight = 11.0;
  static const double musicMiniHeight = 56.0;
  static const double musicExpandedWidth = 460.0;
  static const double musicExpandedPlaylistHeight = 168.0;

  static Size mailWindowSize(Size screenSize, bool expanded) {
    if (expanded) {
      return Size(
        (screenSize.width * mailWidthFactor).clamp(
          mailExpandedWidthMin,
          mailExpandedWidthMax,
        ),
        (screenSize.height * mailHeightFactor).clamp(
          mailExpandedHeightMin,
          mailExpandedHeightMax,
        ),
      );
    }
    return Size(
      (screenSize.width * mailWidthFactor).clamp(mailWidthMin, mailWidthMax),
      (screenSize.height * mailHeightFactor).clamp(
        mailHeightMin,
        mailHeightMax,
      ),
    );
  }
}
