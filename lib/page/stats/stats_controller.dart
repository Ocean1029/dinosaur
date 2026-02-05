import 'package:get/get.dart';
import 'package:dinosaur/model/models.dart';
import 'package:dinosaur/model/user_data.dart' as api_models;
import 'package:dinosaur/page/home/api_service.dart';
import 'package:dinosaur/page/home/point.dart';
import 'package:flutter/foundation.dart';
import 'package:dinosaur/service/account_service.dart';
import 'package:dinosaur/service/service.dart';

class StatsController extends GetxController {
  final Service _runCityService = Get.find<Service>();
  final ApiService _apiService = Get.find<ApiService>();
  final AccountService _accountService = Get.find<AccountService>();

  final RxBool isLoading = false.obs;
  final Rxn<api_models.UserProfile> userData = Rxn<api_models.UserProfile>();
  final RxList<ActivityItem> activities = <ActivityItem>[].obs;
  final RxList<BadgeModel> badges = <BadgeModel>[].obs;
  final RxBool areBadgesExpanded = false.obs;
  final RxList<Point> badgePointsSource = <Point>[].obs;
  final RxnString errorMessage = RxnString();

  /// 計算總時間（從活動列表中累加，單位：秒）
  int get totalTimeSeconds {
    return activities.fold<int>(0, (sum, activity) => sum + activity.duration);
  }

  /// 格式化總時間
  String get formattedTotalTime {
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours} 時 ${minutes} 分';
    }
    return '${minutes} 分';
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// 載入用戶資料和活動列表
  Future<void> loadData() async {
    // 檢查用戶是否已登入
    if (_accountService.account == null) {
      errorMessage.value = '請先登入以使用此功能';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final userId = _accountService.account!.id;
      // 並行載入用戶資料和活動列表
      await Future.wait([
        _loadUserProfile(),
        _loadActivities(userId),
        _loadBadges(userId),
      ]);
    } on ApiException catch (e) {
      // 處理 API 錯誤
      final errorText = e.code != null ? '${e.message} (${e.code})' : e.message;
      errorMessage.value = errorText;
    } catch (e) {
      errorMessage.value = '載入資料失敗：${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// 載入用戶資料
  Future<void> _loadUserProfile() async {
    final data = await _runCityService.getUserProfile();
    userData.value = data;
  }

  /// 載入活動列表（獲取所有記錄）
  Future<void> _loadActivities(String userId) async {
    // 後端 API 最大 limit 為 100，需要分頁加載所有記錄
    final allItems = <ActivityItem>[];
    int currentPage = 1;
    const limit = 100; // 後端允許的最大值
    bool hasMore = true;
    
    while (hasMore) {
      final items = await _apiService.fetchActivities(
        userId: userId,
        page: currentPage,
        limit: limit,
      );
      
      allItems.addAll(items);
      
      // 如果返回的記錄數少於 limit，說明已經是最後一頁
      if (items.length < limit) {
        hasMore = false;
      } else {
        currentPage++;
      }
    }
    
    activities.assignAll(allItems);
  }

  Future<void> _loadBadges(String userId) async {
    try {
      final userBadges = await _apiService.fetchUserBadges(userId: userId);
      // 根據狀態排序：進行中 > 已收集 > 未解鎖
      userBadges.sort((a, b) {
        final statusOrder = {
          BadgeStatus.inProgress: 0,
          BadgeStatus.collected: 1,
          BadgeStatus.locked: 2,
        };
        final aOrder = statusOrder[a.status] ?? 3;
        final bOrder = statusOrder[b.status] ?? 3;
        return aOrder.compareTo(bOrder);
      });
      badges.assignAll(userBadges);
      areBadgesExpanded.value = false;
    } catch (e) {
      if (kDebugMode) {
        print('載入徽章失敗: $e');
      }
      badges.clear();
    }
  }

  /// 刷新資料
  Future<void> refresh() async {
    await loadData();
  }

  void toggleBadgeExpansion() {
    if (badges.length <= 3) {
      return;
    }
    areBadgesExpanded.toggle();
  }
}

