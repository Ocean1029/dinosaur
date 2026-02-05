import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ==================== 簡化版本，用於快速編譯 ====================

/// 表示一個地理位置點
class Point {
  const Point({
    required this.id,
    required this.name,
    required this.location,
    this.area,
    this.description,
    this.nfcId,
    this.isNFCEnabled = false,
    this.collected = false,
    this.collectedAt,
    this.coinsEarned,
  });

  final String id;
  final String name;
  final LatLng location;
  final String? area;
  final String? description;
  final String? nfcId;
  final bool isNFCEnabled;
  final bool collected;
  final DateTime? collectedAt;
  final int? coinsEarned;

  Point copyWith({
    String? id,
    String? name,
    LatLng? location,
    String? area,
    String? description,
    String? nfcId,
    bool? isNFCEnabled,
    bool? collected,
    DateTime? collectedAt,
    int? coinsEarned,
  }) {
    return Point(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      area: area ?? this.area,
      description: description ?? this.description,
      nfcId: nfcId ?? this.nfcId,
      isNFCEnabled: isNFCEnabled ?? this.isNFCEnabled,
      collected: collected ?? this.collected,
      collectedAt: collectedAt ?? this.collectedAt,
      coinsEarned: coinsEarned ?? this.coinsEarned,
    );
  }

  factory Point.fromUserMapJson(Map<String, dynamic> json) {
    return Point(
      id: json['id'] as String,
      name: json['name'] as String,
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      area: json['area'] as String?,
      description: json['description'] as String?,
      nfcId: json['nfcId'] as String?,
      isNFCEnabled: (json['isNFCEnabled'] as bool?) ?? false,
      collected: (json['isCollected'] as bool?) ?? false,
    );
  }
}

class TrackPoint {
  const TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toUtc().toIso8601String(),
    if (accuracy != null) 'accuracy': accuracy,
  };
}

class ActivitySession {
  const ActivitySession({
    required this.activityId,
    required this.startTime,
    required this.status,
  });

  final String activityId;
  final DateTime startTime;
  final String status;
}

class ActivitySummary {
  const ActivitySummary({
    required this.activityId,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averageSpeedKmh,
    required this.route,
    required this.collectedLocations,
    required this.totalCoinsEarned,
  });

  final String activityId;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSeconds;
  final double averageSpeedKmh;
  final List<TrackPoint> route;
  final List<Point> collectedLocations;
  final int totalCoinsEarned;
}

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.totalCoins = 0,
    this.totalDistanceKm = 0,
    this.totalTimeSeconds = 0,
    this.updatedAt,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final int totalCoins;
  final double totalDistanceKm;
  final int totalTimeSeconds;
  final DateTime? updatedAt;
}

enum BadgeStatus { collected, inProgress, locked }

class BadgeProgress {
  const BadgeProgress({
    required this.collected,
    required this.total,
    required this.percentage,
  });

  final int collected;
  final int total;
  final int percentage;

  factory BadgeProgress.fromJson(Map<String, dynamic> json) {
    return BadgeProgress(
      collected: json['collected'] as int,
      total: json['total'] as int,
      percentage: json['percentage'] as int,
    );
  }
}

class BadgeModel {
  const BadgeModel({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.area,
    required this.imageUrl,
    this.status,
    this.unlockedAt,
    this.progress,
    this.requiredLocationIds,
    this.badgeColor,
    this.pointIds,
    this.collectedPointIds,
    this.distanceMeters,
  });

  final String badgeId;
  final String name;
  final String description;
  final String area;
  final String imageUrl;
  final BadgeStatus? status;
  final DateTime? unlockedAt;
  final BadgeProgress? progress;
  final List<String>? requiredLocationIds;
  final Color? badgeColor;
  final List<String>? pointIds;
  final List<String>? collectedPointIds;
  final double? distanceMeters;

  String get id => badgeId;

  int get totalPoints {
    if (progress != null) {
      return progress!.total;
    }
    return pointIds?.length ?? 0;
  }

  int get collectedPoints {
    if (progress != null) {
      return progress!.collected;
    }
    return collectedPointIds?.length ?? 0;
  }

