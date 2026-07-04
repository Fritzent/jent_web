// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class Assets {
  const Assets._();

  static const AssetGenImage icEmail = AssetGenImage('assets/ic_email.png');
  static const AssetGenImage icFinder = AssetGenImage('assets/ic_finder.png');
  static const AssetGenImage icJustLogo = AssetGenImage(
    'assets/ic_just_logo.png',
  );
  static const AssetGenImage icLogo = AssetGenImage('assets/ic_logo.png');
  static const AssetGenImage icLogoTransparent = AssetGenImage(
    'assets/ic_logo_transparent.png',
  );
  static const AssetGenImage icMusic = AssetGenImage('assets/ic_music.png');
  static const AssetGenImage icNotes = AssetGenImage('assets/ic_notes.png');
  static const AssetGenImage icPhotos = AssetGenImage('assets/ic_photos.png');
  static const AssetGenImage icSpotLight = AssetGenImage(
    'assets/ic_spot_light.png',
  );
  static const AssetGenImage icVinyl = AssetGenImage('assets/ic_vinyl.png');
  static const AssetGenImage ilHome1 = AssetGenImage('assets/il_home_1.jpg');
  static const AssetGenImage ilHome2 = AssetGenImage('assets/il_home_2.jpg');
  static const AssetGenImage ilHome3 = AssetGenImage('assets/il_home_3.jpg');
  static const AssetGenImage ilHome4 = AssetGenImage('assets/il_home_4.jpg');
  static const AssetGenImage ilHome5 = AssetGenImage('assets/il_home_5.jpg');

  /// List of all assets
  static List<AssetGenImage> get values => [
    icEmail,
    icFinder,
    icJustLogo,
    icLogo,
    icLogoTransparent,
    icMusic,
    icNotes,
    icPhotos,
    icSpotLight,
    icVinyl,
    ilHome1,
    ilHome2,
    ilHome3,
    ilHome4,
    ilHome5,
  ];
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
