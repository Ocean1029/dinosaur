import 'package:json_annotation/json_annotation.dart';
import 'package:dinosaur/util/json_converter/datetime_string_converter.dart';

part 'user_data.g.dart';

/// Run City 用戶資料回應（符合後端 API 格式）
@JsonSerializable(explicitToJson: true)
class UserDataResponse {
  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'data')
  final UserProfile? data;

  @JsonKey(name: 'error')
  final Error? error;

  const UserDataResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory UserDataResponse.fromJson(Map<String, dynamic> json) =>
      _$UserDataResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataResponseToJson(this);
}

/// 錯誤回應格式
@JsonSerializable(explicitToJson: true)
class Error {
  @JsonKey(name: 'code')
  final String code;

  @JsonKey(name: 'message')
  final String message;

  const Error({
    required this.code,
    required this.message,
  });

  factory Error.fromJson(Map<String, dynamic> json) =>
      _$ErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorToJson(this);
}

/// Run City 用戶資料（符合後端 API 格式）
@JsonSerializable(explicitToJson: true)
class UserProfile {
  /// 用戶 ID
  @JsonKey(name: 'userId')
  final String userId;

  /// 用戶姓名
  @JsonKey(name: 'name')
  final String name;

  /// 用戶 Email
  @JsonKey(name: 'email')
  final String? email;

  /// 用戶頭貼 URL
  @JsonKey(name: 'avatar')
  final String? avatar;

  /// 已獲得金幣
  @JsonKey(name: 'totalCoins')
  final int totalCoins;

  /// 累積距離（公尺）
  @JsonKey(name: 'totalDistance')
  final double? totalDistance;

  /// 累積時間（秒）
  @JsonKey(name: 'totalTime')
  final int? totalTime;

  /// 建立時間
  @DateTimeStringConverter()
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  /// 最後更新時間
  @DateTimeStringConverter()
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    required this.name,
    this.email,
    this.avatar,
    required this.totalCoins,
    this.totalDistance,
    this.totalTime,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  /// 取得頭貼 URL（兼容舊的 avatarUrl 欄位名）
  String? get avatarUrl => avatar;

  /// 取得開通日期（使用 createdAt）
  DateTime? get activatedAt => createdAt;

  /// 格式化累積距離
  /// 後端返回的 totalDistance 單位為公里
  String get formattedTotalDistance {
    if (totalDistance == null || totalDistance == 0) {
      return '0 公里';
    }
    // 後端返回的單位是公里，一律顯示為X.X公里
    // 如果距離是整數，不顯示小數點
    if (totalDistance! == totalDistance!.roundToDouble()) {
      return '${totalDistance!.toInt()} 公里';
    }
    return '${totalDistance!.toStringAsFixed(1)} 公里';
  }

  /// 格式化累積時間
  String get formattedTotalTime {
    if (totalTime == null || totalTime == 0) {
      return '0 分鐘';
    }
    final hours = totalTime! ~/ 3600;
    final minutes = (totalTime! % 3600) ~/ 60;
    final seconds = totalTime! % 60;
    if (hours > 0) {
      return '${hours} 時 ${minutes} 分';
    }
    if (minutes > 0) {
      return '${minutes} 分 ${seconds} 秒';
    }
    return '${seconds} 秒';
  }
}

