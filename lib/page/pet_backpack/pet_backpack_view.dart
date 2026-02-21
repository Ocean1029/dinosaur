import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:dinosaur/page/pet_backpack/pet_backpack_controller.dart';
import 'package:dinosaur/page/pet_backpack/mock_data.dart';
import 'package:dinosaur/util/app_colors.dart';
import 'package:dinosaur/util/app_text.dart';

class PetBackpackView extends GetView<PetBackpackController> {
  const PetBackpackView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildPetSection(),
            Expanded(
              child: _buildBackpackSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: _buildSafeSvg(
                  'assets/svg/icon_arrow_left.svg',
                  size: 24,
                  fallback: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPetSection() {
    return Container(
      height: 320,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final pet = controller.currentPet;
        if (pet == null) {
          return const Center(
            child: AppText('沒有寵物', style: AppTextStyles.body1),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildArrowButton(
                    icon: Icons.chevron_left,
                    isEnabled: controller.canSwitchLeft,
                    onTap: controller.switchToPreviousPet,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBE5DB),
                            borderRadius: BorderRadius.circular(65),
                          ),
                          child: Center(
                            child: Image.asset(
                              pet.assetPath,
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.pets,
                                  size: 60,
                                  color: AppColors.grayscale400,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          pet.name,
                          style: AppTextStyles.h3SemiBold.copyWith(
                            color: AppColors.grayscale800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary500,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AppText(
                            'Lv.${pet.level}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildArrowButton(
                    icon: Icons.chevron_right,
                    isEnabled: controller.canSwitchRight,
                    onTap: controller.switchToNextPet,
                  ),
                ],
              ),
            ),
            _buildPetInfoBar(pet),
          ],
        );
      }),
    );
  }

  Widget _buildPetInfoBar(Pet pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('種類', pet.species),
          _buildInfoItem('出生地', pet.birthplace),
          _buildHungerItem(pet),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        AppText(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.grayscale500,
          ),
        ),
        const SizedBox(height: 2),
        AppText(
          value,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.grayscale800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHungerItem(Pet pet) {
    final percentage = pet.hunger / pet.maxHunger;
    return Column(
      children: [
        AppText(
          '飢餓值',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.grayscale500,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.grayscale200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: percentage < 0.3
                        ? AppColors.red500
                        : percentage < 0.6
                            ? AppColors.orange500
                            : AppColors.primary500,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        AppText(
          '${pet.hunger}/${pet.maxHunger}',
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            color: AppColors.grayscale600,
          ),
        ),
      ],
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.white.withOpacity(0.9)
              : AppColors.grayscale200.withOpacity(0.5),
          shape: BoxShape.circle,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppColors.grayscale700 : AppColors.grayscale400,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildBackpackSection() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    '食物',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final items = controller.foodItems;
              if (items.isEmpty) {
                return const Center(
                  child: AppText(
                    '背包是空的',
                    style: AppTextStyles.body1,
                    color: AppColors.grayscale500,
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildFoodItem(items[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeSvg(String path, {required double size, required Widget fallback}) {
    return FutureBuilder<bool>(
      future: rootBundle.load(path).then((_) => true).catchError((_) => false),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return SvgPicture.asset(path, width: size, height: size, fit: BoxFit.contain);
        }
        return SizedBox(width: size, height: size, child: fallback);
      },
    );
  }

  Widget _buildFoodItem(FoodItem item) {
    final isAvailable = item.count > 0;

    return GestureDetector(
      onTap: isAvailable ? () => controller.feedPet(item) : null,
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.grayscale50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.grayscale200,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Image.asset(
                        item.iconPath,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.fastfood,
                            size: 32,
                            color: AppColors.grayscale400,
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange500,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppText(
                        'x${item.count}',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppText(
                item.name,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grayscale700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
