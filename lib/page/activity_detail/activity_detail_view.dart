import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dinosaur/gen/assets.gen.dart';
import 'package:dinosaur/page/activity_detail/activity_detail_controller.dart';
import 'package:dinosaur/page/home/point.dart';
import 'package:dinosaur/page/home/widgets/activity_share_card.dart';
import 'package:dinosaur/util/app_bar.dart';
import 'package:dinosaur/util/cached_network_image.dart';
import 'package:dinosaur/util/app_colors.dart';
import 'package:dinosaur/util/app_text.dart';

class ActivityDetailView
    extends GetView<ActivityDetailController> {
  const ActivityDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: '運動紀錄'),
      body: Obx(() {
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
                  onPressed: () => controller.refreshActivity(),
                  child: const AppText('重試'),
                ),
              ],
            ),
          );
        }

        final detail = controller.activityDetail.value;
        if (detail == null) {
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
            onRefresh: () => controller.refreshActivity(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 統一的白色背景容器，包含所有區塊
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16), // 白色容器padding 16px
                  child: Column(
                    children: [
                      // 活動摘要區塊（姓名、日期時間、距離時間）
                      _buildActivitySummarySection(context, detail),
                      // 地圖區塊
                      _buildMapSection(detail),
                      // 點位紀錄區塊
                      _buildLocationRecordsSection(detail),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 建立活動摘要區塊（姓名、日期時間、距離時間）
  Widget _buildActivitySummarySection(
    BuildContext context,
    ActivityDetail detail,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 用戶資訊
        Padding(
          padding: const EdgeInsets.only(
              left: 8,
              top:
                  8), // avatar左側與白色方框相距24px (16px padding + 8px = 24px)，姓名與上方白框距離24px (16px padding + 8px = 24px)
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直置中
            children: [
              // 頭像 64×64
              if (detail.userAvatar != null && detail.userAvatar!.isNotEmpty)
                ClipOval(
                  child: AppCachedNetworkImage(
                    imageUrl: detail.userAvatar!,
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
              // 姓名和日期時間
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 姓名 16px
                    AppText(
                      detail.userName,
                      style: AppTextStyles.titleSemiBold.copyWith(fontSize: 16),
                      color: AppColors.grayscale950,
                    ),
                    const SizedBox(height: 8),
                    // 日期時間 + 分享
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: AppText(
                            detail.formattedDateTimeRange,
                            style:
                                AppTextStyles.body1.copyWith(fontSize: 14),
                            color: AppColors.grayscale950,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.ios_share),
                          color: AppColors.runCityBlue,
                          splashRadius: 20,
                          tooltip: '分享',
                          onPressed: () => _handleShareTap(context, controller),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 距離和時間統計
        _buildTotalStatsRow(
          distanceValue: detail.formattedDistance,
          timeValue: detail.formattedDuration,
        ),
      ],
    );
  }

  /// 建立總統計行（兩個統計項目，統一縮放）
  Widget _buildTotalStatsRow({
    required String distanceValue,
    required String timeValue,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Padding(
          padding: const EdgeInsets.only(
              left: 8), // 白色容器邊框到icon為24px (16px padding + 8px = 24px)
          child: Row(
            children: [
              _buildTotalStatItem(
                icon: Icons.straighten,
                label: '距離',
                value: distanceValue,
                fontSize: 24, // 藍色字 24px
                iconSize: 20, // icon 20×20
                labelFontSize: 14, // 標題 14px
              ),
              const SizedBox(width: 8), // 文字到下一個icon是8px
              _buildTotalStatItem(
                icon: Icons.access_time,
                label: '時間',
                value: timeValue,
                fontSize: 24, // 藍色字 24px
                iconSize: 20, // icon 20×20
                labelFontSize: 14, // 標題 14px
              ),
            ],
          ),
        ),
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

  /// 建立地圖區塊
  Widget _buildMapSection(detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 0, vertical: 16), // 地圖與上下的文字距離16px
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.grayscale200,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Obx(() {
            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(25.0330, 121.5654),
                zoom: 15,
              ),
              onMapCreated: controller.onMapCreated,
              markers: controller.markers.toSet(),
              polylines: controller.polylines.toSet(),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            );
          }),
        ),
      ),
    );
  }

  /// 建立點位紀錄區塊
  Widget _buildLocationRecordsSection(detail) {
    final records = detail.locationRecords;
    // 按照 collectedAt 時間排序（最早的在最上面）
    final sortedRecords = List<ActivityLocationRecord>.from(records)
      ..sort((a, b) => a.collectedAt.compareTo(b.collectedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題 14px，與下方表格12px間距
        Padding(
          padding: const EdgeInsets.only(
              left: 8,
              bottom:
                  12), // 「點位紀錄」左側與白色方框相距24px (16px padding + 8px = 24px)，與下方表格12px
          child: AppText(
            '點位紀錄',
            style: AppTextStyles.h3SemiBold.copyWith(fontSize: 14), // 字體大小14px
            color: AppColors.grayscale400, // #91A0A8
          ),
        ),
        // 表格
        if (sortedRecords.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: AppText(
                '尚無點位紀錄',
                style: AppTextStyles.body1,
                color: AppColors.grayscale600,
              ),
            ),
          )
        else
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 0), // 表格使用白色容器的padding
            child: Column(
              children: [
                // 表頭
                _buildLocationTableHeader(),
                // 資料列（從最早到最晚）
                ...sortedRecords.asMap().entries.map((entry) {
                  final index = entry.key;
                  final record = entry.value;
                  final isLast = index == sortedRecords.length - 1;
                  return _buildLocationTableRow(record, isLast: isLast);
                }),
              ],
            ),
          ),
        // 底部 padding
        const SizedBox(height: 16),
      ],
    );
  }

  /// 建立點位紀錄表格表頭
  Widget _buildLocationTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.runCityTableHeader,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              '點位名稱',
              style: AppTextStyles.caption,
              color: AppColors.grayscale400,
            ),
          ),
          Expanded(
            flex: 2,
            child: AppText(
              '時間',
              style: AppTextStyles.caption,
              color: AppColors.grayscale400,
            ),
          ),
          Expanded(
            flex: 2,
            child: AppText(
              '位置',
              style: AppTextStyles.caption,
              color: AppColors.grayscale400,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立點位紀錄表格資料列
  Widget _buildLocationTableRow(record, {required bool isLast}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null // 最後一列不需要底部邊框
            : Border(
                bottom: BorderSide(
                  color: AppColors.grayscale200,
                  width: 1,
                ),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: AppText(
                record.locationName,
                style: AppTextStyles.body1.copyWith(fontSize: 12),
                color: AppColors.grayscale950,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                record.formattedTime,
                style: AppTextStyles.body1.copyWith(fontSize: 12),
                color: AppColors.grayscale950,
              ),
            ),
            Expanded(
              flex: 2,
              child: AppText(
                record.formattedLocation,
                style: AppTextStyles.body1.copyWith(fontSize: 12),
                color: AppColors.grayscale950,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleShareTap(
  BuildContext context,
  ActivityDetailController controller,
) async {
  final ready = await controller.prepareSharePreview();
  if (!ready) {
    return;
  }

  final detail = controller.activityDetail.value;
  if (detail == null) {
    controller.closeSharePreview();
    return;
  }

  await Get.dialog(
    _ActivitySharePreviewDialog(
      controller: controller,
      detail: detail,
    ),
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.65),
  );
  controller.closeSharePreview();
}

class _ActivitySharePreviewDialog extends StatelessWidget {
  const _ActivitySharePreviewDialog({
    required this.controller,
    required this.detail,
  });

  final ActivityDetailController controller;
  final ActivityDetail detail;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenSize.height * 0.85,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      AppText(
                        '分享運動紀錄',
                        style: AppTextStyles.h3SemiBold,
                        color: AppColors.grayscale900,
                      ),
                      SizedBox(height: 4),
                      AppText(
                        '預覽分享畫面，確認後點擊分享即可',
                        style: AppTextStyles.caption,
                        color: AppColors.grayscale400,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.grayscale100),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 393,
                          height: 753,
                          child: RepaintBoundary(
                            key: controller.shareCardKey,
                            child: ActivityShareCard(
                              userName: detail.userName,
                              dateTimeRange: detail.formattedDateTimeRange,
                              distanceText: detail.formattedDistance,
                              durationText: detail.formattedDuration,
                              coinsText: detail.totalCoinsEarned.toString(),
                              mapSnapshot: controller.shareMapSnapshot,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.grayscale100),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: GetBuilder<ActivityDetailController>(
                    id: 'sharePreview',
                    builder: (ctrl) {
                      final busy = ctrl.isSharing;
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () {
                                      controller.closeSharePreview();
                                      Get.back<void>();
                                    },
                              child: const Text('取消'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final success =
                                          await ctrl.shareActivity();
                                      if (success &&
                                          (Get.isDialogOpen ?? false)) {
                                        ctrl.closeSharePreview();
                                        Get.back<void>();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.runCityBlue,
                                foregroundColor: AppColors.white,
                              ),
                              child: busy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppColors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('分享'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
