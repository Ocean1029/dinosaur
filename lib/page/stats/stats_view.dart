import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dinosaur/gen/assets.gen.dart';
import 'package:dinosaur/page/stats/stats_controller.dart';
import 'package:dinosaur/page/home/point.dart';
import 'package:dinosaur/service/account_service.dart';
import 'package:dinosaur/util/app_bar.dart';
import 'package:dinosaur/util/cached_network_image.dart';
import 'package:dinosaur/util/app_colors.dart';
import 'package:dinosaur/util/app_route.dart';
import 'package:dinosaur/util/app_text.dart';

class StatsView extends GetView<StatsController> {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: '個人資訊'),
      body: Obx(() {
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

        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  controller.errorMessage.value ?? '發生錯誤',
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

        final userData = controller.userData.value;
        if (userData == null) {
          return const Center(
            child: AppText(
              '無資料',
              style: AppTextStyles.body1,
              color: AppColors.grayscale600,
            ),
          );
        }

        return Container(
          color: AppColors.runCityBackground,
          child: RefreshIndicator(
            onRefresh: () => controller.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: false,
              children: [
                // 個人簡介區塊
                _buildUserProfileCard(userData),
                const SizedBox(height: 16),
                // 徽章區塊（預留位置）
                _buildBadgeSection(),
                const SizedBox(height: 16),
                // 運動紀錄區塊
                _buildActivityRecordsSection(),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 建立個人簡介區塊（無陰影）
  Widget _buildUserProfileCard(userData) {
    return Container(
      padding: const EdgeInsets.all(16), // 白色容器padding 16px
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16), // 圓角16px
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一區：圖片、名字、金幣
          Padding(
            padding: const EdgeInsets.only(
                left: 8,
                top:
                    8), // avatar左側與白色方框相距24px (16px padding + 8px = 24px)，姓名與上方白框距離24px (16px padding + 8px = 24px)
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // 垂直置中
              children: [
                // 頭貼 64×64
                if (userData.avatarUrl != null &&
                    userData.avatarUrl!.isNotEmpty)
                  ClipOval(
                    child: AppCachedNetworkImage(
                      imageUrl: userData.avatarUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                    ),
                  )
                else
                  ClipOval(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.grayscale200,
                        shape: BoxShape.circle,
                      ),
                      child: Assets.svg.logoIconTpe.svg(
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                // 右側：名字和金幣
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 姓名 16px
                      AppText(
                        userData.name,
                        style:
                            AppTextStyles.titleSemiBold.copyWith(fontSize: 16),
                        color: AppColors.grayscale950,
                      ),
                      const SizedBox(height: 8),
                      // 金幣和徽章
                      Row(
                        children: [
                          // 金幣（藍色點點，約10x10像素）
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.runCityBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // 金幣數字 14px
                          AppText(
                            'x ${userData.totalCoins}',
                            style:
                                AppTextStyles.body1.copyWith(fontSize: 14),
                            color: AppColors.grayscale950,
                          ),
                          const SizedBox(width: 16),
                          // 徽章（六角形，約10x10像素，暫時顯示 x 10）
                          Icon(
                            Icons.hexagon,
                            size: 10,
                            color: const Color(0xFF8B9A5B), // 橄欖綠色
                          ),
                          const SizedBox(width: 4),
                          AppText(
                            'x 10',
                            style:
                                AppTextStyles.body1.copyWith(fontSize: 14),
                            color: AppColors.grayscale950,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 分隔線
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.grayscale200,
            ),
          ),
          // 第二區：總距離和總時間
          _buildTotalStatsRow(
            distanceValue: userData.formattedTotalDistance,
            timeValue: userData.formattedTotalTime,
          ),
        ],
      ),
    );
  }

  /// 建立總統計行（兩個統計項目，先顯示總距離，再顯示總時間）
  Widget _buildTotalStatsRow({
    required String timeValue,
    required String distanceValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 8), // 白色容器邊框到icon為24px (16px padding + 8px = 24px)
      child: Row(
        children: [
          _buildTotalStatItem(
            icon: Icons.straighten,
            label: '總距離',
            value: distanceValue,
            fontSize: 24, // 藍色字 24px
            iconSize: 20, // icon 20×20
            labelFontSize: 14, // 標題 14px
          ),
          const SizedBox(width: 8), // 文字到下一個icon是8px
          _buildTotalStatItem(
            icon: Icons.access_time,
            label: '總時間',
            value: timeValue,
            fontSize: 24, // 藍色字 24px
            iconSize: 20, // icon 20×20
            labelFontSize: 14, // 標題 14px
          ),
        ],
      ),
    );
  }

  /// 建立總統計項目（icon 在左，標題和數值在右）
  Widget _buildTotalStatItem({
    required IconData icon,
    required String label,
    required String value,
    required double fontSize,
    required double iconSize,
    required double labelFontSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon 在左側 20×20
        Icon(
          icon,
          size: iconSize,
          color: AppColors.runCityGray,
        ),
        const SizedBox(width: 8), // icon到文字是8px
        // 標題和數值在右側（垂直排列）
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題（灰字）14px
            AppText(
              label,
              style: AppTextStyles.h3Regular.copyWith(fontSize: labelFontSize),
              color: AppColors.runCityGray,
            ),
            const SizedBox(height: 4),
            // 數值（藍字，大且粗，不換行）24px
            AppText(
              value,
              style: AppTextStyles.h2SemiBold.copyWith(
                fontSize: fontSize,
              ),
              color: AppColors.runCityBlue,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ],
        ),
      ],
    );
  }

  /// 建立徽章區塊
  Widget _buildBadgeSection() {
    return Obx(() {
      final allBadges = controller.badges.toList(growable: false);
      final isExpanded = controller.areBadgesExpanded.value;
      final canToggle = allBadges.length > 3;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: canToggle ? controller.toggleBadgeExpansion : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      '我的徽章',
                      style: AppTextStyles.h3SemiBold.copyWith(fontSize: 14),
                      color: AppColors.grayscale400,
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: canToggle
                          ? AppColors.grayscale400
                          : AppColors.grayscale200,
                    ),
                  ],
                ),
              ),
            ),
            if (allBadges.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: AppText(
                    '尚無徽章資料',
                    style: AppTextStyles.body1,
                    color: AppColors.grayscale600,
                  ),
                ),
              )
            else
              _BadgeGrid(
                badges: allBadges,
                isExpanded: isExpanded,
                onBadgeTap: (badge) {
                  Get.toNamed(
                    AppRoute.badgeDetail,
                    arguments: {
                      'badgeId': badge.badgeId,
                    },
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  /// 建立運動紀錄區塊（表格格式）
  Widget _buildActivityRecordsSection() {
    return Obx(() {
      final activities = controller.activities;
      return Container(
        padding: const EdgeInsets.all(16), // 白色容器padding 16px
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16), // 圓角16px
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題 14px，與下方表格12px間距，與左邊的白色方匡距離為24px
            Padding(
              padding: const EdgeInsets.only(
                  left: 8,
                  bottom:
                      12), // 與左邊的白色方匡距離為24px (16px padding + 8px = 24px)，與下方表格12px
              child: AppText(
                '運動紀錄',
                style: AppTextStyles.h3SemiBold.copyWith(fontSize: 14), // 14px
                color: AppColors.grayscale400,
              ),
            ),
            // 表格
            if (activities.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: AppText(
                    '尚無歷史紀錄',
                    style: AppTextStyles.body1,
                    color: AppColors.grayscale600,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 0), // 表格與左側白匡為16px（使用容器的padding）
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 表頭
                    _buildTableHeader(),
                    // 資料列 - 確保所有資料都能顯示
                    ...activities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final activity = entry.value;
                      final isLast = index == activities.length - 1;
                      return _buildTableRow(activity, isLast: isLast);
                    }),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  /// 建立表格表頭
  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // 標頭與第一行之間相距12px
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 上下 padding 8px
        decoration: BoxDecoration(
          color: AppColors.runCityTableHeader,
          borderRadius: BorderRadius.circular(8), // 四個角都是圓角
          // 標頭不需要陰影
        ),
        child: Row(
          children: [
            // 日期列 - flex: 4
            Expanded(
              flex: 4,
              child: AppText(
                '日期',
                style: AppTextStyles.caption,
                color: AppColors.grayscale400,
              ),
            ),
            // 時間列 - flex: 5
            Expanded(
              flex: 5,
              child: AppText(
                '時間',
                style: AppTextStyles.caption,
                color: AppColors.grayscale400,
              ),
            ),
            // 距離列 - flex: 4
            Expanded(
              flex: 4,
              child: AppText(
                '距離',
                style: AppTextStyles.caption,
                color: AppColors.grayscale400,
              ),
            ),
            // 金幣列 - flex: 2
            Expanded(
              flex: 2,
              child: AppText(
                '金幣',
                style: AppTextStyles.caption,
                color: AppColors.grayscale400,
              ),
            ),
            // 箭頭位置固定寬度
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  /// 建立表格資料列
  Widget _buildTableRow(activity, {required bool isLast}) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final dateStr = dateFormat.format(activity.date);
    final accountService = Get.find<AccountService>();
    final userId = accountService.account?.id ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // 每一列之間相距12px
      child: GestureDetector(
        onTap: () {
          Get.toNamed(
            AppRoute.activityDetail,
            arguments: {
              'activityId': activity.activityId,
              'userId': userId,
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 上下 padding 8px
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8), // 每行都有圓角
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000), // 陰影顏色
                offset: Offset(1, 1), // x:1, y:1
                blurRadius: 4, // blur:4
                spreadRadius: 0, // spread:0
              ),
            ],
          ),
          child: Row(
            children: [
              // 日期列 - flex: 4
              Expanded(
                flex: 4,
                child: AppText(
                  dateStr,
                  style: AppTextStyles.body1.copyWith(fontSize: 12),
                  color: AppColors.grayscale950,
                ),
              ),
              // 時間列 - flex: 5
              Expanded(
                flex: 5,
                child: AppText(
                  activity.formattedTimeRange,
                  style: AppTextStyles.body1.copyWith(fontSize: 12),
                  color: AppColors.grayscale950,
                ),
              ),
              // 距離列 - flex: 4
              Expanded(
                flex: 4,
                child: AppText(
                  activity.formattedDistance,
                  style: AppTextStyles.body1.copyWith(fontSize: 12),
                  color: AppColors.grayscale950,
                ),
              ),
              // 金幣列 - flex: 2
              Expanded(
                flex: 2,
                child: AppText(
                  '${activity.coinsEarned}',
                  style: AppTextStyles.body1.copyWith(fontSize: 12),
                  color: AppColors.grayscale950,
                ),
              ),
              // 右側箭頭指示可點擊（箭頭上面不用標題）
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.grayscale400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({
    required this.badges,
    required this.isExpanded,
    required this.onBadgeTap,
  });

  final List<BadgeModel> badges;
  final bool isExpanded;
  final void Function(BadgeModel badge) onBadgeTap;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!isExpanded) {
      final collapsedBadges = List<BadgeModel?>.generate(
        3,
        (index) => index < badges.length ? badges[index] : null,
      );
      return Row(
        children: collapsedBadges
            .map(
              (badge) => Expanded(
                child: _BadgeSummaryCard(
                  badge: badge,
                  onTap: badge != null ? () => onBadgeTap(badge) : null,
                ),
              ),
            )
            .toList(),
      );
    }

    final List<Widget> rows = <Widget>[];
    final totalRows = (badges.length / 3).ceil();

    for (int rowIndex = 0; rowIndex < totalRows; rowIndex++) {
      final start = rowIndex * 3;
      var end = start + 3;
      if (end > badges.length) {
        end = badges.length;
      }
      final rowBadges = badges.sublist(start, end);
      rows.add(
        Row(
          children: [
            ...rowBadges.map(
              (badge) => Expanded(
                child: _BadgeSummaryCard(
                  badge: badge,
                  onTap: () => onBadgeTap(badge),
                ),
              ),
            ),
            ...List<Widget>.generate(
              3 - rowBadges.length,
              (_) => const Expanded(child: SizedBox()),
            ),
          ],
        ),
      );
      if (rowIndex != totalRows - 1) {
        rows.add(const SizedBox(height: 16));
      }
    }

    return Column(
      children: rows,
    );
  }
}

class _BadgeSummaryCard extends StatelessWidget {
  const _BadgeSummaryCard({required this.badge, this.onTap});

  final BadgeModel? badge;
  final VoidCallback? onTap;

  static const Color _completedColor = Color(0xFF76A732);
  static const Color _incompleteColor = Color(0xFFD5DDE5);

  @override
  Widget build(BuildContext context) {
    if (badge == null) {
      return Opacity(
        opacity: 0.3,
        child: _BadgeContainer(
          iconColor: _incompleteColor,
          title: '待解鎖',
          progress: '--/--',
        ),
      );
    }

    final isCompleted = badge!.isCompleted;
    final collected = badge!.collectedPoints;
    final total = badge!.totalPoints;
    // 優先使用數據庫中的徽章顏色
    // 如果已收集，使用完整顏色；如果未收集，使用數據庫顏色但降低透明度
    final Color iconColor;
    if (badge!.badgeColor != null) {
      // 如果有數據庫顏色，使用它（已收集用完整顏色，未收集用半透明）
      iconColor = isCompleted 
          ? badge!.badgeColor!
          : badge!.badgeColor!.withOpacity(0.3);
    } else {
      // 如果沒有數據庫顏色，使用默認顏色
      iconColor = isCompleted ? _completedColor : _incompleteColor;
    }

    return GestureDetector(
      onTap: onTap,
      child: _BadgeContainer(
        iconColor: iconColor,
        title: badge!.name,
        progress: '$collected/$total',
        isCompleted: isCompleted,
      ),
    );
  }
}

class _BadgeContainer extends StatelessWidget {
  const _BadgeContainer({
    required this.iconColor,
    required this.title,
    required this.progress,
    this.isCompleted = false,
  });

  final Color iconColor;
  final String title;
  final String progress;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final parts = progress.split('/');
    final collectedText = parts.isNotEmpty ? parts.first : progress;
    final totalText = parts.length > 1 ? parts.last : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/svg/badge_icon.svg',
          width: 56,
          height: 56,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        const SizedBox(height: 8),
        AppText(
          title,
          style: AppTextStyles.body1.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          color: Color(0xFF91A0A8),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.grayscale400,
              width: 1,
            ),
          ),
          child: AppText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: collectedText,
                  style: const TextStyle(color: Color(0xFF5AB4C5)),
                ),
                const TextSpan(
                  text: '/',
                  style: TextStyle(color: Color(0xFF91A0A8)),
                ),
                TextSpan(
                  text: totalText,
                  style: const TextStyle(color: Color(0xFF91A0A8)),
                ),
              ],
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
