import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'json_storage_service.dart';

/// Service để khởi tạo database từ file mock hoặc tạo database mới
class DatabaseInitializer {
  final JsonStorageService _storageService = JsonStorageService();

  /// Khởi tạo database từ file mock (nếu chưa có dữ liệu)
  Future<void> initializeIfEmpty() async {
    try {
      // Kiểm tra xem đã có dữ liệu chưa
      final existingUsers = await _storageService.loadUsers();
      final existingNotes = await _storageService.loadNotes();

      // Nếu chưa có dữ liệu, khởi tạo từ file mock
      if (existingUsers.isEmpty && existingNotes.isEmpty) {
        // Trên web, không thể load từ assets, nên tạo database trống
        if (kIsWeb) {
          await _storageService.clearAllData();
          print('Web platform: Created empty database');
        } else {
          try {
            // Đọc file mock từ assets (chỉ cho mobile/desktop)
            final String mockDataString = await rootBundle.loadString('assets/database/mock_database.json');
            final Map<String, dynamic> mockDatabase = jsonDecode(mockDataString);

            // Import database từ mock data
            await _storageService.importDatabase(mockDatabase);
            print('Database initialized from mock data');
          } catch (e) {
            // Nếu không load được từ assets, tạo database trống
            print('Could not load mock data: $e. Creating empty database.');
            await _storageService.clearAllData();
          }
        }
      }
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  /// Reset database về trạng thái ban đầu (xóa tất cả dữ liệu)
  Future<void> resetDatabase() async {
    await _storageService.clearAllData();
  }
}
