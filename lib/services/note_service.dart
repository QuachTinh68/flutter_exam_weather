import '../models/note.dart';
import 'json_storage_service.dart';

class NoteService {
  final JsonStorageService _storageService = JsonStorageService();

  // Lấy tất cả notes của user (không bao gồm deleted)
  Future<List<Note>> getNotesByUserId(String userId, {
    bool includeArchived = false,
    bool includeDeleted = false,
    String? folderId,
    List<String>? tags,
    bool? isPinned,
  }) async {
    try {
      final notesJson = await _storageService.loadNotes();
      print('📝 Loading notes for user: $userId, total notes in DB: ${notesJson.length}');
      
      final userNotes = <Note>[];
      for (var noteJson in notesJson) {
        try {
          if (noteJson['userId'] == userId) {
            final note = Note.fromJson(noteJson);
            
            // Filter deleted
            if (!includeDeleted && note.isDeleted) continue;
            
            // Filter archived
            if (!includeArchived && note.isArchived) continue;
            
            // Filter folder
            if (folderId != null && note.folderId != folderId) continue;
            
            // Filter tags
            if (tags != null && tags.isNotEmpty) {
              if (!tags.any((tag) => note.tags.contains(tag))) continue;
            }
            
            // Filter pinned
            if (isPinned != null && note.isPinned != isPinned) continue;
            
            userNotes.add(note);
          }
        } catch (e) {
          print('⚠️ Error parsing note: $e, noteJson: $noteJson');
        }
      }
      
      // Sắp xếp: pinned trước, sau đó theo thời gian cập nhật
      userNotes.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      
      print('✅ Loaded ${userNotes.length} notes for user: $userId');
      return userNotes;
    } catch (e) {
      print('❌ Error loading notes for user $userId: $e');
      return [];
    }
  }

  // Tạo note mới
  Future<Note> createNote({
    required String userId,
    String title = '',
    String content = '',
    String color = '#FFFFFF',
    String type = 'text',
    String? folderId,
    List<String> tags = const [],
    bool isPinned = false,
    DateTime? reminderAt,
    String? repeatRule,
  }) async {
    final now = DateTime.now();
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title.isEmpty ? 'Untitled' : title,
      content: content,
      color: color,
      type: type,
      folderId: folderId,
      tags: tags,
      isPinned: isPinned,
      reminderAt: reminderAt,
      repeatRule: repeatRule,
      createdAt: now,
      updatedAt: now,
    );

    final notesJson = await _storageService.loadNotes();
    notesJson.add(newNote.toJson());
    await _storageService.saveNotes(notesJson);

