// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_svg/flutter_svg.dart';

class $AssetsMockDataGen {
  const $AssetsMockDataGen();

  /// File path: assets/mock_data/data.json
  String get data => 'assets/mock_data/data.json';

  /// List of all assets
  List<String> get values => [data];

  /// Alias for 'data' to support both naming conventions
  String get runCity => data;
}

class $AssetsSvgGen {
  const $AssetsSvgGen();

  /// File path: assets/svg/badge_icon.svg
  String get badgeIcon => 'assets/svg/badge_icon.svg';

  /// File path: assets/svg/logo.svg
  String get logo => 'assets/svg/logo.svg';

  /// Alias for logo (向後兼容)
  String get logoIconTpe => 'assets/svg/logo.svg';

  /// List of all assets
  List<String> get values => [badgeIcon, logo];
}

class Assets {
  const Assets._();

  static const $AssetsMockDataGen mockData = $AssetsMockDataGen();
  static const $AssetsSvgGen svg = $AssetsSvgGen();
}

/// Extension on String to provide SVG rendering support
extension SvgStringExtension on String {
  /// Returns this string as an SvgPicture widget
  SvgPicture svg({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    Color? color,
    BlendMode colorBlendMode = BlendMode.srcIn,
    bool excludeFromSemantics = false,
    Clip clipBehavior = Clip.hardEdge,
    ColorFilter? colorFilter,
  }) {
    return SvgPicture.asset(
      this,
      key: key,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      color: color,
      colorBlendMode: colorBlendMode,
      excludeFromSemantics: excludeFromSemantics,
      clipBehavior: clipBehavior,
      colorFilter: colorFilter,
    );
  }
}
