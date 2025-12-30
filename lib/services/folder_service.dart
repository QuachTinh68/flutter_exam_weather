import '../models/folder.dart';
import 'json_storage_service.dart';

class FolderService {
  final JsonStorageService _storageService = JsonStorageService();

  // Lấy tất cả folders của user
  Future<List<Folder>> getFoldersByUserId(String userId) async {
    try {
      final foldersJson = await _storageService.loadFolders();
      final userFolders = foldersJson
          .where((f) => f['userId'] == userId)
          .map((f) => Folder.fromJson(f))
          .toList();
      
      userFolders.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return userFolders;
    } catch (e) {
      print('Error loading folders: $e');
      return [];
    }
  }

  // Tạo folder mới
  Future<Folder> createFolder({
    required String userId,
    required String name,
    String? icon,
    String? color,
  }) async {
    final newFolder = Folder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      icon: icon,
      color: color,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );

    final foldersJson = await _storageService.loadFolders();
    foldersJson.add(newFolder.toJson());
    await _storageService.saveFolders(foldersJson);

    return newFolder;
  }

  // Cập nhật folder
  Future<Folder?> updateFolder({
    required String folderId,
    required String userId,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    final foldersJson = await _storageService.loadFolders();
    final folderIndex = foldersJson.indexWhere(
      (f) => f['id'] == folderId && f['userId'] == userId,
    );

    if (folderIndex == -1) return null;

    final existingFolder = Folder.fromJson(foldersJson[folderIndex]);
    final updatedFolder = existingFolder.copyWith(
      name: name,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
    );

    foldersJson[folderIndex] = updatedFolder.toJson();
    await _storageService.saveFolders(foldersJson);

    return updatedFolder;
  }

  // Xóa folder
  Future<bool> deleteFolder(String folderId, String userId) async {
    final foldersJson = await _storageService.loadFolders();
    final initialLength = foldersJson.length;
    
    foldersJson.removeWhere(
      (f) => f['id'] == folderId && f['userId'] == userId,
    );

    if (foldersJson.length < initialLength) {
      await _storageService.saveFolders(foldersJson);
      return true;
    }
    return false;
  }
}

