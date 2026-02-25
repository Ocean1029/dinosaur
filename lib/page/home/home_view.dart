import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:dinosaur/gen/assets.gen.dart';
import 'package:dinosaur/page/home/home_controller.dart';
import 'package:dinosaur/page/home/point.dart';
import 'package:dinosaur/service/account_service.dart';
import 'package:dinosaur/util/app_bar.dart';
import 'package:dinosaur/util/cached_network_image.dart';
import 'package:dinosaur/util/app_colors.dart';
import 'package:dinosaur/util/app_route.dart';
import 'package:dinosaur/util/app_text.dart';

const _badgeCompletedColor = Color(0xFF76A732);
const _badgeBaseColor = Color(0xFF76A732);
const double _badgeCloseButtonSize = 26;

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: '跑城市'),
      body: Obx(() {
        // 訪問控制器的可觀察變數以確保 Obx 正確監視
        final isLoading = controller.isLoading.value;
        final errorMsg = controller.errorMessage.value;

        // 檢查用戶是否登入
        if (Get.find<AccountService>().account == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppText(
                  '請先登入以使用此功能',
                  style: AppTextStyles.body1,
                  color: AppColors.grayscale600,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const AppText('返回'),
                ),
              ],
            ),
          );
        }

        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (errorMsg != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  errorMsg,
                  style: AppTextStyles.body1,
                  color: AppColors.red500,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refresh(),
                  child: const AppText('重試'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            mb.MapWidget(
              key: const ValueKey('mapbox-map'),
              // Standard 樣式較容易呈現 3D（傾斜/建物）視覺效果
              styleUri:
                  'mapbox://styles/angelicazywang/cmm1idkcb003e01r68x8mgqdq',
              cameraOptions: mb.CameraOptions(
                // 注意：Position 順序是 (lng, lat)
                center: mb.Point(
                  coordinates: mb.Position(121.564468, 25.033968),
                ),
                zoom: 15,
                // 0-60 常見；數值越大越「斜」越有 3D 感
                pitch: 35.0,
              ),
            ),
            // 動態計算欄（追蹤時顯示）
            Obx(() {
              if (controller.isTracking.value) {
                return Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildTrackingStatsCard(),
                );
              }
              // 左上角頭貼 + 等級（非追蹤時顯示，可點擊進入個人資訊）
              if (controller.userProfile.value != null) {
                return Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Get.toNamed(AppRoute.stats),
                    child: _buildAvatarWithLevel(controller.userProfile.value!),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            Obx(() {
              if (!controller.isBadgePanelVisible.value) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: controller.closeBadgePanel,
                  child: const SizedBox.shrink(),
                ),
              );
            }),
            Obx(() {
              if (!controller.isBadgePanelVisible.value) {
                return const SizedBox.shrink();
              }
              return Positioned(
                left: 16,
                right: 16,
                bottom: 144, // GO按鈕底部36px + 按鈕高度100px + 間距8px = 144px
                child: _buildBadgePanel(context),
              );
            }),
            // 移除本次跑步紀錄卡片，改為直接跳轉到活動詳細頁面
            // 追蹤控制按鈕
            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: _buildTrackingControls(),
            ),
          ],
        );
      }),
    );
  }

  /// 建立動態計算欄（追蹤時顯示）
  Widget _buildTrackingStatsCard() {
    return Obx(() {
      final distanceMeters = controller.totalDistanceMeters.value;
      final elapsed = controller.elapsed.value;

      // 格式化距離
      final distanceKm = distanceMeters / 1000;
      final formattedDistance = distanceKm >= 1
          ? '${distanceKm.toStringAsFixed(1)} 公里'
          : '${distanceMeters.toStringAsFixed(0)} 公尺';

      // 格式化時長 (HH:MM:SS)
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes.remainder(60);
      final seconds = elapsed.inSeconds.remainder(60);
      final formattedDuration =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      return Container(
        padding: const EdgeInsets.only(
            top: 8, bottom: 8, left: 16, right: 16), // 上方8px padding
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // 左欄：距離
            Expanded(
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // icon 對齊 from start
                children: [
                  // Icon 20×20，與左白匡距離24px（16px padding + 8px = 24px），與上方距離8px
                  const SizedBox(width: 8), // 16px padding + 8px = 24px
                  Icon(
                    Icons.straighten,
                    size: 20,
                    color: const Color(0xFF91A0A8), // #91A0A8
                  ),
                  const SizedBox(width: 8), // icon與文字之間8px
                  // 標題和數值
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 標題 14px #91A0A8
                      AppText(
                        '距離',
                        style: AppTextStyles.h3Regular.copyWith(fontSize: 14),
                        color: const Color(0xFF91A0A8),
                      ),
                      const SizedBox(height: 4),
                      // 數值 24px #00B9CA, font-H2-semibold
                      AppText(
                        formattedDistance,
                        style: AppTextStyles.h2SemiBold.copyWith(fontSize: 24),
                        color: const Color(0xFF00B9CA), // #00B9CA
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 右欄：時長（icon貼齊白容器中線，內文向左對齊）
            Expanded(
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // icon 對齊 from start
                children: [
                  // Icon 貼齊白容器中線（在右欄的開始位置，即整個容器的中線）
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: const Color(0xFF91A0A8), // #91A0A8
                  ),
                  const SizedBox(width: 8), // icon與文字之間8px
                  // 內文向左對齊
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 標題 14px #91A0A8，與下方計算時間對齊
                        AppText(
                          '時長',
                          style: AppTextStyles.h3Regular.copyWith(fontSize: 14),
                          color: const Color(0xFF91A0A8),
                        ),
                        const SizedBox(height: 4),
                        // 數值 24px #00B9CA, font-H2-semibold
                        AppText(
                          formattedDuration,
                          style:
                              AppTextStyles.h2SemiBold.copyWith(fontSize: 24),
                          color: const Color(0xFF00B9CA), // #00B9CA
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 右上角頭貼 + 等級（之後等級可替換成真實玩家等級）
  Widget _buildAvatarWithLevel(userData) {
    const avatarSize = 44.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: userData.avatarUrl != null && userData.avatarUrl!.isNotEmpty
              ? ClipOval(
                  child: AppCachedNetworkImage(
                    imageUrl: userData.avatarUrl!,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                  ),
                )
              : ClipOval(
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: const BoxDecoration(
                      color: AppColors.grayscale200,
                      shape: BoxShape.circle,
                    ),
                    child: Assets.svg.logoIconTpe.svg(
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: AppText(
            'level1', // TODO: 替換成真實玩家等級
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grayscale800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgePanel(BuildContext context) {
    return Obx(() {
      final badges = controller.sortedBadges;
      final selected = controller.selectedBadge.value;

      if (badges.isEmpty) {
        // 無徽章時顯示假資料圖片（TestCute1、TestCute2），如徽章方式排列
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.grayscale300.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CuteImageSlot(assetPath: 'assets/svg/TestCute1.png'),
                    _CuteImageSlot(assetPath: 'assets/svg/TestCute2.png'),
                    _CuteImageSlot(assetPath: 'assets/svg/CuteButton.png'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.grayscale300.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: _badgeCloseButtonSize + 14),
                _BadgeArrowButton(
                  icon: Icons.chevron_left,
                  isEnabled: controller.canPageBadgesLeft,
                  onTap: controller.pageBadgesLeft,
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(HomeController.badgesPerPage, (i) {
                  final badge = controller.currentBadgeSlots.length > i
                      ? controller.currentBadgeSlots[i]
                      : null;
                  final isSelected = badge != null && selected?.id == badge.id;
                  final badgeIndex = badge != null
                      ? controller.badges
                          .indexWhere((b) => b.badgeId == badge.badgeId)
                      : -1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: i == 1 ? 12 : 6,
                      ),
                      child: badge != null
                          ? _BadgePreview(
                              badge: badge,
                              isSelected: isSelected,
                              badgeIndex: badgeIndex,
                              onTap: () => controller.selectBadge(badge),
                            )
                          : const _BadgePlaceholder(),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: _badgeCloseButtonSize + 14),
                _BadgeArrowButton(
                  icon: Icons.chevron_right,
                  isEnabled: controller.canPageBadgesRight,
                  onTap: controller.pageBadgesRight,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTrackingControls() {
    const goButtonWidth = 100.0; // 固定為 100x100
    const positionButtonWidth = 54.0;
    const spacing = 50.0;
    const badgeButtonSize = 54.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center, // 垂直置中
      children: [
        // 左側空白，用於平衡布局
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直置中
            children: [
              // 位置按鈕（位於中央大按鈕左側 50px 處）
              Obx(() => GestureDetector(
                    onTap: () {
                      controller.centerToUserLocation();
                    },
                    child: Container(
                      width: positionButtonWidth,
                      height: positionButtonWidth,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/svg/position.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          controller.isUserLocationCentered.value
                              ? const Color(0xFF5AB4C5) // 居中時為藍色
                              : const Color(0xFF475259), // 未居中時為灰色
                          BlendMode.srcIn,
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  )),
              SizedBox(width: spacing),
            ],
          ),
        ),
        // 中央大按鈕：白底 + CuteButton 圖片，點擊展開徽章選單（與右側徽章按鈕相同功能）
        GestureDetector(
          onTap: controller.toggleBadgePanel,
          child: Container(
            width: goButtonWidth,
            height: goButtonWidth,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/svg/CuteButton.png',
              width: goButtonWidth * 0.6,
              height: goButtonWidth * 0.6,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: spacing), // GO 按鈕右側距離 50px
              _buildBadgeToggleButton(size: badgeButtonSize),
              if (positionButtonWidth > badgeButtonSize)
                SizedBox(width: positionButtonWidth - badgeButtonSize),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeToggleButton({double size = 54}) {
    return Obx(() {
      final hasBadges = controller.badges.isNotEmpty;
      final backgroundColor = AppColors.white;
      final iconSize = size * 0.6;

      return Opacity(
        opacity: hasBadges ? 1 : 0.7,
        child: GestureDetector(
          onTap: controller.toggleBadgePanel,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg/badge_icon.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: const ColorFilter.mode(
                  _badgeBaseColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// 假資料圖片一格（如徽章般圓形顯示）
class _CuteImageSlot extends StatelessWidget {
  const _CuteImageSlot({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              assetPath,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgePreview extends StatelessWidget {
  const _BadgePreview({
    required this.badge,
    required this.isSelected,
    required this.badgeIndex,
    required this.onTap,
  });

  final BadgeModel badge;
  final bool isSelected;
  final int badgeIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final collectedCount = badge.collectedPoints;
    final totalCount = badge.totalPoints;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected && badge.badgeColor != null
                  ? Border.all(
                      color: badge.badgeColor!,
                      width: 3,
                    )
                  : null,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg/badge_icon.svg',
                width: 40,
                height: 40,
                colorFilter: ColorFilter.mode(
                  badge.badgeColor ?? _badgeCompletedColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 66,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  badge.name,
                  style: AppTextStyles.caption,
                  color: isSelected
                      ? const Color(0xFF5AB4C5)
                      : AppColors.grayscale900,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.grayscale200, width: 1),
                  ),
                  child: AppText.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: collectedCount.toString(),
                          style: const TextStyle(color: AppColors.primary500),
                        ),
                        TextSpan(
                          text: '/$totalCount',
                          style: const TextStyle(color: AppColors.grayscale400),
                        ),
                      ],
                      style: AppTextStyles.caption,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeArrowButton extends StatelessWidget {
  const _BadgeArrowButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 22,
            color: isEnabled ? AppColors.grayscale500 : AppColors.grayscale300,
          ),
        ),
      ),
    );
  }
}

class _BadgePlaceholder extends StatelessWidget {
  const _BadgePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.25,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grayscale100,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppColors.grayscale100,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 44,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.grayscale200, width: 1),
            ),
          ),
        ],
      ),
    );
  }
}
