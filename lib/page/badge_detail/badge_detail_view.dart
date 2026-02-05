import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dinosaur/gen/assets.gen.dart';
import 'package:dinosaur/page/badge_detail/badge_detail_controller.dart';
import 'package:dinosaur/page/home/point.dart';
import 'package:dinosaur/page/home/widgets/badge_share_card.dart';
import 'package:dinosaur/util/app_bar.dart';
import 'package:dinosaur/util/app_colors.dart';
import 'package:dinosaur/util/app_text.dart';

class BadgeDetailView extends GetView<BadgeDetailController> {
  const BadgeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Run City'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value != null) {
          return Center(child: Text(controller.errorMessage.value ?? ''));
        }
        if (controller.badgeLocations.isEmpty) {
          return _buildEmptyState();
        }
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BadgeHeader(
                      controller: controller,
                      onShare: () => _showSharePreview(context, controller),
                    ),
                    const SizedBox(height: 16),
                    _BadgeMap(controller: controller),
                    const SizedBox(height: 16),
                    _BadgeLocationsTable(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppText(
            '此徽章尚無點位資料',
            style: AppTextStyles.body1,
            color: AppColors.grayscale500,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: Get.back,
            child: const AppText('返回'),
          )
        ],
      ),
    );
  }

  void _showSharePreview(
    BuildContext context,
    BadgeDetailController controller,
  ) {
    Get.dialog(
      _BadgeSharePreviewDialog(controller: controller),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
    );
  }
}

class _BadgeHeader extends StatelessWidget {
  const _BadgeHeader({required this.controller, required this.onShare});

  final BadgeDetailController controller;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final badge = controller.badge;
    if (badge == null) {
      return const SizedBox.shrink();
    }
    final collected = controller.collectedPoints;
    final total = controller.totalPoints;
    final canShare = controller.isCompleted;
    final Color shareButtonColor =
        canShare ? AppColors.runCityBlue : AppColors.grayscale200;
    final Color shareIconColor =
        canShare ? AppColors.white : AppColors.grayscale500;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Assets.svg.badgeIcon.svg(
          width: 60,
          height: 60,
          colorFilter: ColorFilter.mode(
            badge.badgeColor ?? const Color(0xFF76A732),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AppText(
                      badge.name,
                      style: AppTextStyles.h3SemiBold,
                      color: AppColors.grayscale900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _BadgeProgressChip(collected: collected, total: total),
                ],
              ),
              const SizedBox(height: 4),
              AppText(
                controller.badgeDescription,
                style: AppTextStyles.body1,
                color: AppColors.grayscale500,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: canShare ? onShare : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shareButtonColor,
              boxShadow: canShare
                  ? const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Icon(Icons.ios_share, color: shareIconColor),
          ),
        ),
      ],
    );
  }
}

class _BadgeSharePreviewDialog extends StatelessWidget {
  const _BadgeSharePreviewDialog({required this.controller});

  final BadgeDetailController controller;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final badge = controller.badge;
    if (badge == null) {
      return const SizedBox.shrink();
    }
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
                    children: const [
                      AppText(
                        '分享徽章',
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
                      child: RepaintBoundary(
                        key: controller.shareCardKey,
                        child: BadgeShareCard(
                          badgeName: badge.name,
                          badgeDescription: controller.badgeDescription,
                          collectedPoints: controller.collectedPoints,
                          totalPoints: controller.totalPoints,
                          userName: controller.shareUserName,
                          completedAt: badge.unlockedAt ?? DateTime.now(),
                          badgeColor: badge.badgeColor ?? AppColors.orange500,
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.grayscale100),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: GetBuilder<BadgeDetailController>(
                    id: 'sharePreview',
                    builder: (ctrl) {
                      final bool busy = ctrl.isSharing;
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: busy ? null : () => Get.back<void>(),
                              child: const Text('取消'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final success = await ctrl.shareBadge();
                                      if (success &&
                                          (Get.isDialogOpen ?? false)) {
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

class _BadgeMap extends StatelessWidget {
  const _BadgeMap({required this.controller});

  final BadgeDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GetBuilder<BadgeDetailController>(
          id: 'badgeMap',
          builder: (ctrl) {
            return Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                initialCameraPosition: ctrl.initialCameraPosition,
                markers: ctrl.markers,
                circles: ctrl.circles,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                polylines: const <Polyline>{},
                onMapCreated: ctrl.onMapCreated,
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                '點位資訊',
                style: AppTextStyles.caption.copyWith(fontSize: 14),
                color: AppColors.grayscale500,
              ),
              AppText(
                '點按可顯示詳細位置',
                style: AppTextStyles.caption.copyWith(fontSize: 14),
                color: AppColors.grayscale400,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _BadgeLocationsTable extends StatelessWidget {
  const _BadgeLocationsTable({required this.controller});

  final BadgeDetailController controller;

  @override
  Widget build(BuildContext context) {
    final locations = controller.badgeLocations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.grayscale100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: AppText(
                    '點位名稱',
                    style: AppTextStyles.caption,
                    color: AppColors.grayscale500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: AppText(
                  '狀態',
                  style: AppTextStyles.caption,
                  color: AppColors.grayscale500,
                ),
              ),
              SizedBox(width: 24),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...locations.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final location = entry.value;
            final isLast = index == locations.length - 1;
            return _LocationRow(
              location: location,
              isCollected: location.isCollected,
              onTap: () => controller.focusOnLocation(location),
              showDivider: !isLast,
            );
          },
        ),
      ],
    );
  }
}

class _LocationRow extends StatefulWidget {
  const _LocationRow({
    required this.location,
    required this.isCollected,
    required this.onTap,
    required this.showDivider,
  });

  final BadgeLocation location;
  final bool isCollected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  State<_LocationRow> createState() => _LocationRowState();
}

class _LocationRowState extends State<_LocationRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final statusText = widget.isCollected ? '已完成' : '待收集';
    final statusBackground =
        widget.isCollected ? const Color(0xFFDBF1F5) : const Color(0xFF5AB4C5);

    return Column(
      children: [
        Container(
          decoration: widget.showDivider
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.grayscale200, width: 1),
                  ),
                )
              : null,
          child: InkWell(
            onTap: () {
              widget.onTap();
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: AppText(
                            widget.location.name,
                            style:
                                AppTextStyles.body1.copyWith(fontSize: 13),
                            color: AppColors.grayscale900,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AppText(
                              statusText,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.grayscale400,
                      ),
                    ],
                  ),
                  if (_expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppText(
                          widget.location.nfcId ?? '未指定',
                          style: AppTextStyles.body1.copyWith(
                            fontSize: 12,
                            color: AppColors.grayscale500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeProgressChip extends StatelessWidget {
  const _BadgeProgressChip({
    required this.collected,
    required this.total,
  });

  final int collected;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB7CBD4), width: 1),
      ),
      child: AppText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$collected',
              style: const TextStyle(color: Color(0xFF5AB4C5)),
            ),
            const TextSpan(
              text: '/',
              style: TextStyle(color: Color(0xFF91A0A8)),
            ),
            TextSpan(
              text: '$total',
              style: const TextStyle(color: Color(0xFF91A0A8)),
            ),
          ],
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
