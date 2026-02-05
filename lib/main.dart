import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dinosaur/service/account_service.dart';
import 'package:dinosaur/service/service.dart';
import 'package:dinosaur/page/home/api_service.dart';
import 'package:dinosaur/util/app_route.dart';
import 'package:dinosaur/util/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 載入 .env 文件
  await dotenv.load(fileName: ".env");
  
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
