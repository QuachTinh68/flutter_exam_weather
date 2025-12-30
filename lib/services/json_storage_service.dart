import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// Conditional imports - import dart:io on non-web, stub on web
import 'dart:io' if (dart.library.html) 'file_storage_stub.dart' show Directory, File;
import 'package:path_provider/path_provider.dart' if (dart.library.html) 'path_provider_web_stub.dart' show getApplicationDocumentsDirectory;

/// Service quản lý database JSON
/// 
/// Database được lưu trong file `mock_database.json` với cấu trúc:
/// {
///   "users": [
///     {
///       "id": "string",
///       "username": "string",
///       "email": "string",
///       "password": "string"
///     }
///   ],
///   "notes": [
///     {
///       "id": "string",
///       "userId": "string",  // Liên kết với user
///       "title": "string",
///       "content": "string",
///       "color": "string",
///       "type": "string",
///       "createdAt": "ISO8601",
///       "updatedAt": "ISO8601"
///     }
///   ],
///   "currentUser": { ... } | null
/// }
/// 
/// - Trên Web: Lưu vào localStorage (SharedPreferences)
/// - Trên Mobile/Desktop: Lưu vào file JSON trong documents directory
class JsonStorageService {
  // Tên file JSON duy nhất chứa tất cả dữ liệu
  static const String _databaseFileName = 'mock_database.json';
  static const String _databaseKey = 'weather_app_database_json';