  bool get isCompleted {
    if (status == BadgeStatus.collected) {
      return true;
    }
    if (progress != null) {
      return progress!.percentage >= 100;
    }
    return true;
  }

  double get completionRate {
    if (progress != null) {
      return progress!.percentage / 100.0;
    }
    return totalPoints == 0 ? 0 : collectedPoints / totalPoints;
  }

  double get distanceKm => (distanceMeters ?? 0) / 1000;

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    BadgeStatus? status;
    if (json['status'] != null) {
      switch (json['status'] as String) {
        case 'collected':
          status = BadgeStatus.collected;
          break;
        case 'in_progress':
          status = BadgeStatus.inProgress;
          break;
        case 'locked':
          status = BadgeStatus.locked;
          break;
      }
    }

    Color? badgeColor;
    if (json['color'] != null && json['color'] is String) {
      try {
        final colorString = json['color'] as String;
        final hexString = colorString.replaceFirst('#', '').toUpperCase();
        final fullHexString = hexString.length == 8 ? hexString : 'FF$hexString';
        final colorValue = int.parse(fullHexString, radix: 16);
        badgeColor = Color(colorValue);
      } catch (e) {
        badgeColor = null;
      }
    }

    return BadgeModel(
      badgeId: json['badgeId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      area: json['area'] as String? ?? '',
      imageUrl: json['imageUrl'] as String,
      status: status,
      requiredLocationIds: json['requiredLocationIds'] != null
          ? (json['requiredLocationIds'] as List<dynamic>).map((e) => e as String).toList()
          : null,
      badgeColor: badgeColor,
    );
  }

