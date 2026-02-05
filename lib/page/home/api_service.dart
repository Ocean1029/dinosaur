import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dinosaur/page/home/point.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() {
    if (code != null) {
      return '[$code] $message';
    }
    return 'ApiException(statusCode: $statusCode, message: $message)';
  }
}

class ApiService extends GetxService {
  static bool get useMockData {
    // 優先從 .env 讀取，如果沒有則從環境變數讀取
    final envValue = dotenv.env['RUN_CITY_USE_MOCK_DATA'];
    if (envValue != null) {
      return envValue.toLowerCase() == 'true';
    }
    return const bool.fromEnvironment(
      'RUN_CITY_USE_MOCK_DATA',
      defaultValue: false,
    );
  }

  ApiService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ??
            dotenv.env['RUN_CITY_API_BASE_URL'] ??
            const String.fromEnvironment(
              'RUN_CITY_API_BASE_URL',
              defaultValue: 'https://run-city-424370484311.asia-east1.run.app', // 部署的後端 API 網址
            );

  final http.Client _httpClient;
  final String baseUrl;

  @override
  void onClose() {
    _httpClient.close();
    super.onClose();
  }

  Future<List<Point>> fetchLocations({
    String? badge,
    int? page,
    int? limit,
  }) async {
    final response = await _get(
      '/api/locations',
      queryParameters: <String, String>{
        if (badge != null) 'badge': badge,
        if (page != null) 'page': '$page',
        if (limit != null) 'limit': '$limit',
      },
    );

    final data = response['data'] as List<dynamic>? ?? <dynamic>[];
    return data
        .map(
          (dynamic json) =>
              Point.fromUserMapJson(json as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<List<Point>> fetchUserLocations({
    required String userId,
    String? badge,
    String? bounds,
  }) async {
    final response = await _get(
      '/api/users/$userId/map',
      queryParameters: <String, String>{
        if (badge != null) 'badge': badge,
        if (bounds != null) 'bounds': bounds,
      },
    );

    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final locations = data['locations'] as List<dynamic>? ?? <dynamic>[];
    return locations
        .map(
          (dynamic json) =>
              Point.fromUserMapJson(json as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<Point> createLocation({
    required String name,
    required double latitude,
    required double longitude,
    String? description,
    bool isNFCEnabled = false,
    String? nfcId,
  }) async {
    final response = await _post(
      '/api/locations',
      body: <String, dynamic>{
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        if (description != null) 'description': description,
        'isNFCEnabled': isNFCEnabled,
        if (nfcId != null) 'nfcId': nfcId,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return Point.fromUserMapJson(data);
  }

  Future<Point> updateLocation({
    required String locationId,
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _patch(
      '/api/locations/$locationId',
      body: <String, dynamic>{
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return Point.fromUserMapJson(data);
  }

  Future<void> deleteLocation(String locationId) async {
    await _delete('/api/locations/$locationId');
  }

  Future<ActivitySession> startActivity({
    required String userId,
    required DateTime startTime,
    required LatLng startLocation,
  }) async {
    final response = await _post(
      '/api/users/$userId/activities/start',
      body: <String, dynamic>{
        'startTime': startTime.toUtc().toIso8601String(),
        'startLocation': {
          'latitude': startLocation.latitude,
          'longitude': startLocation.longitude,
        },
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    // 將後端傳入的 UTC 時間（GMT+0）轉換為 GMT+8
    final startTimeUtc = DateTime.parse(data['startTime'] as String).toUtc();
    final startTimeGmt8 = startTimeUtc.add(const Duration(hours: 8));
    return ActivitySession(
      activityId: data['activityId'] as String,
      startTime: startTimeGmt8,
      status: data['status'] as String,
    );
  }

  Future<double> trackActivity({
    required String userId,
    required String activityId,
    required List<TrackPoint> points,
  }) async {
    if (points.isEmpty) {
      return 0.0;
    }
    final response = await _post(
      '/api/users/$userId/activities/$activityId/track',
      body: <String, dynamic>{
        'points': points.map((TrackPoint p) => p.toJson()).toList(),
      },
    );
    // 後端會回傳 distance（已行走距離，單位：公尺）
    final distance = (response['data']?['distance'] as num?)?.toDouble() ?? 0.0;
    return distance;
  }

  Future<Map<String, dynamic>> collectNfcLocation({
    required String userId,
    required String activityId,
    required String nfcId,
  }) async {
    if (useMockData) {
      // 模擬成功回傳
      await Future.delayed(const Duration(milliseconds: 200));
      return {
        'success': true,
        'data': {
          'locationId': 'mock-location-id',
          'name': '模擬地點',
          'coinsEarned': 1,
          'totalCoins': 100,
          'isFirstCollection': true,
        }
      };
    }

    final response = await _post(
      '/api/users/$userId/activities/$activityId/collect/nfc',
      body: <String, dynamic>{
        'nfcId': nfcId,
      },
    );
    
    return response;
  }

  Future<ActivitySummary> endActivity({
    required String userId,
    required String activityId,
    required DateTime endTime,
    required LatLng endLocation,
  }) async {
    final response = await _post(
      '/api/users/$userId/activities/$activityId/end',
      body: <String, dynamic>{
        'endTime': endTime.toUtc().toIso8601String(),
        'endLocation': {
          'latitude': endLocation.latitude,
          'longitude': endLocation.longitude,
        },
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    final route = (data['route'] as List<dynamic>? ?? <dynamic>[])
        .map(
          (dynamic item) {
            // 將後端傳入的 UTC 時間（GMT+0）轉換為 GMT+8
            final timestampUtc = DateTime.parse(item['timestamp'] as String).toUtc();
            final timestampGmt8 = timestampUtc.add(const Duration(hours: 8));
            return TrackPoint(
              latitude: (item['latitude'] as num).toDouble(),
              longitude: (item['longitude'] as num).toDouble(),
              timestamp: timestampGmt8,
            );
          },
        )
        .toList(growable: false);

    final collectedLocations =
        (data['collectedLocations'] as List<dynamic>? ?? <dynamic>[])
            .map(
              (dynamic item) => Point(
                id: item['id'] as String,
                name: item['name'] as String,
                location: LatLng(
                  (item['latitude'] as num).toDouble(),
                  (item['longitude'] as num).toDouble(),
                ),
                area: item['area'] as String?, // 後端會傳 area，但可能為 null
                coinsEarned: (item['coinsEarned'] as num?)?.toInt(),
                collected: true,
              ),
            )
            .toList(growable: false);

    // 將後端傳入的 UTC 時間（GMT+0）轉換為 GMT+8
    final startTimeUtc = DateTime.parse(data['startTime'] as String).toUtc();
    final startTimeGmt8 = startTimeUtc.add(const Duration(hours: 8));
    final endTimeUtc = DateTime.parse(data['endTime'] as String).toUtc();
    final endTimeGmt8 = endTimeUtc.add(const Duration(hours: 8));
    return ActivitySummary(
      activityId: data['activityId'] as String,
      startTime: startTimeGmt8,
      endTime: endTimeGmt8,
      distanceKm: (data['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (data['duration'] as num?)?.toInt() ?? 0,
      averageSpeedKmh: (data['averageSpeed'] as num?)?.toDouble() ?? 0,
      route: route,
      collectedLocations: collectedLocations,
      totalCoinsEarned: (data['totalCoinsEarned'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<ActivityItem>> fetchActivities({
    required String userId,
    int? page,
    int? limit,
  }) async {
    if (useMockData) {
      return _getMockActivities();
    }

    final response = await _get(
      '/api/users/$userId/activities',
      queryParameters: <String, String>{
        if (page != null) 'page': '$page',
        if (limit != null) 'limit': '$limit',
      },
    );

    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final activities = data['activities'] as List<dynamic>? ?? <dynamic>[];
    return activities
        .map(
          (dynamic json) =>
              ActivityItem.fromJson(json as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<ActivityDetail> fetchActivityDetail({
    required String userId,
    required String activityId,
    String? userName,
    String? userAvatar,
  }) async {
    if (useMockData) {
      return _getMockActivityDetail(activityId, userId: userId, userName: userName, userAvatar: userAvatar);
    }

    final response = await _get(
      '/api/users/$userId/activities/$activityId',
    );

    final data = response['data'] as Map<String, dynamic>;
    return ActivityDetail.fromJson(
      data,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
    );
  }

  /// 獲取用戶的徽章列表
  /// GET /api/users/{userId}/badges
  Future<List<BadgeModel>> fetchUserBadges({
    required String userId,
  }) async {
    if (useMockData) {
      return _getMockUserBadges(userId: userId);
    }

    final response = await _get('/api/users/$userId/badges');
    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final badges = data['badges'] as List<dynamic>? ?? <dynamic>[];
    
    // 調試：打印API返回的徽章數據，確認是否包含color字段
    debugPrint('========== API返回的徽章數據 ==========');
    debugPrint('徽章總數: ${badges.length}');
    if (badges.isNotEmpty) {
      // 打印所有徽章的color字段
      for (var i = 0; i < badges.length; i++) {
        final badge = badges[i] as Map<String, dynamic>;
        debugPrint('徽章[$i]: ${badge['name']} - color: ${badge['color']} (類型: ${badge['color']?.runtimeType})');
      }
      debugPrint('第一個徽章的完整 JSON: ${badges.first}');
    }
    debugPrint('=======================================');
    
    return badges
        .map((json) {
          return BadgeModel.fromJson(json as Map<String, dynamic>);
        })
        .toList(growable: false);
  }


  /// 獲取用戶徽章統計（包含已收集數量）
  /// GET /api/users/{userId}/badges
  Future<UserBadgeStats> fetchUserBadgeStats({
    required String userId,
  }) async {
    if (useMockData) {
      // Mock模式下也從真實API獲取數據，確保數據從數據庫讀取
      try {
        final response = await _get('/api/users/$userId/badges');
        final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final collectedCount = data['collectedCount'] as int? ?? 0;
        final totalCount = data['totalBadges'] as int? ?? 0;
        return UserBadgeStats(
          collectedCount: collectedCount,
          totalCount: totalCount,
        );
      } catch (e) {
        debugPrint('Mock模式：無法連接到後端，返回空統計');
        return const UserBadgeStats(collectedCount: 0, totalCount: 0);
      }
    }

    final response = await _get('/api/users/$userId/badges');
    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    
    return UserBadgeStats(
      collectedCount: data['collectedCount'] as int? ?? 0,
      totalCount: data['totalBadges'] as int? ?? 0,
    );
  }

  /// 獲取單個徽章詳情
  /// GET /api/users/{userId}/badges/{badgeId}
  Future<BadgeDetailModel> fetchUserBadgeDetail({
    required String userId,
    required String badgeId,
  }) async {
    if (useMockData) {
      return _getMockBadgeDetail(userId: userId, badgeId: badgeId);
    }

    final response = await _get('/api/users/$userId/badges/$badgeId');
    final data = response['data'] as Map<String, dynamic>;
    return BadgeDetailModel.fromJson(data);
  }

  /// 獲取所有徽章列表
  /// GET /api/badges
  Future<List<BadgeModel>> fetchAllBadges() async {
    if (useMockData) {
      return _getMockAllBadges();
    }

    final response = await _get('/api/badges');
    final data = response['data'] as List<dynamic>? ?? <dynamic>[];
    
    return data
        .map((dynamic json) => BadgeModel.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Mock 活動詳情資料
  Future<ActivityDetail> _getMockActivityDetail(
    String activityId, {
    String? userId,
    String? userName,
    String? userAvatar,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 先獲取活動列表，找到對應的活動信息
    final activities = await _getMockActivities();
    final activity = activities.firstWhere(
      (a) => a.activityId == activityId,
      orElse: () => activities.first, // 如果找不到，使用第一個
    );

    // 根據活動信息生成詳細數據
    final startTime = activity.date;
    final endTime = startTime.add(Duration(seconds: activity.duration));
    final distanceKm = activity.distance;
    final durationSeconds = activity.duration;
    final averageSpeedKmh = activity.averageSpeed;
    final coinsEarned = activity.coinsEarned;

    // 根據不同的 activityId 生成不同的路線和點位
    final centerLat = 25.0330;
    final centerLng = 121.5654;
    final route = <TrackPoint>[];
    
    // 根據 activityId 生成不同的路線模式
    int routePattern = 0;
    if (activityId == 'act_001') {
      routePattern = 1; // 環形路線
    } else if (activityId == 'act_002') {
      routePattern = 2; // 直線路線
    } else if (activityId == 'act_003') {
      routePattern = 3; // 曲折路線
    }

    // 生成路線點位
    final pointCount = (durationSeconds / 120).round().clamp(10, 30); // 每2分鐘一個點
    for (int i = 0; i < pointCount; i++) {
      double lat, lng;
      final progress = i / pointCount;
      
      switch (routePattern) {
        case 1: // 環形路線
          final radius = 0.002;
          final angle = progress * 2 * math.pi;
          lat = centerLat + radius * math.sin(angle);
          lng = centerLng + radius * math.cos(angle);
          break;
        case 2: // 直線路線
          lat = centerLat + progress * 0.003;
          lng = centerLng + progress * 0.003;
          break;
        case 3: // 曲折路線
          final radius = 0.0015;
          final angle = progress * 4 * math.pi; // 多繞幾圈
          lat = centerLat + radius * math.sin(angle) + progress * 0.002;
          lng = centerLng + radius * math.cos(angle) + progress * 0.002;
          break;
        default:
          final radius = 0.002;
          final angle = progress * 2 * math.pi;
          lat = centerLat + radius * math.sin(angle);
          lng = centerLng + radius * math.cos(angle);
      }
      
      route.add(
        TrackPoint(
          latitude: lat,
          longitude: lng,
          timestamp: startTime.add(Duration(seconds: i * (durationSeconds ~/ pointCount))),
        ),
      );
    }

    // 根據 collectedLocationsCount 生成點位紀錄
    final locationRecords = <ActivityLocationRecord>[];
    final locationNames = ['安森東側涼亭', '台大體育館', '台大圖書館', '台大操場', '台大總圖'];
    final areas = ['臺北市 大安區', '臺北市 大安區', '臺北市 大安區', '臺北市 大安區', null];
    
    // 使用固定的種子確保每次生成的數據一致（基於 activityId）
    final random = math.Random(activityId.hashCode);
    
    for (int i = 0; i < activity.collectedLocationsCount; i++) {
      final locationIndex = i % locationNames.length;
      final collectTime = startTime.add(
        Duration(seconds: (i + 1) * (durationSeconds ~/ (activity.collectedLocationsCount + 1))),
      );
      
      // 根據路線計算點位位置
      final routeIndex = ((i + 1) * route.length / (activity.collectedLocationsCount + 1)).round();
      final routePoint = route[routeIndex.clamp(0, route.length - 1)];
      
      // 使用固定種子的隨機數，確保同一活動每次生成的數據一致
      locationRecords.add(
        ActivityLocationRecord(
          locationId: 'loc_${activityId}_${i + 1}',
          locationName: locationNames[locationIndex],
          collectedAt: collectTime,
          latitude: routePoint.latitude + (random.nextDouble() - 0.5) * 0.0005,
          longitude: routePoint.longitude + (random.nextDouble() - 0.5) * 0.0005,
          area: areas[locationIndex],
        ),
      );
    }

    return ActivityDetail(
      activityId: activityId,
      userId: userId ?? 'user_001',
      userName: userName ?? 'Ocean',
      userAvatar: userAvatar,
      startTime: startTime,
      endTime: endTime,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      averageSpeedKmh: averageSpeedKmh,
      route: route,
      locationRecords: locationRecords,
      totalCoinsEarned: coinsEarned,
    );
  }

  /// Mock 用戶徽章列表
  /// 注意：即使使用Mock模式，也嘗試從真實API獲取數據，確保顏色從數據庫讀取
  Future<List<BadgeModel>> _getMockUserBadges({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock模式下，嘗試從真實API獲取數據（如果後端可用）
    // 這樣可以確保即使使用Mock模式，顏色也從數據庫獲取
    try {
      final response = await _get('/api/users/$userId/badges');
      final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final badges = data['badges'] as List<dynamic>? ?? <dynamic>[];
      
      return badges
          .map((json) {
            return BadgeModel.fromJson(json as Map<String, dynamic>);
          })
          .toList(growable: false);
    } catch (e) {
      // 如果後端不可用，返回空列表
      debugPrint('Mock模式：無法連接到後端，返回空徽章列表');
      return <BadgeModel>[];
    }
  }

  /// Mock 徽章詳情
  /// 注意：即使使用Mock模式，也嘗試從真實API獲取數據，確保顏色從數據庫讀取
  Future<BadgeDetailModel> _getMockBadgeDetail({
    required String userId,
    required String badgeId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock模式下，嘗試從真實API獲取數據
    try {
      final response = await _get('/api/users/$userId/badges/$badgeId');
      final data = response['data'] as Map<String, dynamic>;
      return BadgeDetailModel.fromJson(data);
    } catch (e) {
      debugPrint('Mock模式：無法連接到後端獲取徽章詳情');
      rethrow;
    }
  }

  /// Mock 所有徽章列表
  Future<List<BadgeModel>> _getMockAllBadges() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock模式下，嘗試從真實API獲取數據（如果後端可用）
    // 這樣可以確保即使使用Mock模式，顏色也從數據庫獲取
    try {
      final response = await _get('/api/badges');
      final data = response['data'] as List<dynamic>? ?? <dynamic>[];
      
      return data
          .map((dynamic json) => BadgeModel.fromJson(json as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e) {
      // 如果後端不可用，返回空列表
      debugPrint('Mock模式：無法連接到後端，返回空徽章列表');
      return <BadgeModel>[];
    }
  }

  /// Mock 活動列表資料
  Future<List<ActivityItem>> _getMockActivities() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now();
    
    // Mock 資料：符合 API Response 9 格式
    // date 欄位是開始時間，需要設定具體的時間（例如 10:00）
    final mockActivities = <ActivityItem>[
      ActivityItem(
        activityId: 'act_001',
        date: DateTime(now.year, now.month, now.day - 1, 10, 0), // 昨天 10:00
        distance: 3.5,
        duration: 1800, // 30 分鐘
        averageSpeed: 7.0,
        coinsEarned: 2,
        collectedLocationsCount: 2,
      ),
      ActivityItem(
        activityId: 'act_002',
        date: DateTime(now.year, now.month, now.day - 2, 9, 0), // 2天前 09:00
        distance: 5.2,
        duration: 2400, // 40 分鐘
        averageSpeed: 7.8,
        coinsEarned: 3,
        collectedLocationsCount: 3,
      ),
      ActivityItem(
        activityId: 'act_003',
        date: DateTime(now.year, now.month, now.day - 5, 14, 30), // 5天前 14:30
        distance: 2.1,
        duration: 1200, // 20 分鐘
        averageSpeed: 6.3,
        coinsEarned: 1,
        collectedLocationsCount: 1,
      ),
    ];
    
    return mockActivities;
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: <String, String>{
        if (queryParameters != null) ...queryParameters,
      },
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final response = await _httpClient.get(uri);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    
    try {
      final response = await _httpClient
          .post(
      uri,
      headers: _jsonHeaders,
      body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw ApiException(
                '請求超時，請檢查網路連接',
                code: 'TIMEOUT',
                statusCode: 408,
              );
            },
    );
    return _handleResponse(response);
    } on http.ClientException catch (e) {
      // 處理網路連接錯誤
      throw ApiException(
        '網路連接失敗：${e.message}\n請確認：\n1. 後端伺服器正在運行\n2. iPhone 和 Mac 在同一網路\n3. Mac IP 地址正確',
        code: 'NETWORK_ERROR',
        statusCode: null,
      );
    } on SocketException catch (e) {
      throw ApiException(
        '無法連接到伺服器：${e.message}\n請確認後端伺服器正在運行',
        code: 'CONNECTION_ERROR',
        statusCode: null,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        '請求失敗：${e.toString()}',
        code: 'UNKNOWN_ERROR',
        statusCode: null,
      );
    }
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    final response = await _httpClient.patch(
      uri,
      headers: _jsonHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<void> _delete(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final response = await _httpClient.delete(uri, headers: _jsonHeaders);
    _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final String body = response.body;
    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException(
        'Request failed with status $statusCode: $body',
        statusCode: statusCode,
      );
    }

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final success = decoded['success'] as bool?;
          if (success != null && !success) {
            // 處理後端 API 錯誤格式
            final error = decoded['error'] as Map<String, dynamic>?;
            if (error != null) {
              final code = error['code'] as String? ?? 'UNKNOWN_ERROR';
              final message = error['message'] as String? ??
                  decoded['message'] as String? ??
                  decoded['reason'] as String? ??
                  'Unknown API error';
              throw ApiException(
                message,
                code: code,
                statusCode: statusCode,
              );
            }
            // 如果沒有 error 物件，使用舊格式
            final message = decoded['message'] as String? ??
                decoded['reason'] as String? ??
                'Unknown API error';
            throw ApiException(
              message,
              statusCode: statusCode,
            );
          }
          return decoded;
        }
        return <String, dynamic>{'data': decoded};
      } catch (error, stackTrace) {
      debugPrint(
        'ApiService: failed to decode response ($statusCode): $error\n$stackTrace',
      );
      throw ApiException(
        'Failed to decode response: $error',
        statusCode: statusCode,
      );
    }
  }

  Map<String, String> get _jsonHeaders => const <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}

