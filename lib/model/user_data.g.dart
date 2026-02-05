// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDataResponse _$UserDataResponseFromJson(Map<String, dynamic> json) =>
    UserDataResponse(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : UserProfile.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : Error.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserDataResponseToJson(UserDataResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data?.toJson(),
      'error': instance.error?.toJson(),
    };

Error _$ErrorFromJson(Map<String, dynamic> json) => Error(
      code: json['code'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$ErrorToJson(Error instance) => <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
    };

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      totalCoins: (json['totalCoins'] as num).toInt(),
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
      totalTime: (json['totalTime'] as num?)?.toInt(),
      createdAt: _$JsonConverterFromJson<String, DateTime>(
          json['createdAt'], const DateTimeStringConverter().fromJson),
      updatedAt: _$JsonConverterFromJson<String, DateTime>(
          json['updatedAt'], const DateTimeStringConverter().fromJson),
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'avatar': instance.avatar,
      'totalCoins': instance.totalCoins,
      'totalDistance': instance.totalDistance,
      'totalTime': instance.totalTime,
      'createdAt': _$JsonConverterToJson<String, DateTime>(
          instance.createdAt, const DateTimeStringConverter().toJson),
      'updatedAt': _$JsonConverterToJson<String, DateTime>(
          instance.updatedAt, const DateTimeStringConverter().toJson),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
