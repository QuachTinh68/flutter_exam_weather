import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import '../theme/note_theme.dart';
import 'reminder_picker_screen.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note; // null nếu tạo mới

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;
  bool _hasChanges = false;
  String _selectedColor = '#FFFFFF';
  String _selectedType = 'text';
  String? _folderId;
  List<String> _tags = [];
  bool _isPinned = false;
  DateTime? _reminderAt;
  String? _repeatRule;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _selectedColor = note?.color ?? '#FFFFFF';
    _selectedType = note?.type ?? 'text';
    _folderId = note?.folderId;
    _tags = List.from(note?.tags ?? []);
    _isPinned = note?.isPinned ?? false;
    _reminderAt = note?.reminderAt;
    _repeatRule = note?.repeatRule;

    // Track changes
    _titleController.addListener(() {
      _hasChanges = true;
    });
    _contentController.addListener(() {
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final noteProvider = context.read<NoteProvider>();

      if (widget.note == null) {
        // Tạo note mới
        await noteProvider.createNote(
          userId: authProvider.currentUser!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          color: _selectedColor,
          type: _selectedType,
          folderId: _folderId,
          tags: _tags,
          isPinned: _isPinned,
          reminderAt: _reminderAt,
          repeatRule: _repeatRule,
        );
      } else {
        // Cập nhật note
        await noteProvider.updateNote(
          noteId: widget.note!.id,
          userId: authProvider.currentUser!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          color: _selectedColor,
          type: _selectedType,
          folderId: _folderId,
          tags: _tags,
          isPinned: _isPinned,
          reminderAt: _reminderAt,
          repeatRule: _repeatRule,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu'),
            duration: Duration(seconds: 1),
            backgroundColor: NoteTheme.accentMint,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi lưu'),
            backgroundColor: NoteTheme.danger,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu thay đổi?'),
        content: const Text('Bạn có muốn lưu các thay đổi trước khi thoát?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Không lưu'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _save();
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NoteTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    return shouldSave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.pop(context, true);
          }
        }
      },
      child: Scaffold(
        backgroundColor: NoteTheme.background,
        appBar: AppBar(
          backgroundColor: NoteTheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: NoteTheme.textPrimary),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, size: 20),
                label: const Text('Lưu'),
                style: TextButton.styleFrom(
                  foregroundColor: NoteTheme.primaryBlue,
                ),
              ),
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? NoteTheme.primaryBlue : NoteTheme.textSecondary,
            ),
            onPressed: () async {
              if (widget.note != null) {
                final authProvider = context.read<AuthProvider>();
                final noteProvider = context.read<NoteProvider>();
                await noteProvider.togglePin(widget.note!.id, authProvider.currentUser!.id);
                setState(() {
                  _isPinned = !_isPinned;
                });
              } else {
                setState(() {
                  _isPinned = !_isPinned;
                  _hasChanges = true;
                });
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: NoteTheme.textPrimary),
            onSelected: (value) async {
              final authProvider = context.read<AuthProvider>();
              final noteProvider = context.read<NoteProvider>();
              
              if (widget.note == null) return;

              switch (value) {
                case 'reminder':
                  final reminder = await Navigator.push<DateTime?>(
                    context,
                    MaterialPageRoute(builder: (_) => const ReminderPickerScreen()),
                  );
                  if (reminder != null) {
                    setState(() {
                      _reminderAt = reminder;
                      _hasChanges = true;
                    });
                  }
                  break;
                case 'archive':
                  await noteProvider.toggleArchive(widget.note!.id, authProvider.currentUser!.id);
                  if (mounted) Navigator.pop(context, true);
                  break;
                case 'delete':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xóa ghi chú'),
                      content: const Text('Ghi chú sẽ được chuyển vào thùng rác.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Xóa', style: TextStyle(color: NoteTheme.danger)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await noteProvider.moveToTrash(widget.note!.id, authProvider.currentUser!.id);
                    if (mounted) Navigator.pop(context, true);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reminder',
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Nhắc nhở'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Lưu trữ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: NoteTheme.danger),
                    SizedBox(width: 10),
                    Text('Xóa', style: TextStyle(color: NoteTheme.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: NoteTheme.background,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(NoteTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        style: NoteTheme.noteTitle.copyWith(fontSize: 24),
                        decoration: InputDecoration(
                          hintText: 'Tiêu đề',
                          hintStyle: NoteTheme.noteTitle.copyWith(
                            color: NoteTheme.textSecondary,
                            fontSize: 24,
                          ),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                      ),
                      const SizedBox(height: NoteTheme.spacingM),
                      if (_reminderAt != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: NoteTheme.spacingS,
                            vertical: NoteTheme.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: NoteTheme.activePillBackground,
                            borderRadius: BorderRadius.circular(NoteTheme.chipRadius),
                            border: Border.all(
                              color: NoteTheme.primaryBlue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications, size: 16, color: NoteTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Text(
                                _formatReminder(_reminderAt!),
                                style: NoteTheme.chipText.copyWith(color: NoteTheme.primaryBlue),
                              ),
                            ],
                          ),
                        ),
                      if (_reminderAt != null) const SizedBox(height: NoteTheme.spacingS),
                      TextField(
                        controller: _contentController,
                        style: NoteTheme.notePreview.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Bắt đầu ghi chú...',
                          hintStyle: NoteTheme.notePreview,
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        expands: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _formatReminder(DateTime reminder) {
    final now = DateTime.now();
    final difference = reminder.difference(now);

    if (difference.inDays == 0) {
      return 'Hôm nay ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ngày mai ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';
    } else {
      return '${reminder.day}/${reminder.month}/${reminder.year} ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';
    }
  }
}

