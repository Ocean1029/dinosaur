import 'package:flutter/material.dart';
import 'package:dinosaur/util/app_colors.dart';

class AppText extends StatelessWidget {
  final String? data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final TextSpan? textSpan;

  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.textSpan,
  });

  factory AppText.rich(
    TextSpan textSpan, {
    Key? key,
    TextAlign? textAlign,
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return AppText(
      null,
      key: key,
      textSpan: textSpan,
      textAlign: textAlign,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (textSpan != null) {
      return RichText(
        text: textSpan!,
        textAlign: textAlign ?? TextAlign.start,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.clip,
      );
    }

    return Text(
      data ?? '',
      style: style?.copyWith(color: color) ?? (color != null ? TextStyle(color: color) : null),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class AppTextStyles {
  static const TextStyle h1Bold = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.grayscale900,
  );

  static const TextStyle h2SemiBold = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.grayscale900,
  );

  static const TextStyle h3SemiBold = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.grayscale700,
  );

  static const TextStyle h3Regular = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.grayscale700,
  );

  static const TextStyle h1SemiBold = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.grayscale900,
  );

  static const TextStyle titleSemiBold = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.grayscale900,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.grayscale700,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.grayscale700,
  );

  static const TextStyle bodySemiBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.grayscale700,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.grayscale600,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.grayscale500,
  );

  static const TextStyle h = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.grayscale900,
  );
}