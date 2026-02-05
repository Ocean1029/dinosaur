import 'package:flutter/material.dart';
import 'package:dinosaur/util/app_colors.dart';
import 'package:dinosaur/util/app_text.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final String? title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppAppBar({
    super.key,
    this.leading,
    this.bottom,
    this.title,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      key: key,
      leading: leading,
      title: AppText(
        title ?? '',
        style: AppTextStyles.h3SemiBold,
      ),
      actions: actions ?? [const SizedBox(width: 56)],
      backgroundColor: backgroundColor ?? AppColors.white,
      foregroundColor: foregroundColor ?? AppColors.grayscale700,
      elevation: 0,
      centerTitle: true,
      bottom: bottom,
      surfaceTintColor: Colors.transparent,
    );
  }
}