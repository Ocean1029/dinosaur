import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dinosaur/page/home/api_service.dart';
import 'package:dinosaur/page/home/point.dart';
import 'package:dinosaur/service/account_service.dart';
import 'package:dinosaur/service/service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ActivityDetailController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AccountService _accountService = Get.find<AccountService>();
  final Service _runCityService = Get.find<Service>();

  final RxBool isLoading = false.obs;
  final Rxn<ActivityDetail> activityDetail =
      Rxn<ActivityDetail>();
  final RxnString errorMessage = RxnString();

  // 地圖相關
  GoogleMapController? mapController;
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;

  final GlobalKey shareCardKey = GlobalKey();
  Uint8List? _shareMapSnapshot;
  bool _isSharing = false;
  bool _isSharePreviewOpen = false;

  String? _userId;
  String? _activityId;

  Uint8List? get shareMapSnapshot => _shareMapSnapshot;
  bool get isSharing => _isSharing;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments is Map<String, dynamic>) {
      _activityId = arguments['activityId'] as String?;
      _userId = arguments['userId'] as String?;
    }
    if (_activityId != null && _userId != null) {
      loadActivityDetail();
    } else {
      errorMessage.value = '缺少必要參數';
    }
  }

  @override
  void onClose() {
    mapController?.dispose();
    super.onClose();
  }

  /// 載入活動詳情
  Future<void> loadActivityDetail() async {
    if (_userId == null || _activityId == null) {
      errorMessage.value = '缺少必要參數';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      // 獲取用戶信息（用於顯示頭像和姓名）
      String? userName;
      String? userAvatar;

      try {
        final userData = await _runCityService.getUserProfile();
        userName = userData.name;
        userAvatar = userData.avatarUrl;
      } catch (e) {
        // 如果獲取用戶資料失敗，使用 account service 的資料
        final account = _accountService.account;
        if (account != null) {
          // Account 可能沒有 name 欄位，使用 userId 作為備用
          userName = account.id;
        }
      }

      final detail = await _apiService.fetchActivityDetail(
        userId: _userId!,
        activityId: _activityId!,
        userName: userName,
        userAvatar: userAvatar,
      );
      activityDetail.value = detail;
      await _updateMap();
    } on ApiException catch (e) {
      final errorText = e.code != null ? '${e.message} (${e.code})' : e.message;
      errorMessage.value = errorText;
    } catch (e) {
      errorMessage.value = '載入活動詳情失敗：${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// 更新地圖顯示
  BitmapDescriptor? _nodeMarkerIcon;

  Future<void> _updateMap() async {
    final detail = activityDetail.value;
    if (detail == null) {
      return;
    }

    // 清除所有現有的標記
    markers.clear();
    markers.refresh();

    // 建立路線 Polyline（僅當有路線數據時）
    if (detail.route.isNotEmpty) {
      final routePoints = detail.route
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList(growable: false);
      polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: const Color(0xFFFF853A), // 橙色
            width: 5,
          ),
        );
      polylines.refresh();
    } else {
      polylines.clear();
      polylines.refresh();
    }

    // 只標記 collectedLocations 中的地點（即 locationRecords）
    final locationRecords = detail.locationRecords;
    if (locationRecords.isNotEmpty) {
      final markerIcon = await _getNodeMarkerIcon();
      final newMarkers = locationRecords
          .asMap()
          .entries
          .map(
            (entry) => Marker(
              markerId: MarkerId('collected_location_${entry.value.locationId}'),
              position: LatLng(
                entry.value.latitude,
                entry.value.longitude,
              ),
              icon: markerIcon,
              anchor: const Offset(0.5, 0.5),
              infoWindow: InfoWindow(
                title: entry.value.locationName,
                snippet: entry.value.area ?? '',
              ),
            ),
          )
          .toSet();
      markers.addAll(newMarkers);
      markers.refresh();
    }

    // 調整地圖視角以包含所有路線和標記的地點
    final allPoints = <LatLng>[];
    
    // 添加路線點
    if (detail.route.isNotEmpty) {
      allPoints.addAll(
        detail.route.map((point) => LatLng(point.latitude, point.longitude)),
      );
    }
    
    // 添加標記的地點
    if (locationRecords.isNotEmpty) {
      allPoints.addAll(
        locationRecords.map((record) => LatLng(record.latitude, record.longitude)),
      );
    }
    
    if (mapController != null && allPoints.isNotEmpty) {
      await _fitBounds(allPoints);
    }
  }

  /// 調整地圖視角以包含所有點位
  Future<void> _fitBounds(List<LatLng> points) async {
    if (points.isEmpty || mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.001, minLng - 0.001),
          northeast: LatLng(maxLat + 0.001, maxLng + 0.001),
        ),
        100.0, // padding
      ),
    );
  }

  /// 地圖創建完成回調
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    unawaited(_updateMap());
  }

  Future<bool> prepareSharePreview() async {
    if (_isSharePreviewOpen) {
      return true;
    }
    try {
      await _captureMapSnapshot();
      update(['sharePreview']);
      _isSharePreviewOpen = true;
      return true;
    } on _ShareException catch (error) {
      _showShareError(error.userMessage);
      return false;
    }
  }

  Future<BitmapDescriptor> _getNodeMarkerIcon() async {
    if (_nodeMarkerIcon != null) {
      return _nodeMarkerIcon!;
    }

    const double markerDiameter = 50;
    const double borderWidth = 3.5;
    const double shadowBlurSigma = 7;
    const double shadowOffsetY = 5;
    final double canvasSize =
        markerDiameter + shadowBlurSigma * 2 + shadowOffsetY;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = ui.Offset(
      canvasSize / 2,
      markerDiameter / 2 + shadowBlurSigma,
    );

    final shadowPaint = ui.Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, shadowBlurSigma);
    canvas.drawCircle(
      center.translate(0, shadowOffsetY),
      markerDiameter / 2,
      shadowPaint,
    );

    final fillPaint = ui.Paint()..color = const Color(0xFF5AB4C5);
    canvas.drawCircle(center, markerDiameter / 2, fillPaint);

    final borderPaint = ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(
      center,
      markerDiameter / 2 - borderWidth / 2,
      borderPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.toInt(),
      (markerDiameter + shadowBlurSigma * 2 + shadowOffsetY).toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('無法產生節點圖示');
    }
    final Uint8List bytes = byteData.buffer.asUint8List();
    _nodeMarkerIcon = BitmapDescriptor.fromBytes(bytes);
    return _nodeMarkerIcon!;
  }

  Future<bool> shareActivity() async {
    if (_isSharing) {
      return false;
    }
    final detail = activityDetail.value;
    if (detail == null) {
      _showShareError('尚無活動資料');
      return false;
    }

    try {
      _isSharing = true;
      update(['sharePreview']);
      if (_shareMapSnapshot == null || _shareMapSnapshot!.isEmpty) {
        await _captureMapSnapshot();
        update(['sharePreview']);
      }

      final boundary = await _obtainReadyBoundary();

      ui.Image image;
      try {
        image = await boundary.toImage(pixelRatio: 3);
      } catch (error, stack) {
        _logShareError('capture_image', error, stack);
        throw _ShareException(
          userMessage: '生成分享圖片時發生錯誤，請稍後再試',
          debugStep: 'capture_image',
          cause: error,
        );
      }

      ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } catch (error, stack) {
        _logShareError('encode_image', error, stack);
        throw _ShareException(
          userMessage: '轉換分享圖片時發生錯誤，請稍後再試',
          debugStep: 'encode_image',
          cause: error,
        );
      }
      if (byteData == null) {
        throw const _ShareException(
          userMessage: '無法產生分享圖片，請稍後再試',
          debugStep: 'encode_image_null',
        );
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      File file;
      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath =
            '${tempDir.path}/run_city_activity_${_activityId}_${DateTime.now().millisecondsSinceEpoch}.png';
        file = File(filePath);
        await file.writeAsBytes(pngBytes, flush: true);
      } catch (error, stack) {
        _logShareError('write_file', error, stack);
        throw _ShareException(
          userMessage: '儲存分享圖片時發生錯誤，請檢查儲存空間後再試',
          debugStep: 'write_file',
          cause: error,
        );
      }

      try {
        final String shareText =
            '我的 Run City 運動紀錄：${detail.formattedDistance}，耗時 ${detail.formattedDuration}，獲得 ${detail.totalCoinsEarned} 金幣！#RunCity #TownPass';
        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
        );
      } catch (error, stack) {
        _logShareError('share_sheet', error, stack);
        throw _ShareException(
          userMessage: '開啟分享面板失敗，請確認是否允許分享權限或稍後再試',
          debugStep: 'share_sheet',
          cause: error,
        );
      }
      return true;
    } on _ShareException catch (error) {
      _showShareError(error.userMessage);
      return false;
    } finally {
      _isSharing = false;
      update(['sharePreview']);
    }
  }

  Future<void> _captureMapSnapshot() async {
    if (mapController == null) {
      throw const _ShareException(
        userMessage: '地圖尚未載入完成，請稍後再試',
        debugStep: 'map_not_ready',
      );
    }
    try {
      final Uint8List? snapshot = await mapController!.takeSnapshot();
      if (snapshot == null || snapshot.isEmpty) {
        throw const _ShareException(
          userMessage: '無法擷取地圖畫面，請稍後再試',
          debugStep: 'map_snapshot_empty',
        );
      }
      _shareMapSnapshot = snapshot;
    } catch (error) {
      throw _ShareException(
        userMessage: '擷取地圖畫面失敗，請稍後再試',
        debugStep: 'map_snapshot_error',
        cause: error,
      );
    }
  }

  void _logShareError(String step, Object error, StackTrace stackTrace) {
    debugPrint(
      '[RunCityActivityShare] step=$step activity=$_activityId error=$error\n$stackTrace',
    );
  }

  Future<RenderRepaintBoundary> _obtainReadyBoundary() async {
    RenderRepaintBoundary? boundary;
    for (var attempt = 0; attempt < 8; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      boundary = shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw const _ShareException(
          userMessage: '找不到分享卡片，請重新開啟頁面後再試',
          debugStep: 'locate_boundary',
        );
      }
      if (boundary.size.isEmpty) {
        throw const _ShareException(
          userMessage: '分享卡片尚未準備好，請稍後再試',
          debugStep: 'boundary_empty',
        );
      }
      if (!boundary.debugNeedsPaint) {
        return boundary;
      }
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    throw const _ShareException(
      userMessage: '分享畫面尚未渲染完成，請稍候片刻再試',
      debugStep: 'boundary_never_painted',
    );
  }

  void closeSharePreview() {
    _isSharePreviewOpen = false;
    update(['sharePreview']);
  }

  void _showShareError(String message) {
    Get.snackbar(
      '分享失敗',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.85),
      colorText: Colors.white,
    );
  }

  /// 刷新資料
  Future<void> refreshActivity() async {
    await loadActivityDetail();
  }
}

class _ShareException implements Exception {
  const _ShareException({
    required this.userMessage,
    this.debugStep,
    this.cause,
  });

  final String userMessage;
  final String? debugStep;
  final Object? cause;
}