    print('✅ Created note: ${newNote.id}');
    return newNote;
  }

  // Cập nhật note
  Future<Note?> updateNote({
    required String noteId,
    required String userId,
    String? title,
    String? content,
    String? color,
    String? type,
    String? folderId,
    List<String>? tags,
    bool? isPinned,
    bool? isArchived,
    DateTime? reminderAt,
    String? repeatRule,
  }) async {
    final notesJson = await _storageService.loadNotes();
    final noteIndex = notesJson.indexWhere(
      (n) => n['id'] == noteId && n['userId'] == userId,
    );

    if (noteIndex == -1) return null;

    final existingNote = Note.fromJson(notesJson[noteIndex]);
    final updatedNote = existingNote.copyWith(
      title: title,
      content: content,
      color: color,
      type: type,
      folderId: folderId,
      tags: tags,
      isPinned: isPinned,
      isArchived: isArchived,
      reminderAt: reminderAt,
      repeatRule: repeatRule,
      updatedAt: DateTime.now(),
    );

    notesJson[noteIndex] = updatedNote.toJson();
    await _storageService.saveNotes(notesJson);

    return updatedNote;
  }

  // Xóa note (soft delete - move to trash)
  Future<bool> deleteNote(String noteId, String userId) async {
    return await moveToTrash(noteId, userId);
  }

  // Lấy note theo ID
  Future<Note?> getNoteById(String noteId, String userId) async {
    final notesJson = await _storageService.loadNotes();
    try {
      final noteJson = notesJson.firstWhere(
        (n) => n['id'] == noteId && n['userId'] == userId,
      );
      return Note.fromJson(noteJson);
    } catch (e) {
      return null;
    }
  }

  // Đếm số notes của user
  Future<int> getNoteCountByUserId(String userId) async {
    final notes = await getNotesByUserId(userId);
    return notes.length;
  }

  // Lấy notes theo type
  Future<List<Note>> getNotesByType(String userId, String type) async {
    final notes = await getNotesByUserId(userId);
    return notes.where((n) => n.type == type).toList();
  }

  // Tìm kiếm notes theo từ khóa
  Future<List<Note>> searchNotes(String userId, String keyword, {
    bool includeArchived = false,
    bool includeDeleted = false,
  }) async {
    final notes = await getNotesByUserId(
      userId,
      includeArchived: includeArchived,
      includeDeleted: includeDeleted,
    );
    final lowerKeyword = keyword.toLowerCase();
    return notes.where((note) {
      return note.title.toLowerCase().contains(lowerKeyword) ||
          note.content.toLowerCase().contains(lowerKeyword) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowerKeyword));
    }).toList();
  }

  // Pin/Unpin note
  Future<bool> togglePin(String noteId, String userId) async {
    final notesJson = await _storageService.loadNotes();
    final noteIndex = notesJson.indexWhere(
      (n) => n['id'] == noteId && n['userId'] == userId,
    );

    if (noteIndex == -1) return false;

    final note = Note.fromJson(notesJson[noteIndex]);
    final updatedNote = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );

    notesJson[noteIndex] = updatedNote.toJson();
    await _storageService.saveNotes(notesJson);
    return true;
  }

  // Archive/Unarchive note
  Future<bool> toggleArchive(String noteId, String userId) async {
    final notesJson = await _storageService.loadNotes();
    final noteIndex = notesJson.indexWhere(
      (n) => n['id'] == noteId && n['userId'] == userId,
    );

    if (noteIndex == -1) return false;

    final note = Note.fromJson(notesJson[noteIndex]);
    final updatedNote = note.copyWith(
      isArchived: !note.isArchived,
      updatedAt: DateTime.now(),
    );

    notesJson[noteIndex] = updatedNote.toJson();
    await _storageService.saveNotes(notesJson);
    return true;
  }

  // Soft delete (move to trash)
  Future<bool> moveToTrash(String noteId, String userId) async {
    final notesJson = await _storageService.loadNotes();
    final noteIndex = notesJson.indexWhere(
      (n) => n['id'] == noteId && n['userId'] == userId,
    );

    if (noteIndex == -1) return false;

    final note = Note.fromJson(notesJson[noteIndex]);
    final updatedNote = note.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    notesJson[noteIndex] = updatedNote.toJson();
    await _storageService.saveNotes(notesJson);
    return true;
  }

  // Restore from trash
  Future<bool> restoreFromTrash(String noteId, String userId) async {
    final notesJson = await _storageService.loadNotes();
    final noteIndex = notesJson.indexWhere(
      (n) => n['id'] == noteId && n['userId'] == userId,
    );

    if (noteIndex == -1) return false;

    final note = Note.fromJson(notesJson[noteIndex]);
    final updatedNote = note.copyWith(
      deletedAt: null,
      updatedAt: DateTime.now(),
    );

    notesJson[noteIndex] = updatedNote.toJson();
    await _storageService.saveNotes(notesJson);
    return true;
  }

  // Permanently delete
  Future<bool> permanentlyDelete(String noteId, String userId) async {
    final notesJson = await _storageService.loadNotes();
    final initialLength = notesJson.length;
    
    notesJson.removeWhere(
      (n) => n['id'] == noteId && n['userId'] == userId,
    );

    if (notesJson.length < initialLength) {
      await _storageService.saveNotes(notesJson);
      return true;
    }
    return false;
  }

  // Xóa tất cả notes của một user
  Future<int> deleteAllNotesByUserId(String userId) async {
    final notesJson = await _storageService.loadNotes();
    final initialLength = notesJson.length;
    
    notesJson.removeWhere((n) => n['userId'] == userId);
    
    final deletedCount = initialLength - notesJson.length;
    if (deletedCount > 0) {
      await _storageService.saveNotes(notesJson);
      print('🗑️ Đã xóa $deletedCount notes của user $userId');
    }
    
    return deletedCount;
  }
}
