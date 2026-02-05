import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dinosaur/page/home/api_service.dart';
import 'package:dinosaur/page/home/point.dart';
import 'package:dinosaur/service/account_service.dart';

class BadgeDetailController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AccountService _accountService = Get.find<AccountService>();

  final RxBool isLoading = true.obs;
  final Rxn<BadgeDetailModel> badgeDetail = Rxn<BadgeDetailModel>();
  final RxnString errorMessage = RxnString();

  late CameraPosition initialCameraPosition;
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Circle> circles = <Circle>{}.obs;
  GoogleMapController? mapController;
  BitmapDescriptor? _pointMarkerIcon;
  final GlobalKey shareCardKey = GlobalKey();

  String? _userName;
  bool _isSharing = false;

  static const Color _pointColor = Color.fromRGBO(90, 180, 197, 1);
  static const String _mapStyleHidePoi = '''
[
  {
    "featureType": "poi",
    "stylers": [{ "visibility": "off" }]
  }
]
''';

  BadgeModel? get badge => badgeDetail.value?.badge;
  List<BadgeLocation> get badgeLocations => badgeDetail.value?.requiredLocations ?? [];

  String get badgeDescription => badge?.description ?? '探索${badge?.name ?? ""}，完成所有指定地點即可獲得徽章。';

  List<BadgeLocation> get collectedLocations => badgeLocations
      .where((location) => location.isCollected)
      .toList();

  List<BadgeLocation> get pendingLocations => badgeLocations
      .where((location) => !location.isCollected)
      .toList();

  bool get isCompleted => badge?.status == BadgeStatus.collected || 
                         (badge?.progress?.percentage ?? 0) == 100;

  int get collectedPoints => badge?.progress?.collected ?? collectedLocations.length;
  int get totalPoints => badge?.progress?.total ?? badgeLocations.length;

  String get shareUserName =>
      _userName?.isNotEmpty == true ? _userName! : 'Run City 玩家';
  bool get isSharing => _isSharing;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
    final badgeId = args['badgeId'] as String?;
    final badgeArg = args['badge'] as BadgeModel?;

    if (badgeId == null && badgeArg == null) {
      Get.back();
      return;
    }

    loadBadgeDetail(badgeId ?? badgeArg!.badgeId);
  }

  Future<void> loadBadgeDetail(String badgeId) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final account = _accountService.account;
      if (account == null) {
        errorMessage.value = '請先登入';
        return;
      }

      final detail = await _apiService.fetchUserBadgeDetail(
        userId: account.id,
        badgeId: badgeId,
      );

      badgeDetail.value = detail;
      initialCameraPosition = _buildInitialCameraPosition();
      circles.clear();
      await _prepareMarkers();
      unawaited(_loadUserName());
    } catch (e) {
      errorMessage.value = '載入徽章詳情失敗：$e';
    } finally {
      isLoading.value = false;
    }
  }

  CameraPosition _buildInitialCameraPosition() {
    if (badgeLocations.isEmpty) {
      return const CameraPosition(
        target: LatLng(25.033968, 121.564468),
        zoom: 13,
      );
    }

    double latSum = 0;
    double lngSum = 0;
    for (final location in badgeLocations) {
      latSum += location.latitude;
      lngSum += location.longitude;
    }
    final center =
        LatLng(latSum / badgeLocations.length, lngSum / badgeLocations.length);

    return CameraPosition(
      target: center,
      zoom: _suggestZoom(badgeLocations),
    );
  }

  double _suggestZoom(List<BadgeLocation> locations) {
    if (locations.length <= 1) {
      return 15;
    }
    double maxDistance = 0;
    for (var i = 0; i < locations.length; i++) {
      for (var j = i + 1; j < locations.length; j++) {
        final distance = _haversineDistance(
          locations[i].location,
          locations[j].location,
        );
        maxDistance = max(maxDistance, distance);
      }
    }
    if (maxDistance < 0.5) {
      return 15.5;
    }
    if (maxDistance < 1) {
      return 14.5;
    }
    if (maxDistance < 3) {
      return 13.5;
    }
    return 12.5;
  }

  double _haversineDistance(LatLng a, LatLng b) {
    const earthRadiusKm = 6371;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  Future<void> _prepareMarkers() async {
    // 使用徽章的顏色，如果沒有則使用默認顏色
    final badgeColor = badge?.badgeColor ?? _pointColor;
    // 每次重新創建標記圖標，以確保使用正確的徽章顏色
    _pointMarkerIcon = await _createMarkerBitmap(
      diameter: 50,
      fillColor: badgeColor,
      borderColor: Colors.white,
      borderWidth: 4,
      shadowBlur: 8,
    );
    markers.assignAll(_buildMarkers());
    update(['badgeMap']);
  }

  Set<Marker> _buildMarkers() {
    if (badge == null) {
      return <Marker>{};
    }
    
    return badgeLocations.map((location) {
      return Marker(
        markerId: MarkerId(location.locationId),
        position: location.location,
        infoWindow: InfoWindow(
          title: location.name,
          snippet: badge?.area ?? '',
        ),
        icon: _pointMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(
              location.isCollected
                  ? BitmapDescriptor.hueAzure
                  : BitmapDescriptor.hueCyan,
            ),
        zIndex: 2,
      );
    }).toSet();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.setMapStyle(_mapStyleHidePoi);
  }

  Future<void> focusOnLocation(BadgeLocation location) async {
    if (mapController == null) {
      return;
    }
    await mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(location.location, 15),
    );
  }

  Future<BitmapDescriptor> _createMarkerBitmap({
    required double diameter,
    required Color fillColor,
    required Color borderColor,
    double borderWidth = 2,
    double shadowBlur = 6,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = ui.Size(diameter, diameter);
    final center = Offset(diameter / 2, diameter / 2);

    if (shadowBlur > 0) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);
      canvas.drawCircle(
        center.translate(0, diameter * 0.05),
        diameter / 2 - borderWidth,
        shadowPaint,
      );
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, diameter / 2, borderPaint);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, diameter / 2 - borderWidth, fillPaint);

    final picture = recorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<bool> shareBadge() async {
    if (!isCompleted || _isSharing || badge == null) {
      return false;
    }

    try {
      _isSharing = true;
      update(['sharePreview']);
      final RenderRepaintBoundary boundary = await _obtainReadyBoundary();

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
        throw _ShareException(
          userMessage: '無法產生分享圖片，請稍後再試',
          debugStep: 'encode_image_null',
        );
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      File file;
      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath =
            '${tempDir.path}/run_city_badge_${badge!.badgeId}_${DateTime.now().millisecondsSinceEpoch}.png';
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
            '我完成了 ${badge!.name} 徽章，收集了 $collectedPoints/$totalPoints 個點位！#RunCity #TownPass';
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
    } on _ShareException catch (shareError) {
      if (shareError.debugStep != null) {
        debugPrint(
          '[BadgeShare] step=${shareError.debugStep} badge=${badge?.badgeId} message=${shareError.userMessage} cause=${shareError.cause}',
        );
      }
      _showShareError(shareError.userMessage);
      return false;
    } finally {
      _isSharing = false;
      update(['sharePreview']);
    }
  }

  Future<RenderRepaintBoundary> _obtainReadyBoundary() async {
    RenderRepaintBoundary? boundary;
    for (var attempt = 0; attempt < 8; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      boundary = shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw const _ShareException(
          userMessage: '找不到分享卡片，請重新進入頁面後再試',
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

  Future<void> _loadUserName() async {
    try {
      final account = _accountService.account;
      if (account?.id != null) {
        _userName = account!.id;
      }
    } catch (_) {
      // ignore
    }
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

  void _logShareError(String step, Object error, StackTrace stackTrace) {
    debugPrint(
      '[BadgeShare] step=$step badge=${badge?.badgeId} error=$error\n$stackTrace',
    );
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
