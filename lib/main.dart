import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:dinosaur/service/account_service.dart';
import 'package:dinosaur/service/service.dart';
import 'package:dinosaur/page/home/api_service.dart';
import 'package:dinosaur/util/app_route.dart';
import 'package:dinosaur/util/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 捕獲未處理的 Dart 錯誤與 Flutter 框架錯誤，方便排查閃退（「Lost connection to device」多為原生崩潰）
  runZonedGuarded(() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exception}\n${details.stack}');
    };
    await _runApp();
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

Future<void> _runApp() async {

  // 載入 .env 文件（若檔案不存在則略過，避免閃退）
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('dotenv: .env 未找到或載入失敗，使用預設值: $e');
  }

  // 初始化 Mapbox Access Token（建議用 public token: pk. 開頭）
  try {
    final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    if (mapboxToken.isNotEmpty) {
      MapboxOptions.setAccessToken(mapboxToken);
    } else {
      debugPrint('Mapbox token is empty. Please set MAPBOX_ACCESS_TOKEN in .env');
    }
  } catch (e) {
    debugPrint('Failed to set Mapbox access token: $e');
  }

  // 初始化 iOS Google Maps API Key
  await initGoogleMapsApiKey();

  await initServices();
  runApp(const MyApp());
}

/// 初始化 Google Maps API Key（iOS）
Future<void> initGoogleMapsApiKey() async {
  try {
    const platform = MethodChannel('com.example.dinosaur/google_maps');
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      await platform.invokeMethod('setApiKey', {'apiKey': apiKey});
    }
  } catch (e) {
    // 如果平台不支持或出錯，忽略（可能是 Android 或其他平台）
    debugPrint('Failed to set Google Maps API Key: $e');
  }
}

Future<void> initServices() async {
  // 初始化 AccountService（簡化版，等待登入系統實作）
  await Get.putAsync<AccountService>(
    () async => await AccountService().init(),
  );
  
  // 初始化服務
  Get.put<ApiService>(ApiService());
  Get.put<Service>(Service());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Dinosaur',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.grayscale50,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary500,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0.0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoute.home,
      getPages: AppRoute.pages,
    );
  }
}
