import 'package:json_annotation/json_annotation.dart';

/// DateTime Converter for ISO 8601 string format
/// 後端傳入的時間都是 UTC (GMT+0)，自動轉換為 GMT+8
class DateTimeStringConverter implements JsonConverter<DateTime, String> {
  const DateTimeStringConverter();

  @override
  DateTime fromJson(String json) {
    final utcTime = DateTime.parse(json).toUtc();
    return utcTime.add(const Duration(hours: 8));
  }

  @override
  String toJson(DateTime datetime) => datetime.toIso8601String();
}