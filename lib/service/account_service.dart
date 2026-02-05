import 'package:get/get.dart';

/// 簡化版的 Account 模型
class Account {
  final String id;
  final String username;
  final String? name;
  final String? email;
  final String? avatar;

  const Account({
    required this.id,
    required this.username,
    this.name,
    this.email,
    this.avatar,
  });
}

/// 簡化版的 AccountService
/// TODO: 實作您自己的登入系統後，更新此服務
class AccountService extends GetxService {
  Account? _account;

  Account? get account => _account;

  Future<AccountService> init() async {
    // 建立預設用戶以跳過登入流程，方便測試
    // 注意：ID 必須是 UUID 格式，符合後端驗證要求
    _account = const Account(
      id: '550e8400-e29b-41d4-a716-446655440000', // UUID 格式
      username: 'testuser',
      name: '測試用戶',
      email: 'test@example.com',
      avatar: null,
    );
    return this;
  }

  void updateAccount(Account account) {
    _account = account;
  }

  void logout() {
    _account = null;
    // TODO: 清除本地儲存的認證資訊
  }

  bool get isLoggedIn => _account != null;
}