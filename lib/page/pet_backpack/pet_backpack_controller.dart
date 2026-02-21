import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dinosaur/page/pet_backpack/mock_data.dart';

/// 寵物背包頁面控制器
/// 
/// API 規劃（後端尚未建立，目前使用 mock）：
/// - GET /user/pets          取得使用者寵物列表
/// - GET /backpack?tag=food  取得背包內容（依 tag）
/// - POST /pets/{petId}/feed 餵食寵物 body: { "itemId": "xxx", "amount": 1 }
class PetBackpackController extends GetxController {
  final RxInt currentPetIndex = 0.obs;
  final RxList<Pet> pets = <Pet>[].obs;
  final RxList<FoodItem> foodItems = <FoodItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadMockData();
  }

  void _loadMockData() {
    pets.assignAll(mockPets.map((p) => Pet(
      id: p.id,
      name: p.name,
      level: p.level,
      assetPath: p.assetPath,
      birthplace: p.birthplace,
      species: p.species,
      hunger: p.hunger,
      maxHunger: p.maxHunger,
    )));
    
    foodItems.assignAll(mockFoodItems.map((f) => FoodItem(
      id: f.id,
      name: f.name,
      iconPath: f.iconPath,
      count: f.count,
      hungerRestore: f.hungerRestore,
    )));
  }

  Pet? get currentPet {
    if (pets.isEmpty) return null;
    return pets[currentPetIndex.value];
  }

  bool get canSwitchLeft => currentPetIndex.value > 0;
  bool get canSwitchRight => currentPetIndex.value < pets.length - 1;

  void switchPet(int index) {
    if (index >= 0 && index < pets.length) {
      currentPetIndex.value = index;
    }
  }

  void switchToPreviousPet() {
    if (canSwitchLeft) {
      currentPetIndex.value--;
    }
  }

  void switchToNextPet() {
    if (canSwitchRight) {
      currentPetIndex.value++;
    }
  }

  void feedPet(FoodItem item) {
    final pet = currentPet;
    if (pet == null) return;

    final foodIndex = foodItems.indexWhere((f) => f.id == item.id);
    if (foodIndex == -1 || foodItems[foodIndex].count <= 0) {
      Get.snackbar(
        '餵食失敗',
        '${item.name} 數量不足',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    foodItems[foodIndex] = foodItems[foodIndex].copyWith(
      count: foodItems[foodIndex].count - 1,
    );

    final newHunger = (pet.hunger + item.hungerRestore).clamp(0, pet.maxHunger);
    pets[currentPetIndex.value] = pet.copyWith(hunger: newHunger);

    Get.snackbar(
      '餵食成功',
      '${pet.name} 吃了 ${item.name}，飢餓值 +${item.hungerRestore}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 2),
    );
  }
}