  BadgeModel copyWith({
    BadgeStatus? status,
    DateTime? unlockedAt,
    BadgeProgress? progress,
    List<String>? collectedPointIds,
    double? distanceMeters,
    Color? badgeColor,
    List<String>? requiredLocationIds,
  }) {
    return BadgeModel(
      badgeId: badgeId,
      name: name,
      description: description,
      area: area,
      imageUrl: imageUrl,
      status: status ?? this.status,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      requiredLocationIds: requiredLocationIds ?? this.requiredLocationIds,
      badgeColor: badgeColor ?? this.badgeColor,
      pointIds: pointIds,
      collectedPointIds: collectedPointIds ?? this.collectedPointIds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}

class BadgeLocation {
  const BadgeLocation({
    required this.locationId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.nfcId,
    required this.isCollected,
    this.collectedAt,
  });

  final String locationId;
  final String name;
  final double latitude;
  final double longitude;
  final String? nfcId;
  final bool isCollected;
  final DateTime? collectedAt;

  factory BadgeLocation.fromJson(Map<String, dynamic> json) {
    return BadgeLocation(
      locationId: json['locationId'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      nfcId: json['nfcId'] as String?,
      isCollected: json['isCollected'] as bool,
    );
  }

  LatLng get location => LatLng(latitude, longitude);
}

class BadgeDetailModel {
  const BadgeDetailModel({
    required this.badge,
    required this.requiredLocations,
  });

  final BadgeModel badge;
  final List<BadgeLocation> requiredLocations;

  factory BadgeDetailModel.fromJson(Map<String, dynamic> json) {
    final badge = BadgeModel.fromJson(json);
    final requiredLocations = (json['requiredLocations'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic item) => BadgeLocation.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return BadgeDetailModel(
      badge: badge,
      requiredLocations: requiredLocations,
    );
  }
}

class UserBadgeStats {
  const UserBadgeStats({
    required this.collectedCount,
    required this.totalCount,
  });

  final int collectedCount;
  final int totalCount;
}

class ActivityItem {
  const ActivityItem({
    required this.activityId,
    required this.date,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
    required this.coinsEarned,
    required this.collectedLocationsCount,
  });

  final String activityId;
  final DateTime date;
  final double distance;
  final int duration;
  final double averageSpeed;
  final int coinsEarned;
  final int collectedLocationsCount;

  /// 格式化時間範圍（開始時間到結束時間）
  String get formattedTimeRange {
    final endTime = date.add(Duration(seconds: duration));
    final startStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  /// 格式化距離
  String get formattedDistance {
    if (distance >= 1) {
      return '${distance.toStringAsFixed(1)} 公里';
    }
    return '${(distance * 1000).toStringAsFixed(0)} 公尺';
  }

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      activityId: json['activityId'] as String,
      date: DateTime.parse(json['date'] as String),
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'] as int,
      averageSpeed: (json['averageSpeed'] as num).toDouble(),
      coinsEarned: json['coinsEarned'] as int,
      collectedLocationsCount: json['collectedLocationsCount'] as int,
    );
  }
}

class ActivityLocationRecord {
  const ActivityLocationRecord({
    required this.locationId,
    required this.locationName,
    required this.collectedAt,
    required this.latitude,
    required this.longitude,
    this.area,
  });

  final String locationId;
  final String locationName;
  final DateTime collectedAt;
  final double latitude;
  final double longitude;
  final String? area;

  /// 格式化收集時間（HH:mm）
  String get formattedTime {
    return '${collectedAt.hour.toString().padLeft(2, '0')}:${collectedAt.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化地點名稱（包含區域資訊）
  String get formattedLocation {
    if (area != null && area!.isNotEmpty) {
      return '$locationName ($area)';
    }
    return locationName;
  }

  factory ActivityLocationRecord.fromJson(Map<String, dynamic> json) {
    return ActivityLocationRecord(
      locationId: json['id'] as String,
      locationName: json['name'] as String,
      collectedAt: DateTime.parse(json['collectedAt'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      area: json['area'] as String?,
    );
  }
}

class ActivityDetail {
  const ActivityDetail({
    required this.activityId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averageSpeedKmh,
    required this.route,
    required this.locationRecords,
    required this.totalCoinsEarned,
  });

  final String activityId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSeconds;
  final double averageSpeedKmh;
  final List<TrackPoint> route;
  final List<ActivityLocationRecord> locationRecords;
  final int totalCoinsEarned;

  factory ActivityDetail.fromJson(
    Map<String, dynamic> json, {
    String? userId,
    String? userName,
    String? userAvatar,
  }) {
    final route = (json['route'] as List<dynamic>? ?? <dynamic>[])
        .map(
          (dynamic item) => TrackPoint(
            latitude: (item['latitude'] as num).toDouble(),
            longitude: (item['longitude'] as num).toDouble(),
            timestamp: DateTime.parse(item['timestamp'] as String),
            accuracy: (item['accuracy'] as num?)?.toDouble(),
          ),
        )
        .toList(growable: false);

    final locationRecords =
        (json['collectedLocations'] as List<dynamic>? ?? <dynamic>[])
            .map(
              (dynamic item) =>
                  ActivityLocationRecord.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false);

    return ActivityDetail(
      activityId: json['activityId'] as String,
      userId: userId ?? '',
      userName: userName ?? '',
      userAvatar: userAvatar,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      distanceKm: (json['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
      averageSpeedKmh: (json['averageSpeed'] as num?)?.toDouble() ?? 0,
      route: route,
      locationRecords: locationRecords,
      totalCoinsEarned: (json['coinsEarned'] as num?)?.toInt() ?? 0,
    );
  }

  /// 格式化日期時間範圍 (e.g., "2024-01-15 14:30 - 15:45")
  String get formattedDateTimeRange {
    final startStr = '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')} '
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  /// 格式化距離 (e.g., "5.2 公里")
  String get formattedDistance {
    if (distanceKm == 0) {
      return '0 公里';
    }
    if (distanceKm == distanceKm.roundToDouble()) {
      return '${distanceKm.toInt()} 公里';
    }
    return '${distanceKm.toStringAsFixed(1)} 公里';
  }

  /// 格式化時長 (e.g., "1 時 15 分")
  String get formattedDuration {
    if (durationSeconds == 0) {
      return '0 分鐘';
    }
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '$hours 時 $minutes 分';
    }
    if (minutes > 0) {
      return '$minutes 分 $seconds 秒';
    }
    return '$seconds 秒';
  }
}
