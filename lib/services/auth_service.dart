import '../models/user.dart';
import 'json_storage_service.dart';

class AuthService {
  final JsonStorageService _storageService = JsonStorageService();

  // Đăng ký
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    // Kiểm tra username/email đã tồn tại chưa
    final users = await _storageService.loadUsers();
    
    if (users.any((u) => u['username'] == username)) {
      return {'success': false, 'message': 'Username đã tồn tại'};
    }
    
    if (users.any((u) => u['email'] == email)) {
      return {'success': false, 'message': 'Email đã tồn tại'};
    }

    // Tạo user mới
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      email: email,
      password: password, // Trong thực tế nên hash
    );

    users.add(newUser.toJson());
    await _storageService.saveUsers(users);

    print('✅ Đã thêm user mới vào database: ${newUser.username}');
    print('📊 Tổng số users trong database: ${users.length}');

    return {
      'success': true,
      'message': 'Đăng ký thành công',
      'user': newUser.toJson(),
    };
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final users = await _storageService.loadUsers();
    
    final user = users.firstWhere(
      (u) => u['username'] == username && u['password'] == password,
      orElse: () => {},
    );

    if (user.isEmpty) {
      return {'success': false, 'message': 'Username hoặc password không đúng'};
    }

    // Lưu user hiện tại
    await _storageService.saveCurrentUser(user);

    return {
      'success': true,
      'message': 'Đăng nhập thành công',
      'user': user,
    };
  }

  // Đăng xuất
  Future<void> logout() async {
    await _storageService.saveCurrentUser(null);
  }

  // Lấy user hiện tại
  Future<User?> getCurrentUser() async {
    final userJson = await _storageService.loadCurrentUser();
    if (userJson != null) {
      return User.fromJson(userJson);
    }
    return null;
  }

  // Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final currentUser = await getCurrentUser();
    return currentUser != null;
  }

  // Cập nhật thông tin user
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? username,
    String? email,
    String? password,
  }) async {
    final users = await _storageService.loadUsers();
    final userIndex = users.indexWhere((u) => u['id'] == userId);

    if (userIndex == -1) {
      return {'success': false, 'message': 'User không tồn tại'};
    }

    // Kiểm tra username/email mới có trùng không (nếu có thay đổi)
    if (username != null && username != users[userIndex]['username']) {
      if (users.any((u) => u['username'] == username && u['id'] != userId)) {
        return {'success': false, 'message': 'Username đã tồn tại'};
      }
    }

    if (email != null && email != users[userIndex]['email']) {
      if (users.any((u) => u['email'] == email && u['id'] != userId)) {
        return {'success': false, 'message': 'Email đã tồn tại'};
      }
    }

    // Cập nhật thông tin
    if (username != null) users[userIndex]['username'] = username;
    if (email != null) users[userIndex]['email'] = email;
    if (password != null) users[userIndex]['password'] = password;

    await _storageService.saveUsers(users);

    // Cập nhật currentUser nếu đang là user hiện tại
    final currentUser = await _storageService.loadCurrentUser();
    if (currentUser != null && currentUser['id'] == userId) {
      await _storageService.saveCurrentUser(users[userIndex]);
    }

    print('✅ Đã cập nhật thông tin user: ${users[userIndex]['username']}');

    return {
      'success': true,
      'message': 'Cập nhật thành công',
      'user': users[userIndex],
    };
  }

  // Xóa user (và tất cả notes của user đó)
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    final users = await _storageService.loadUsers();
    final userIndex = users.indexWhere((u) => u['id'] == userId);

    if (userIndex == -1) {
      return {'success': false, 'message': 'User không tồn tại'};
    }

    final username = users[userIndex]['username'];

    // Xóa tất cả notes của user
    final notes = await _storageService.loadNotes();
    notes.removeWhere((n) => n['userId'] == userId);
    await _storageService.saveNotes(notes);

    // Xóa user
    users.removeAt(userIndex);
    await _storageService.saveUsers(users);

    // Nếu là user hiện tại, đăng xuất
    final currentUser = await _storageService.loadCurrentUser();
    if (currentUser != null && currentUser['id'] == userId) {
      await _storageService.saveCurrentUser(null);
    }

    print('✅ Đã xóa user: $username và ${notes.length} notes liên quan');

    return {
      'success': true,
      'message': 'Đã xóa user và tất cả notes liên quan',
    };
  }

  // Lấy thông tin user theo ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final users = await _storageService.loadUsers();
    try {
      return users.firstWhere((u) => u['id'] == userId);
    } catch (e) {
      return null;
    }
  }
}