  // Helper method to get documents directory (ONLY for non-web)
  Future<dynamic> _getDocumentsDirectory() async {
    // Early return for web - never touch path_provider
    if (kIsWeb) {
      return null;
    }
    
    // Only execute this on mobile/desktop
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      return null;
    }
  }

  // Lấy đường dẫn file database (ONLY for non-web)
  Future<File?> _getDatabaseFile() async {
    // Early return for web - never use File/Directory
    if (kIsWeb) return null;
    
    try {
      final directory = await _getDocumentsDirectory();
      if (directory == null) return null;
      
      // Use File and Directory - will be stub on web, real on mobile/desktop
      final dataDir = Directory('${directory.path}/weather_app_data');
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      return File('${dataDir.path}/$_databaseFileName');
    } catch (e) {
      return null;
    }
  }

  // Đọc toàn bộ database từ file JSON
  Future<Map<String, dynamic>> _loadDatabase() async {
    try {
      if (kIsWeb) {
        // Web: Sử dụng shared_preferences (localStorage)
        final prefs = await SharedPreferences.getInstance();
        final jsonString = prefs.getString(_databaseKey);
        if (jsonString != null) {
          final decoded = jsonDecode(jsonString);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        }
      } else {
        // Mobile/Desktop: Đọc từ file JSON
        final file = await _getDatabaseFile();
        if (file != null && await file.exists()) {
          final content = await file.readAsString();
          final decoded = jsonDecode(content);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        }
      }
    } catch (e) {
      print('Error loading database: $e');
    }
    
    // Trả về database mặc định nếu chưa có
    return {
      'users': [],
      'notes': [],
      'folders': [],
      'tags': [],
      'currentUser': null,
    };
  }

  // Lưu toàn bộ database vào file JSON
  Future<void> _saveDatabase(Map<String, dynamic> database) async {
    try {
      if (kIsWeb) {
        // Web: Sử dụng shared_preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_databaseKey, jsonEncode(database));
        print('🌐 Đã lưu database vào localStorage (web)');
        return;
      } else {
        // Mobile/Desktop: Lưu vào file JSON với format đẹp
        final file = await _getDatabaseFile();
        if (file != null) {
          // Format JSON với indent để dễ đọc
          const encoder = JsonEncoder.withIndent('  ');
          await file.writeAsString(encoder.convert(database));
          print('📁 Đã lưu database vào file: ${file.path}');
          print('📊 Tổng số users: ${(database['users'] as List?)?.length ?? 0}');
          print('📝 Tổng số notes: ${(database['notes'] as List?)?.length ?? 0}');
          return;
        }
      }
    } catch (e) {
      print('❌ Error saving database: $e');
    }
    
    // Fallback to shared_preferences if file system fails
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_databaseKey, jsonEncode(database));
      print('💾 Đã lưu database vào shared_preferences (fallback)');
    } catch (e) {
      print('❌ Error saving to shared_preferences: $e');
    }
  }

  // ========== USER METHODS ==========

  // Lưu danh sách users
  Future<void> saveUsers(List<Map<String, dynamic>> users) async {
    final database = await _loadDatabase();
    database['users'] = users;
    await _saveDatabase(database);
    print('💾 Đã lưu ${users.length} users vào database');
  }

  // Đọc danh sách users
  Future<List<Map<String, dynamic>>> loadUsers() async {
    final database = await _loadDatabase();
    final users = database['users'];
    if (users is List) {
      return List<Map<String, dynamic>>.from(users);
    }
    return [];
  }

  // Lưu user hiện tại
  Future<void> saveCurrentUser(Map<String, dynamic>? user) async {
    final database = await _loadDatabase();
    database['currentUser'] = user;
    await _saveDatabase(database);
  }

  // Đọc user hiện tại
  Future<Map<String, dynamic>?> loadCurrentUser() async {
    final database = await _loadDatabase();
    final currentUser = database['currentUser'];
    if (currentUser is Map) {
      return Map<String, dynamic>.from(currentUser);
    }
    return null;
  }

  // ========== NOTE METHODS ==========

  // Lưu danh sách notes
  Future<void> saveNotes(List<Map<String, dynamic>> notes) async {
    final database = await _loadDatabase();
    database['notes'] = notes;
    await _saveDatabase(database);
  }

  // Đọc danh sách notes
  Future<List<Map<String, dynamic>>> loadNotes() async {
    final database = await _loadDatabase();
    final notes = database['notes'];
    if (notes is List) {
      return List<Map<String, dynamic>>.from(notes);
    }
    return [];
  }

  // Xóa tất cả dữ liệu (cho testing)
  Future<void> clearAllData() async {
    final emptyDatabase = {
      'users': [],
      'notes': [],
      'folders': [],
      'tags': [],
      'currentUser': null,
    };
    await _saveDatabase(emptyDatabase);
  }

  // Export database để xem (cho debugging)
  Future<Map<String, dynamic>> exportDatabase() async {
    return await _loadDatabase();
  }

  // Import database (cho testing hoặc backup/restore)
  Future<void> importDatabase(Map<String, dynamic> database) async {
    await _saveDatabase(database);
  }

  // Lấy đường dẫn file database (để người dùng có thể xem/backup)
  Future<String?> getDatabaseFilePath() async {
    if (kIsWeb) {
      return 'Web: localStorage (key: $_databaseKey)';
    }
    final file = await _getDatabaseFile();
    return file?.path;
  }

  // Kiểm tra file database có tồn tại không
  Future<bool> databaseFileExists() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_databaseKey);
    }
    final file = await _getDatabaseFile();
    return file != null && await file.exists();
  }

  // ========== DATABASE STATISTICS & VALIDATION ==========

  // Lấy thống kê database
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final database = await _loadDatabase();
    final users = database['users'] as List? ?? [];
    final notes = database['notes'] as List? ?? [];

    // Đếm số notes theo từng user
    final Map<String, int> notesByUser = {};
    for (var note in notes) {
      final userId = note['userId'] as String? ?? 'unknown';
      notesByUser[userId] = (notesByUser[userId] ?? 0) + 1;
    }

    return {
      'totalUsers': users.length,
      'totalNotes': notes.length,
      'notesByUser': notesByUser,
      'currentUser': database['currentUser'] != null ? 'logged_in' : 'not_logged_in',
    };
  }

  // Validate tính toàn vẹn dữ liệu (kiểm tra notes có userId hợp lệ không)
  Future<Map<String, dynamic>> validateDatabaseIntegrity() async {
    final database = await _loadDatabase();
    final users = database['users'] as List? ?? [];
    final notes = database['notes'] as List? ?? [];

    final List<String> errors = [];
    final List<String> warnings = [];

    // Lấy danh sách userId hợp lệ
    final validUserIds = users.map((u) => u['id'] as String).toSet();

    // Kiểm tra notes có userId hợp lệ không
    int orphanNotes = 0;
    for (var note in notes) {
      final userId = note['userId'] as String?;
      if (userId == null || userId.isEmpty) {
        errors.add('Note ${note['id']} không có userId');
      } else if (!validUserIds.contains(userId)) {
        orphanNotes++;
        warnings.add('Note ${note['id']} có userId không tồn tại: $userId');
      }
    }

    // Kiểm tra currentUser có hợp lệ không
    final currentUser = database['currentUser'];
    if (currentUser != null) {
      final currentUserId = currentUser['id'] as String?;
      if (currentUserId == null || !validUserIds.contains(currentUserId)) {
        warnings.add('currentUser không hợp lệ hoặc không tồn tại');
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'orphanNotes': orphanNotes,
      'totalUsers': users.length,
      'totalNotes': notes.length,
    };
  }

  // Dọn dẹp database (xóa notes không có userId hợp lệ)
  Future<Map<String, dynamic>> cleanupDatabase() async {
    final database = await _loadDatabase();
    final users = database['users'] as List? ?? [];
    final notes = database['notes'] as List? ?? [];

    final validUserIds = users.map((u) => u['id'] as String).toSet();
    final initialNoteCount = notes.length;

    // Xóa notes không có userId hợp lệ
    notes.removeWhere((note) {
      final userId = note['userId'] as String?;
      return userId == null || userId.isEmpty || !validUserIds.contains(userId);
    });

    final removedCount = initialNoteCount - notes.length;

    if (removedCount > 0) {
      database['notes'] = notes;
      await _saveDatabase(database);
      print('🧹 Đã dọn dẹp $removedCount notes không hợp lệ');
    }

    return {
      'removedNotes': removedCount,
      'remainingNotes': notes.length,
    };
  }

  // Lấy tất cả notes của một user cụ thể
  Future<List<Map<String, dynamic>>> getNotesByUserId(String userId) async {
    final notes = await loadNotes();
    return notes.where((n) => n['userId'] == userId).toList();
  }

  // Kiểm tra user có tồn tại không
  Future<bool> userExists(String userId) async {
    final users = await loadUsers();
    return users.any((u) => u['id'] == userId);
  }

  // ========== FOLDER METHODS ==========

  // Lưu danh sách folders
  Future<void> saveFolders(List<Map<String, dynamic>> folders) async {
    final database = await _loadDatabase();
    database['folders'] = folders;
    await _saveDatabase(database);
  }

  // Đọc danh sách folders
  Future<List<Map<String, dynamic>>> loadFolders() async {
    final database = await _loadDatabase();
    final folders = database['folders'];
    if (folders is List) {
      return List<Map<String, dynamic>>.from(folders);
    }
    return [];
  }

  // ========== TAG METHODS ==========

  // Lưu danh sách tags
  Future<void> saveTags(List<Map<String, dynamic>> tags) async {
    final database = await _loadDatabase();
    database['tags'] = tags;
    await _saveDatabase(database);
  }

  // Đọc danh sách tags
  Future<List<Map<String, dynamic>>> loadTags() async {
    final database = await _loadDatabase();
    final tags = database['tags'];
    if (tags is List) {
      return List<Map<String, dynamic>>.from(tags);
    }
    return [];
  }
}