/// 寵物資料模型
class Pet {
  final String id;
  final String name;
  final int level;
  final String assetPath;
  final String birthplace;
  final String species;
  final int hunger;
  final int maxHunger;

  const Pet({
    required this.id,
    required this.name,
    required this.level,
    required this.assetPath,
    required this.birthplace,
    required this.species,
    required this.hunger,
    required this.maxHunger,
  });

  Pet copyWith({
    String? id,
    String? name,
    int? level,
    String? assetPath,
    String? birthplace,
    String? species,
    int? hunger,
    int? maxHunger,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      assetPath: assetPath ?? this.assetPath,
      birthplace: birthplace ?? this.birthplace,
      species: species ?? this.species,
      hunger: hunger ?? this.hunger,
      maxHunger: maxHunger ?? this.maxHunger,
    );
  }
}

/// 食物道具模型
class FoodItem {
  final String id;
  final String name;
  final String iconPath;
  final int count;
  final int hungerRestore;

  const FoodItem({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.count,
    required this.hungerRestore,
  });

  FoodItem copyWith({
    String? id,
    String? name,
    String? iconPath,
    int? count,
    int? hungerRestore,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      count: count ?? this.count,
      hungerRestore: hungerRestore ?? this.hungerRestore,
    );
  }
}

/// Mock 寵物列表
const List<Pet> mockPets = [
  Pet(
    id: 'pet-001',
    name: '小白',
    level: 5,
    assetPath: 'assets/svg/TestCute1.png',
    birthplace: '台北市',
    species: '暴龍',
    hunger: 30,
    maxHunger: 100,
  ),
  Pet(
    id: 'pet-002',
    name: '小黑',
    level: 3,
    assetPath: 'assets/svg/TestCute2.png',
    birthplace: '新北市',
    species: '翼龍',
    hunger: 60,
    maxHunger: 100,
  ),
];

/// Mock 食物列表
const List<FoodItem> mockFoodItems = [
  FoodItem(
    id: 'food-001',
    name: '蘋果',
    iconPath: 'assets/svg/TestCute1.png',
    count: 5,
    hungerRestore: 10,
  ),
  FoodItem(
    id: 'food-002',
    name: '魚乾',
    iconPath: 'assets/svg/TestCute2.png',
    count: 3,
    hungerRestore: 20,
  ),
  FoodItem(
    id: 'food-003',
    name: '肉骨頭',
    iconPath: 'assets/svg/TestCute1.png',
    count: 8,
    hungerRestore: 15,
  ),
  FoodItem(
    id: 'food-004',
    name: '牛奶',
    iconPath: 'assets/svg/TestCute2.png',
    count: 2,
    hungerRestore: 25,
  ),
  FoodItem(
    id: 'food-005',
    name: '餅乾',
    iconPath: 'assets/svg/TestCute1.png',
    count: 10,
    hungerRestore: 5,
  ),
  FoodItem(
    id: 'food-006',
    name: '罐頭',
    iconPath: 'assets/svg/TestCute2.png',
    count: 4,
    hungerRestore: 30,
  ),
  FoodItem(
    id: 'food-007',
    name: '起司',
    iconPath: 'assets/svg/TestCute1.png',
    count: 6,
    hungerRestore: 12,
  ),
  FoodItem(
    id: 'food-008',
    name: '雞肉',
    iconPath: 'assets/svg/TestCute2.png',
    count: 7,
    hungerRestore: 18,
  ),
];
