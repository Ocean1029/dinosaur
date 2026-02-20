import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:dinosaur/page/home/api_service.dart';
import 'package:dinosaur/page/home/point.dart';
import 'package:dinosaur/page/home/mock_data.dart';
import 'package:dinosaur/page/stats/stats_controller.dart';
import 'package:dinosaur/service/account_service.dart';
import 'package:dinosaur/service/service.dart';
import 'package:dinosaur/util/app_route.dart';
import 'package:dinosaur/util/app_colors.dart';

class HomeController extends GetxController {
  HomeController({
    ApiService? apiService,
    AccountService? accountService,
    Service? runCityService,
  })  : _apiService = apiService ?? Get.find<ApiService>(),
        _accountService = accountService ?? Get.find<AccountService>(),
        _runCityService = runCityService ?? Get.find<Service>();

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(25.033968, 121.564468),
    zoom: 12.5,
  );

  final RxBool isLoading = true.obs;
  final RxList<Point> points = <Point>[].obs;
  final RxList<Marker> markers = <Marker>[].obs;
  final RxList<Polyline> polylines = <Polyline>[].obs;
  final RxBool isTracking = false.obs;
  final RxList<LatLng> routePath = <LatLng>[].obs;
  final Rx<Duration> elapsed = Duration.zero.obs;
  final RxDouble totalDistanceMeters = 0.0.obs;
  final RxDouble averageSpeedKmh = 0.0.obs;
  final RxList<String> visitedPointIds = <String>[].obs;
  final RxnString errorMessage = RxnString();

  final Rxn<UserProfile> userProfile = Rxn<UserProfile>();
  final RxList<BadgeModel> badges = <BadgeModel>[].obs;
  final RxInt collectedBadgesCount = 0.obs; // 已收集的徽章數量
  final Rxn<BadgeModel> selectedBadge = Rxn<BadgeModel>();
  final RxBool isBadgePanelVisible = false.obs;
  static const int badgesPerPage = 3;
  final RxInt badgeStartIndex = 0.obs;

  final ApiService _apiService;
  final AccountService _accountService;
  final Service _runCityService;

  GoogleMapController? mapController;
  bool _isMapControllerDisposed = false; // 追蹤 mapController 是否已被 dispose
  StreamSubscription<Position>? _positionSubscription;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  BitmapDescriptor? _collectedMarkerIcon;
  BitmapDescriptor? _uncollectedMarkerIcon;
  BitmapDescriptor? _highlightMarkerIcon;
  final Map<String, BitmapDescriptor> _badgeMarkerIcons = {}; // 緩存徽章顏色的標記圖標
  LatLng? _initialUserLocation; // 存儲用戶初始位置
  LatLng? _currentUserLocation; // 當前用戶位置
  final RxBool isUserLocationCentered = true.obs; // 用戶位置是否在地圖中心
  CameraPosition? _lastCameraPosition; // 上次的相機位置

  // 路線記錄相關
  final List<TrackPoint> _pendingTrackPoints = <TrackPoint>[];
  String? _currentActivityId;
  bool _isSendingTrackPoints = false;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  @override
  void onClose() {
    _isMapControllerDisposed = true;
    mapController?.dispose();
    mapController = null;
    _stopTrackingStream();
    super.onClose();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // 先請求定位權限並獲取用戶當前位置
      await _requestLocationAndSetInitialPosition();

      // 並行載入地圖點位、用戶資料和徽章
      await Future.wait([
        _loadMapPoints(),
        _loadUserProfile(),
        _loadBadges(),
        _loadBadgeStats(),
      ]);
      await _updateMarkers();
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

  /// 請求定位權限並設置初始位置
  Future<void> _requestLocationAndSetInitialPosition() async {
    try {
      final granted = await _ensurePermissionReady();
      if (!granted) {
        // 如果權限被拒絕，使用默認位置
        return;
      }

      // 獲取用戶當前位置
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      _initialUserLocation = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      _currentUserLocation = _initialUserLocation;

      // 如果地圖控制器已經初始化，立即定位到用戶位置
      // 縮放級別 17 對應約兩三百公尺的視野寬度
      if (!_isMapControllerDisposed && mapController != null) {
        await _safeAnimateCamera(
          CameraUpdate.newLatLngZoom(_initialUserLocation!, 17),
        );
        isUserLocationCentered.value = true;
      }
    } catch (e) {
      // 如果獲取位置失敗，使用默認位置（不顯示錯誤，因為這不是必須的）
      print('無法獲取用戶位置：$e');
    }
  }

  Future<void> refresh() async {
    await loadData();
  }

  /// 載入地圖點位
  Future<void> _loadMapPoints() async {
    final account = _accountService.account;
    if (account == null) {
      // 如果用戶未登入，不載入點位
      points.clear();
      await _updateMarkers();
      return;
    }

    if (Service.useMockData) {
      points.assignAll(mockPoints);
      await _updateMarkers();
      return;
    }

    try {
      // 使用真實 API 獲取用戶的地圖點位
      final userLocations = await _apiService.fetchUserLocations(
        userId: account.id,
      );

      points.assignAll(userLocations);
      await _updateMarkers();
    } catch (e) {
      // 如果獲取失敗，記錄錯誤但不中斷流程
      debugPrint('載入地圖點位失敗: $e');
      points.clear();
      await _updateMarkers();
    }
  }

  Future<void> _loadUserProfile() async {
    final account = _accountService.account;
    if (account == null) {
      userProfile.value = null;
      return;
    }

    try {
      final data = await _runCityService.getUserProfile();
      userProfile.value = UserProfile(
        userId: data.userId,
        name: data.name,
        avatarUrl: data.avatarUrl,
        totalCoins: data.totalCoins,
        totalDistanceKm: (data.totalDistance ?? 0) / 1000,
        totalTimeSeconds: 5400,
        updatedAt: data.updatedAt,
      );
    } catch (_) {
      userProfile.value = UserProfile(
        userId: account.id,
        name: account.username,
        totalCoins: 0,
        totalDistanceKm: 0,
        totalTimeSeconds: 0,
      );
    }
  }

  /// 載入用戶徽章列表
  Future<void> _loadBadges() async {
    final account = _accountService.account;
    if (account == null) {
      badges.clear();
      selectedBadge.value = null;
      isBadgePanelVisible.value = false;
      badgeStartIndex.value = 0;
      return;
    }

    try {
      final userBadges = await _apiService.fetchUserBadges(userId: account.id);
      badges.assignAll(userBadges);

      // 預設不選取任何徽章
      selectedBadge.value = null;

      _resetBadgeStartIndex();
    } catch (e) {
      debugPrint('載入徽章失敗: $e');
      badges.clear();
      selectedBadge.value = null;
      isBadgePanelVisible.value = false;
      badgeStartIndex.value = 0;
    }
  }

  /// 載入用戶徽章統計（已收集數量）
  Future<void> _loadBadgeStats() async {
    final account = _accountService.account;
    if (account == null) {
      collectedBadgesCount.value = 0;
      return;
    }

    try {
      final stats = await _apiService.fetchUserBadgeStats(userId: account.id);
      collectedBadgesCount.value = stats.collectedCount;
    } catch (e) {
      debugPrint('載入徽章統計失敗: $e');
      collectedBadgesCount.value = 0;
    }
  }

  void onMapCreated(GoogleMapController controller) {
    if (_isMapControllerDisposed) {
      // 如果已經被 dispose，立即 dispose 新的 controller
      controller.dispose();
      return;
    }
    mapController = controller;
    _isMapControllerDisposed = false;

    // 如果已經獲取了用戶位置，立即定位到用戶位置
    // 縮放級別 17 對應約兩三百公尺的視野寬度
    if (_initialUserLocation != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_initialUserLocation!, 17),
      );
      isUserLocationCentered.value = true;
    }
  }

  /// 安全地使用 mapController，檢查是否已被 dispose
  Future<void> _safeAnimateCamera(CameraUpdate update) async {
    if (_isMapControllerDisposed || mapController == null) {
      return;
    }
    try {
      await mapController!.animateCamera(update);
    } catch (e) {
      // 如果 controller 已被 dispose，忽略錯誤
      if (e.toString().contains('disposed') || e.toString().contains('Bad state')) {
        debugPrint('MapController was disposed during animation: $e');
        _isMapControllerDisposed = true;
        mapController = null;
      } else {
        rethrow;
      }
    }
  }

  /// 安全地使用 mapController（不等待完成），檢查是否已被 dispose
  void _safeAnimateCameraSync(CameraUpdate update) {
    if (_isMapControllerDisposed || mapController == null) {
      return;
    }
    try {
      mapController!.animateCamera(update);
    } catch (e) {
      // 如果 controller 已被 dispose，忽略錯誤
      if (e.toString().contains('disposed') || e.toString().contains('Bad state')) {
        debugPrint('MapController was disposed during animation: $e');
        _isMapControllerDisposed = true;
        mapController = null;
      }
    }
  }

  /// 處理地圖相機移動
  void onCameraMove(CameraPosition position) {
    _lastCameraPosition = position;
    // 實時檢查地圖中心是否與用戶位置一致
    _checkIfUserLocationCentered();
  }

  /// 處理地圖相機移動完成（停止）
  void onCameraIdle() {
    // 地圖停止移動時再次確認狀態
    if (_lastCameraPosition != null) {
      _checkIfUserLocationCentered();
    }
  }

  /// 檢查用戶位置是否在地圖中心
  void _checkIfUserLocationCentered() {
    if (_currentUserLocation == null || _lastCameraPosition == null) {
      return;
    }

    final cameraCenter = _lastCameraPosition!.target;
    final userLocation = _currentUserLocation!;

    // 計算距離（米）
    final distance = Geolocator.distanceBetween(
      cameraCenter.latitude,
      cameraCenter.longitude,
      userLocation.latitude,
      userLocation.longitude,
    );

    // 如果距離小於 50 米，認為是居中的
    final threshold = 50.0; // 50 米
    final isCentered = distance < threshold;

    // 只在狀態改變時更新，避免不必要的重建
    if (isUserLocationCentered.value != isCentered) {
      isUserLocationCentered.value = isCentered;
    }
  }

  /// 將地圖移動到用戶當前位置
  Future<void> centerToUserLocation() async {
    if (_isMapControllerDisposed || mapController == null) {
      return;
    }

    // 總是重新獲取用戶當前位置
    try {
      final granted = await _ensurePermissionReady();
      if (!granted) {
        Get.snackbar(
          '無法定位',
          '需要定位權限才能使用此功能',
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          backgroundColor: Colors.black87,
        );
        return;
      }

      // 獲取最新的用戶當前位置
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final newUserLocation = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );

      // 更新當前用戶位置
      _currentUserLocation = newUserLocation;

      // 移動地圖到用戶最新位置
      // 縮放級別 17 對應約兩三百公尺的視野寬度
      await _safeAnimateCamera(
        CameraUpdate.newLatLngZoom(newUserLocation, 17),
      );

      // 更新相機位置記錄，以便後續檢查
      _lastCameraPosition = CameraPosition(
        target: newUserLocation,
        zoom: 17,
      );
      // 地圖移動過程中，onCameraMove 會持續檢查並更新狀態
      // 當移動完成時，onCameraIdle 會最終確認狀態
    } catch (e) {
      Get.snackbar(
        '無法獲取位置',
        '請檢查定位服務是否開啟',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
    }
  }

  void selectBadge(BadgeModel? badge) {
    if (badge == null) {
      selectedBadge.value = null;
      debugPrint('選中的徽章已清除');
    } else if (selectedBadge.value?.id == badge.id) {
      selectedBadge.value = null;
      debugPrint('取消選中徽章: ${badge.name}');
    } else {
      selectedBadge.value = badge;
      // 記錄選中徽章的顏色資訊
      debugPrint('========== 選中徽章顏色資訊 ==========');
      debugPrint('徽章名稱: ${badge.name}');
      debugPrint('徽章ID: ${badge.badgeId}');
      debugPrint('徽章顏色 (badgeColor): ${badge.badgeColor}');
      if (badge.badgeColor != null) {
        debugPrint('顏色值 (value): ${badge.badgeColor!.value}');
        debugPrint('顏色hex: #${badge.badgeColor!.value.toRadixString(16).substring(2).toUpperCase()}');
        debugPrint('顏色RGB: R=${badge.badgeColor!.red}, G=${badge.badgeColor!.green}, B=${badge.badgeColor!.blue}');
      } else {
        debugPrint('⚠️ 徽章顏色為 null（未從數據庫獲取到顏色）');
      }
      debugPrint('=====================================');
      // 聚焦到該徽章的所有地點
      _focusOnBadgeLocations(badge);
    }
    _ensureBadgeVisible(selectedBadge.value);
    _updateMarkers();
  }

  /// 聚焦到徽章的所有地點
  Future<void> _focusOnBadgeLocations(BadgeModel badge) async {
    debugPrint('開始聚焦徽章: ${badge.name}, badgeId: ${badge.badgeId}');
    debugPrint('徽章的 requiredLocationIds: ${badge.requiredLocationIds}');
    debugPrint('當前地圖點位數量: ${points.length}');
    debugPrint('mapController 是否為 null: ${mapController == null}');

    if (mapController == null) {
      debugPrint('mapController 為 null，無法聚焦');
      return;
    }

    // 如果徽章沒有 requiredLocationIds，嘗試從徽章詳情 API 獲取
    List<String>? locationIds = badge.requiredLocationIds;
    if (locationIds == null || locationIds.isEmpty) {
      debugPrint('徽章沒有 requiredLocationIds，嘗試從徽章詳情 API 獲取');
      try {
        final account = _accountService.account;
        if (account != null) {
          final badgeDetail = await _apiService.fetchUserBadgeDetail(
            userId: account.id,
            badgeId: badge.badgeId,
          );
          locationIds = badgeDetail.requiredLocations
              .map((loc) => loc.locationId)
              .toList();
          debugPrint('從徽章詳情 API 獲取的 locationIds: $locationIds');
          
          // 更新徽章的 requiredLocationIds
          final updatedBadge = badge.copyWith(requiredLocationIds: locationIds);
          final badgeIndex = badges.indexWhere((b) => b.badgeId == badge.badgeId);
          if (badgeIndex != -1) {
            badges[badgeIndex] = updatedBadge;
            selectedBadge.value = updatedBadge;
          }
        }
      } catch (e) {
        debugPrint('獲取徽章詳情失敗: $e');
        return;
      }
    }

    if (locationIds == null || locationIds.isEmpty) {
      debugPrint('徽章沒有 requiredLocationIds，無法聚焦');
      return;
    }

    // 收集該徽章的所有地點的 LatLng
    final badgeLocations = <LatLng>[];
    for (final locId in locationIds) {
      try {
        final point = points.firstWhere((p) => p.id == locId);
        badgeLocations.add(point.location);
        debugPrint('找到點位: $locId -> ${point.name} (${point.location.latitude}, ${point.location.longitude})');
      } catch (e) {
        // 如果找不到點位，跳過
        debugPrint('徽章點位 ID "$locId" 在地圖點位中找不到');
      }
    }

    debugPrint('找到的徽章地點數量: ${badgeLocations.length}');

    if (badgeLocations.isEmpty) {
      debugPrint('沒有找到任何徽章地點，無法聚焦');
      return;
    }

    // 計算邊界
    double minLat = badgeLocations.first.latitude;
    double maxLat = badgeLocations.first.latitude;
    double minLng = badgeLocations.first.longitude;
    double maxLng = badgeLocations.first.longitude;

    for (final location in badgeLocations) {
      minLat = minLat < location.latitude ? minLat : location.latitude;
      maxLat = maxLat > location.latitude ? maxLat : location.latitude;
      minLng = minLng < location.longitude ? minLng : location.longitude;
      maxLng = maxLng > location.longitude ? maxLng : location.longitude;
    }

    debugPrint('計算的邊界: minLat=$minLat, maxLat=$maxLat, minLng=$minLng, maxLng=$maxLng');

    // 添加一些邊距，確保所有地點都能完整顯示
    const padding = 0.002; // 約 200 公尺的邊距
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    debugPrint('準備移動地圖到邊界: southwest=${bounds.southwest}, northeast=${bounds.northeast}');

    // 動畫移動地圖到該區域
    try {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0), // 100px 的內邊距
      );
      debugPrint('地圖聚焦成功');
    } catch (e) {
      debugPrint('地圖聚焦失敗: $e');
    }
  }

  void toggleBadgePanel() {
    // 無論有無徽章都可開關選單（無徽章時顯示空狀態）
    isBadgePanelVisible.toggle();
  }

  void closeBadgePanel() {
    if (isBadgePanelVisible.value) {
      isBadgePanelVisible.value = false;
    }
  }

  List<BadgeModel> get sortedBadges {
    final sorted = badges.toList();
    // 根據狀態排序：進行中 > 已收集 > 未解鎖
    sorted.sort((a, b) {
      final statusOrder = {
        BadgeStatus.inProgress: 0,
        BadgeStatus.collected: 1,
        BadgeStatus.locked: 2,
      };
      final aOrder = statusOrder[a.status] ?? 3;
      final bOrder = statusOrder[b.status] ?? 3;
      return aOrder.compareTo(bOrder);
    });
    return sorted;
  }

  Future<void> updatePointCollected(String id, bool collected) async {
    final index = points.indexWhere((point) => point.id == id);
    if (index == -1) {
      return;
    }
    points[index] = points[index].copyWith(
      collected: collected,
      collectedAt:
          collected ? (points[index].collectedAt ?? DateTime.now()) : null,
    );
    // 重新載入徽章以更新進度
    _loadBadges();
    await _updateMarkers();
  }

  Future<void> startTracking() async {
    if (isTracking.value) {
      return;
    }

    final granted = await _ensurePermissionReady();
    if (!granted) {
      return;
    }

    final userId = _accountService.account?.id;
    if (userId == null) {
      Get.snackbar(
        '無法開始紀錄',
        '尚未取得使用者資訊，請重新登入後再試',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
      return;
    }

    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final currentLatLng = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );

      routePath.clear();
      polylines.clear();
      visitedPointIds.clear();
      totalDistanceMeters.value = 0;
      averageSpeedKmh.value = 0;
      elapsed.value = Duration.zero;
      _pendingTrackPoints.clear();

      final session = await _apiService.startActivity(
        userId: userId,
        startTime: DateTime.now().toUtc(),
        startLocation: currentLatLng,
      );
      _currentActivityId = session.activityId;

      isTracking.value = true;
      _stopwatch
        ..reset()
        ..start();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsed.value = _stopwatch.elapsed;
        if (_stopwatch.elapsed.inSeconds > 0) {
          final hours = _stopwatch.elapsed.inSeconds / 3600;
          averageSpeedKmh.value =
              hours > 0 ? (totalDistanceMeters.value / 1000) / hours : 0;
        }
      });

      final locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      );

      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(_onPositionUpdated);

      _onPositionUpdated(currentPosition);
      await _flushTrackPoints(force: true);
    } on PlatformException catch (e) {
      // 處理定位相關的 PlatformException（必須在 ApiException 之前）
      debugPrint('HomeController.startTracking PlatformException: $e');
      String errorMessage = '定位服務錯誤';
      if (e.code == 'PERMISSION_DENIED') {
        errorMessage = '定位權限被拒絕，請在設定中開啟定位權限';
      } else if (e.code == 'LOCATION_SERVICE_DISABLED') {
        errorMessage = '定位服務未開啟，請開啟定位服務';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      Get.snackbar(
        '無法開始紀錄',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      );
    } on ApiException catch (error) {
      debugPrint('HomeController.startTracking API error: $error');
      Get.snackbar(
        '無法開始紀錄',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 4),
      );
    } catch (error) {
      debugPrint('HomeController.startTracking error: $error');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrint('Error stack: ${StackTrace.current}');
      
      // 根據錯誤類型顯示更詳細的錯誤信息
      String errorMessage = '請稍後再試';
      if (error.toString().contains('timeout') || error.toString().contains('Timeout')) {
        errorMessage = '請求超時，請檢查網路連接';
      } else if (error.toString().contains('network') || error.toString().contains('Network')) {
        errorMessage = '網路連接失敗，請檢查網路設定';
      } else if (error.toString().contains('location') || error.toString().contains('Location')) {
        errorMessage = '無法獲取位置資訊，請檢查定位權限和 GPS 訊號';
      } else {
        errorMessage = '發生錯誤：${error.toString().split('\n').first}';
      }
      
      Get.snackbar(
        '無法開始紀錄',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> stopTracking() async {
    if (!isTracking.value) {
      return;
    }

    isTracking.value = false;
    _stopwatch.stop();
    _timer?.cancel();
    _stopTrackingStream();

    final userId = _accountService.account?.id;
    final activityId = _currentActivityId;
    final endPoint = routePath.isNotEmpty ? routePath.last : null;

    await _flushTrackPoints(force: true);
    _pendingTrackPoints.clear();

    if (userId != null && activityId != null && endPoint != null) {
      try {
        final summary = await _apiService.endActivity(
          userId: userId,
          activityId: activityId,
          endTime: DateTime.now().toUtc(),
          endLocation: endPoint,
        );

        totalDistanceMeters.value = summary.distanceKm * 1000;
        elapsed.value = Duration(seconds: summary.durationSeconds);
        averageSpeedKmh.value = summary.averageSpeedKmh;
        visitedPointIds.assignAll(
          summary.collectedLocations.map((Point point) => point.id),
        );
        _applyCollectedLocations(summary.collectedLocations);
        await _loadBadges();

        // 活動結束後，刷新用戶資料和徽章統計以更新金幣和徽章數量
        await Future.wait([
          _loadUserProfile(),
          _loadBadgeStats(),
        ]);
        
        // 先跳轉到「個人資訊」頁面，然後再跳轉到「運動紀錄詳細畫面」
        // 這樣返回時會先回到「個人資訊」頁面，再返回會回到「跑城市」頁面
        // 手動註冊 Controller 確保它存在，然後跳轉
        if (!Get.isRegistered<StatsController>()) {
          Get.put(StatsController());
        }
        Get.toNamed(AppRoute.stats);
        // 使用 Future.microtask 確保路由跳轉完成後再跳轉到下一個頁面
        Future.microtask(() {
          Get.toNamed(
            AppRoute.activityDetail,
            arguments: {
              'activityId': activityId,
              'userId': userId,
            },
          );
        });
      } on ApiException catch (error) {
        Get.snackbar(
          '結束紀錄失敗',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          backgroundColor: Colors.black87,
        );
        elapsed.value = _stopwatch.elapsed;
      } catch (error) {
        debugPrint('HomeController.stopTracking error: $error');
        Get.snackbar(
          '結束紀錄失敗',
          '請稍後再試',
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          backgroundColor: Colors.black87,
        );
        elapsed.value = _stopwatch.elapsed;
      }
    } else {
      elapsed.value = _stopwatch.elapsed;
      if (_stopwatch.elapsed.inSeconds > 0) {
        final hours = _stopwatch.elapsed.inSeconds / 3600;
        averageSpeedKmh.value =
            hours > 0 ? (totalDistanceMeters.value / 1000) / hours : 0;
      }
    }

    _currentActivityId = null;
  }

  void clearRoute() {
    if (isTracking.value) {
      return;
    }
    routePath.clear();
    polylines.clear();
    visitedPointIds.clear();
    totalDistanceMeters.value = 0;
    averageSpeedKmh.value = 0;
    elapsed.value = Duration.zero;
    _pendingTrackPoints.clear();
    _currentActivityId = null;
  }

  Future<bool> _ensurePermissionReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        '無法開始紀錄',
        '請開啟定位服務後再試一次',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      Get.snackbar(
        '定位權限遭拒',
        '需要定位權限才能紀錄跑步路線',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        '定位權限永久被拒',
        '請前往系統設定開啟定位權限',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
      return false;
    }

    return true;
  }

  void _onPositionUpdated(Position position) {
    final currentPoint = LatLng(position.latitude, position.longitude);
    _currentUserLocation = currentPoint; // 更新當前用戶位置
    _checkIfUserLocationCentered(); // 檢查是否居中

    final trackPoint = TrackPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      accuracy: position.accuracy,
    );
    _pendingTrackPoints.add(trackPoint);

    if (routePath.isEmpty) {
      routePath.add(currentPoint);
      _updatePolyline();
      // 縮放級別 17 對應約兩三百公尺的視野寬度
      _safeAnimateCameraSync(
        CameraUpdate.newLatLngZoom(currentPoint, 17),
      );
      _markVisitedPoints(currentPoint);
      return;
    }

    final last = routePath.last;
    final segmentDistance = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      currentPoint.latitude,
      currentPoint.longitude,
    );

    if (segmentDistance < 3) {
      return;
    }

    routePath.add(currentPoint);
    totalDistanceMeters.value += segmentDistance;
    _updatePolyline();
    _markVisitedPoints(currentPoint);
    // 徽章進度會在活動結束後統一更新

    if (isTracking.value) {
      _safeAnimateCameraSync(CameraUpdate.newLatLng(currentPoint));
    }

    _flushTrackPoints();
  }

  void _updatePolyline() {
    if (routePath.length < 2) {
      polylines.assignAll([]);
      return;
    }

    polylines.assignAll([
      Polyline(
        polylineId: const PolylineId('run-city-route'),
        points: routePath.toList(),
        color: const Color(0xFF5AB4C5),
        width: 6,
      ),
    ]);
  }

  void _markVisitedPoints(LatLng currentPoint) {
    final newlyVisitedIds = <String>[];
    for (final point in points) {
      if (visitedPointIds.contains(point.id)) {
        continue;
      }

      final distance = Geolocator.distanceBetween(
        point.location.latitude,
        point.location.longitude,
        currentPoint.latitude,
        currentPoint.longitude,
      );

      if (distance <= 60) {
        newlyVisitedIds.add(point.id);
      }
    }

    if (newlyVisitedIds.isEmpty) {
      return;
    }

    visitedPointIds.addAll(newlyVisitedIds);
  }



  void _stopTrackingStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _flushTrackPoints({bool force = false}) async {
    if (_isSendingTrackPoints) {
      return;
    }
    if (_currentActivityId == null) {
      return;
    }
    if (_pendingTrackPoints.isEmpty) {
      return;
    }
    if (!force && _pendingTrackPoints.length < 5) {
      return;
    }

    final userId = _accountService.account?.id;
    if (userId == null) {
      return;
    }

    final pointsToSend = List<TrackPoint>.from(_pendingTrackPoints);
    _isSendingTrackPoints = true;
    try {
      final distance = await _apiService.trackActivity(
        userId: userId,
        activityId: _currentActivityId!,
        points: pointsToSend,
      );
      // 更新已行走距離（後端返回的距離，單位：公尺）
      if (distance > 0) {
        totalDistanceMeters.value = distance;
      }
      if (_pendingTrackPoints.length >= pointsToSend.length) {
        _pendingTrackPoints.removeRange(0, pointsToSend.length);
      } else {
        _pendingTrackPoints.clear();
      }
    } on ApiException catch (error) {
      debugPrint(
          'HomeController._flushTrackPoints API error: ${error.message}');
    } catch (error) {
      debugPrint('HomeController._flushTrackPoints error: $error');
    } finally {
      _isSendingTrackPoints = false;
    }
  }

  void _applyCollectedLocations(List<Point> collected) {
    if (collected.isEmpty) {
      return;
    }
    final collectedMap = {
      for (final point in collected) point.id: point,
    };

    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final updated = collectedMap[current.id];
      if (updated != null) {
        points[i] = current.copyWith(
          collected: true,
          collectedAt: updated.collectedAt ?? DateTime.now(),
          coinsEarned: updated.coinsEarned,
        );
      }
    }

    // 重新載入徽章以更新進度
    _loadBadges();
    _updateMarkers();
  }

  /// 獲取或創建徽章顏色的標記圖標
  Future<BitmapDescriptor> _getBadgeMarkerIcon(Color badgeColor) async {
    final colorKey = badgeColor.value.toString();
    if (_badgeMarkerIcons.containsKey(colorKey)) {
      return _badgeMarkerIcons[colorKey]!;
    }
    final icon = await _createCircleMarker(badgeColor);
    _badgeMarkerIcons[colorKey] = icon;
    return icon;
  }

  Future<void> _ensureMarkerIcons() async {
    _collectedMarkerIcon ??= await _createCircleMarker(const Color(0xFFDBF1F5));
    _uncollectedMarkerIcon ??=
        await _createCircleMarker(const Color(0xFF5AB4C5));
    _highlightMarkerIcon ??= await _createCircleMarker(const Color(0xFF4CAF50));
  }

  Future<BitmapDescriptor> _createCircleMarker(Color fillColor) async {
    const double size = 68;
    const double borderWidth = 5;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    final ui.Paint borderPaint = ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.fill;
    final ui.Paint fillPaint = ui.Paint()
      ..color = fillColor
      ..style = ui.PaintingStyle.fill;

    const ui.Offset center = ui.Offset(size / 2, size / 2);
    const double radius = size / 2;

    canvas.drawCircle(center, radius, borderPaint);
    canvas.drawCircle(center, radius - borderWidth, fillPaint);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _updateMarkers() async {
    await _ensureMarkerIcons();
    final collectedIcon = _collectedMarkerIcon;
    final uncollectedIcon = _uncollectedMarkerIcon;

    if (collectedIcon == null || uncollectedIcon == null) {
      return;
    }

    // 如果有選取的徽章，獲取該徽章未收集的點位 ID
    final selectedBadgeValue = selectedBadge.value;
    final highlightIds = <String>{};
    
    if (selectedBadgeValue != null && selectedBadgeValue.requiredLocationIds != null) {
      for (final locId in selectedBadgeValue.requiredLocationIds!) {
        // 檢查該點位是否存在於地圖點位中
        try {
          final point = points.firstWhere((p) => p.id == locId);
          // 只標記未收集的點位
          if (!point.collected) {
            highlightIds.add(locId);
          }
        } catch (e) {
          // 如果找不到點位，記錄調試信息
          debugPrint('徽章點位 ID "$locId" 在地圖點位中找不到');
        }
      }
    }

    // 如果有選取的徽章，獲取徽章的顏色
    Color? badgeColor;
    if (selectedBadgeValue != null) {
      badgeColor = selectedBadgeValue.badgeColor;
    }

    final nextMarkers = <Marker>[];
    for (final point in points) {
      final statusLabel = point.collected ? '已收集' : '待收集';
      final subtitle = (point.area?.isNotEmpty ?? false)
          ? '${point.area} · $statusLabel'
          : statusLabel;
      final isHighlight = highlightIds.contains(point.id);
      
      // 如果有選取的徽章且該點未收集，使用徽章顏色
      BitmapDescriptor markerIcon;
      if (isHighlight && badgeColor != null && !point.collected) {
        // 使用徽章顏色的標記圖標
        markerIcon = await _getBadgeMarkerIcon(badgeColor);
      } else if (point.collected) {
        markerIcon = collectedIcon;
      } else {
        markerIcon = uncollectedIcon;
      }
      
      nextMarkers.add(Marker(
        markerId: MarkerId(point.id),
        position: point.location,
        infoWindow: InfoWindow(
          title: point.name,
          snippet: subtitle,
        ),
        icon: markerIcon,
        anchor: const Offset(0.5, 0.5),
        zIndex: isHighlight
            ? 4
            : point.collected
                ? 3
                : 2,
      ));
    }

    markers.assignAll(nextMarkers);
  }

  List<BadgeModel?> get currentBadgeSlots {
    if (badges.isEmpty) {
      return List<BadgeModel?>.filled(badgesPerPage, null);
    }
    final start = badgeStartIndex.value.clamp(0, _maxBadgeStartIndex);
    final items = <BadgeModel?>[];
    for (var i = 0; i < badgesPerPage; i++) {
      final index = start + i;
      items.add(index < badges.length ? badges[index] : null);
    }
    return items;
  }

  bool get canPageBadgesLeft => badgeStartIndex.value > 0;
  bool get canPageBadgesRight => badgeStartIndex.value < _maxBadgeStartIndex;

  void pageBadgesLeft() {
    if (!canPageBadgesLeft) {
      return;
    }
    badgeStartIndex.value =
        (badgeStartIndex.value - 1).clamp(0, _maxBadgeStartIndex);
  }

  void pageBadgesRight() {
    if (!canPageBadgesRight) {
      return;
    }
    badgeStartIndex.value =
        (badgeStartIndex.value + 1).clamp(0, _maxBadgeStartIndex);
  }

  int get _maxBadgeStartIndex {
    if (badges.length <= badgesPerPage) {
      return 0;
    }
    return badges.length - badgesPerPage;
  }

  void _resetBadgeStartIndex() {
    if (badges.length <= badgesPerPage) {
      badgeStartIndex.value = 0;
      return;
    }
    final middleStart = ((badges.length - badgesPerPage) / 2).floor();
    badgeStartIndex.value = middleStart.clamp(0, _maxBadgeStartIndex);
  }

  void _ensureBadgeVisible(BadgeModel? badge) {
    if (badge == null) {
      return;
    }
    final index = badges.indexWhere((element) => element.id == badge.id);
    if (index == -1) {
      return;
    }
    final start = badgeStartIndex.value;
    final end = start + badgesPerPage - 1;

    if (index < start) {
      badgeStartIndex.value = index.clamp(0, _maxBadgeStartIndex);
    } else if (index > end) {
      badgeStartIndex.value =
          (index - badgesPerPage + 1).clamp(0, _maxBadgeStartIndex);
    }
  }

  /// 處理 NFC 收集（從 URL Scheme 觸發）
  Future<void> handleNfcCollection(String nfcId) async {
    // 1. 檢查用戶是否登入
    final userId = _accountService.account?.id;
    if (userId == null) {
      Get.snackbar(
        '請先登入',
        '請先登入以使用此功能',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }

    // 2. 檢查是否有活動
    if (_currentActivityId == null || !isTracking.value) {
      Get.snackbar(
        '請先開始跑步活動',
        '請先開始跑步活動才能收集地點',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.orange,
      );
      return;
    }

    // 3. 從已載入的點位中查找對應的地點名稱
    String? locationName;
    try {
      final location = points.firstWhere((point) => point.nfcId == nfcId);
      locationName = location.name;
    } catch (e) {
      // 如果找不到，使用 nfcId 作為臨時名稱
      locationName = nfcId;
    }

    // 4. 顯示收集對話框
    await _showNfcCollectionDialog(nfcId, locationName, userId, _currentActivityId!);
  }

  /// 顯示 NFC 收集對話框
  Future<void> _showNfcCollectionDialog(
    String nfcId,
    String locationName,
    String userId,
    String activityId,
  ) async {
    bool isCollecting = false;
    String? errorMessage;

    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "收集成功!" 文字
                  const Text(
                    '收集成功!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 勾選圖標
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 地點名稱
                  Text(
                    locationName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // 錯誤訊息
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  // 確認收集按鈕
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isCollecting
                          ? null
                          : () async {
                              setState(() {
                                isCollecting = true;
                                errorMessage = null;
                              });

                              try {
                                final response = await _apiService.collectNfcLocation(
                                  userId: userId,
                                  activityId: activityId,
                                  nfcId: nfcId,
                                );

                                if (response['success'] == true) {
                                  final data = response['data'] as Map<String, dynamic>;
                                  final collectedLocationName = data['name'] as String? ?? locationName;

                                  // 更新點位狀態
                                  await _refreshCollectedLocation(nfcId);

                                  // 關閉對話框
                                  Get.back();

                                  // 顯示成功提示
                                  Get.snackbar(
                                    '收集成功',
                                    '已收集：$collectedLocationName',
                                    snackPosition: SnackPosition.BOTTOM,
                                    colorText: Colors.white,
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  );
                                } else {
                                  setState(() {
                                    isCollecting = false;
                                    errorMessage = '收集失敗，請稍後再試';
                                  });
                                }
                              } on ApiException catch (e) {
                                setState(() {
                                  isCollecting = false;
                                  if (e.statusCode == 404) {
                                    errorMessage = '找不到該地點';
                                  } else if (e.code == 'NETWORK_ERROR' || e.code == 'CONNECTION_ERROR') {
                                    errorMessage = '網路連接失敗\n請檢查：\n1. 後端伺服器是否運行\n2. 網路連接是否正常';
                                  } else if (e.code == 'TIMEOUT') {
                                    errorMessage = '請求超時\n請檢查網路連接';
                                  } else {
                                    errorMessage = e.message;
                                  }
                                });
                              } catch (e) {
                                setState(() {
                                  isCollecting = false;
                                  errorMessage = '收集失敗：${e.toString()}';
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isCollecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              '確認收集',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// 刷新已收集的地點狀態
  Future<void> _refreshCollectedLocation(String nfcId) async {
    try {
      // 重新載入地圖點位以更新收集狀態
      await _loadMapPoints();
    } catch (e) {
      debugPrint('刷新地點狀態失敗: $e');
    }
  }
}
