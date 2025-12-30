import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/note_service.dart';

class NoteProvider with ChangeNotifier {
  final NoteService _noteService = NoteService();
  List<Note> _notes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedFolderId;
  List<String> _selectedTags = [];
  bool _showArchived = false;
  bool _showPinnedOnly = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedFolderId => _selectedFolderId;
  List<String> get selectedTags => _selectedTags;
  bool get showArchived => _showArchived;
  bool get showPinnedOnly => _showPinnedOnly;

  // Filtered notes
  List<Note> get filteredNotes {
    var filtered = _notes;
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }
    
    if (_selectedFolderId != null) {
      filtered = filtered.where((note) => note.folderId == _selectedFolderId).toList();
    }
    
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((note) {
        return _selectedTags.any((tag) => note.tags.contains(tag));
      }).toList();
    }
    
    if (_showPinnedOnly) {
      filtered = filtered.where((note) => note.isPinned).toList();
    }
    
    return filtered;
  }

  List<Note> get pinnedNotes => _notes.where((n) => n.isPinned && !n.isArchived && !n.isDeleted).toList();
  List<Note> get archivedNotes => _notes.where((n) => n.isArchived && !n.isDeleted).toList();
  List<Note> get trashNotes => _notes.where((n) => n.isDeleted).toList();

  // Load notes cho user
  Future<void> loadNotes(String userId, {
    bool includeArchived = false,
    bool includeDeleted = false,
  }) async {
    if (userId.isEmpty) {
      print('⚠️ Cannot load notes: userId is empty');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 Loading notes for user: $userId');
      _notes = await _noteService.getNotesByUserId(
        userId,
        includeArchived: includeArchived,
        includeDeleted: includeDeleted,
        folderId: _selectedFolderId,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
        isPinned: _showPinnedOnly ? true : null,
      );
      print('✅ Successfully loaded ${_notes.length} notes');
    } catch (e, stackTrace) {
      print('❌ Error loading notes: $e');
      print('Stack trace: $stackTrace');
      _notes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Filter
  void setFolderFilter(String? folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }

  void setTagsFilter(List<String> tags) {
    _selectedTags = tags;
    notifyListeners();
  }

  void toggleArchived() {
    _showArchived = !_showArchived;
    notifyListeners();
  }

  void togglePinnedOnly() {
    _showPinnedOnly = !_showPinnedOnly;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedFolderId = null;
    _selectedTags = [];
    _showArchived = false;
    _showPinnedOnly = false;
    notifyListeners();
  }

  // Tạo note mới
  Future<Note?> createNote({
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
    try {
      final note = await _noteService.createNote(
        userId: userId,
        title: title,
        content: content,
        color: color,
        type: type,
        folderId: folderId,
        tags: tags,
        isPinned: isPinned,
        reminderAt: reminderAt,
        repeatRule: repeatRule,
      );
      _notes.insert(0, note);
      notifyListeners();
      return note;
    } catch (e) {
      print('Error creating note: $e');
      return null;
    }
  }

  // Cập nhật note
  Future<bool> updateNote({
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
    try {
      final updatedNote = await _noteService.updateNote(
        noteId: noteId,
        userId: userId,
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
      );

      if (updatedNote != null) {
        final index = _notes.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          _notes[index] = updatedNote;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  // Pin/Unpin
  Future<bool> togglePin(String noteId, String userId) async {
    try {
      final success = await _noteService.togglePin(noteId, userId);
      if (success) {
        await loadNotes(userId, includeArchived: _showArchived);
      }
      return success;
    } catch (e) {
      print('Error toggling pin: $e');
      return false;
    }
  }

  // Archive/Unarchive
  Future<bool> toggleArchive(String noteId, String userId) async {
    try {
      final success = await _noteService.toggleArchive(noteId, userId);
      if (success) {
        await loadNotes(userId, includeArchived: _showArchived);
      }
      return success;
    } catch (e) {
      print('Error toggling archive: $e');
      return false;
    }
  }

  // Move to trash
  Future<bool> moveToTrash(String noteId, String userId) async {
    try {
      final success = await _noteService.moveToTrash(noteId, userId);
      if (success) {
        _notes.removeWhere((n) => n.id == noteId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error moving to trash: $e');
      return false;
    }
  }

  // Restore from trash
  Future<bool> restoreFromTrash(String noteId, String userId) async {
    try {
      final success = await _noteService.restoreFromTrash(noteId, userId);
      if (success) {
        await loadNotes(userId, includeArchived: true, includeDeleted: true);
      }
      return success;
    } catch (e) {
      print('Error restoring from trash: $e');
      return false;
    }
  }

  // Permanently delete
  Future<bool> permanentlyDelete(String noteId, String userId) async {
    try {
      final success = await _noteService.permanentlyDelete(noteId, userId);
      if (success) {
        _notes.removeWhere((n) => n.id == noteId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error permanently deleting: $e');
      return false;
    }
  }

  // Xóa note
  Future<bool> deleteNote(String noteId, String userId) async {
    try {
      final success = await _noteService.deleteNote(noteId, userId);
      if (success) {
        _notes.removeWhere((n) => n.id == noteId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }
}
