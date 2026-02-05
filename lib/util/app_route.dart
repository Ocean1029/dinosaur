import 'package:get/get.dart';
import 'package:dinosaur/page/home/home_view.dart';
import 'package:dinosaur/page/home/home_controller.dart';
import 'package:dinosaur/page/stats/stats_view.dart';
import 'package:dinosaur/page/stats/stats_controller.dart';
import 'package:dinosaur/page/activity_detail/activity_detail_view.dart';
import 'package:dinosaur/page/activity_detail/activity_detail_controller.dart';
import 'package:dinosaur/page/badge_detail/badge_detail_view.dart';
import 'package:dinosaur/page/badge_detail/badge_detail_controller.dart';

/// 應用程式路由管理
abstract final class AppRoute {
  static const String home = '/home';
  static const String homeStats = '/home-stats'; // 向後兼容
  static const String stats = '/stats';
  static const String activityDetail = '/activity-detail';
  static const String homeActivityDetail = '/home-activity-detail'; // 向後兼容
  static const String homeBadgeDetail = '/home-badge-detail'; // 向後兼容
  static const String badgeDetail = '/badge-detail';

  static final List<GetPage> pages = [
    GetPage(
      name: home,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
    GetPage(
      name: stats,
      page: () => const StatsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StatsController>(() => StatsController());
      }),
    ),
    GetPage(
      name: activityDetail,
      page: () => const ActivityDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ActivityDetailController>(() => ActivityDetailController());
      }),
    ),
    GetPage(
      name: badgeDetail,
      page: () => const BadgeDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BadgeDetailController>(() => BadgeDetailController());
      }),
    ),
  ];
}
