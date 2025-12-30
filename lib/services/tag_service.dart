import '../models/tag.dart';
import 'json_storage_service.dart';

class TagService {
  final JsonStorageService _storageService = JsonStorageService();

  // Lấy tất cả tags của user
  Future<List<Tag>> getTagsByUserId(String userId) async {
    try {
      final tagsJson = await _storageService.loadTags();
      final userTags = tagsJson
          .where((t) => t['userId'] == userId)
          .map((t) => Tag.fromJson(t))
          .toList();
      
      return userTags;
    } catch (e) {
      print('Error loading tags: $e');
      return [];
    }
  }

  // Tạo tag mới
  Future<Tag> createTag({
    required String userId,
    required String name,
    String? color,
  }) async {
    final newTag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      color: color,
      createdAt: DateTime.now(),
    );

    final tagsJson = await _storageService.loadTags();
    tagsJson.add(newTag.toJson());
    await _storageService.saveTags(tagsJson);

    return newTag;
  }

  // Cập nhật tag
  Future<Tag?> updateTag({
    required String tagId,
    required String userId,
    String? name,
    String? color,
  }) async {
    final tagsJson = await _storageService.loadTags();
    final tagIndex = tagsJson.indexWhere(
      (t) => t['id'] == tagId && t['userId'] == userId,
    );

    if (tagIndex == -1) return null;

    final existingTag = Tag.fromJson(tagsJson[tagIndex]);
    final updatedTag = existingTag.copyWith(
      name: name,
      color: color,
    );

    tagsJson[tagIndex] = updatedTag.toJson();
    await _storageService.saveTags(tagsJson);

    return updatedTag;
  }

  // Xóa tag
  Future<bool> deleteTag(String tagId, String userId) async {
    final tagsJson = await _storageService.loadTags();
    final initialLength = tagsJson.length;
    
    tagsJson.removeWhere(
      (t) => t['id'] == tagId && t['userId'] == userId,
    );

    if (tagsJson.length < initialLength) {
      await _storageService.saveTags(tagsJson);
      return true;
    }
    return false;
  }
}

