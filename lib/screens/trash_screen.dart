import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import '../widgets/note_card_widget.dart';
import '../theme/note_theme.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final noteProvider = context.read<NoteProvider>();

    // Load trash notes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      noteProvider.loadNotes(
        authProvider.currentUser!.id,
        includeArchived: true,
        includeDeleted: true,
      );
    });

    return Scaffold(
      backgroundColor: NoteTheme.background,
      appBar: AppBar(
        backgroundColor: NoteTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NoteTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thùng rác', style: NoteTheme.pageTitle),
        actions: [
          Consumer<NoteProvider>(
            builder: (context, noteProvider, _) {
              if (noteProvider.trashNotes.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xóa vĩnh viễn'),
                      content: const Text('Xóa tất cả ghi chú trong thùng rác? Hành động này không thể hoàn tác.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Xóa tất cả', style: TextStyle(color: NoteTheme.danger)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    for (var note in noteProvider.trashNotes) {
                      await noteProvider.permanentlyDelete(
                        note.id,
                        authProvider.currentUser!.id,
                      );
                    }
                  }
                },
                child: const Text('Xóa tất cả', style: TextStyle(color: NoteTheme.danger)),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: NoteTheme.background,
        child: SafeArea(
          child: Consumer<NoteProvider>(
            builder: (context, noteProvider, _) {
              final trashNotes = noteProvider.trashNotes;

              if (trashNotes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 80,
                        color: NoteTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: NoteTheme.spacingM),
                      Text(
                        'Thùng rác trống',
                        style: NoteTheme.noteTitle.copyWith(
                          color: NoteTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(NoteTheme.spacingM),
                itemCount: trashNotes.length,
                itemBuilder: (context, index) {
                  final note = trashNotes[index];
                  return NoteCardWidget(
                    note: note,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          decoration: BoxDecoration(
                            color: NoteTheme.surface,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(NoteTheme.bottomSheetRadius),
                            ),
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.restore, color: NoteTheme.textPrimary),
                                  title: const Text('Khôi phục'),
                                  onTap: () async {
                                    await noteProvider.restoreFromTrash(
                                      note.id,
                                      authProvider.currentUser!.id,
                                    );
                                    Navigator.pop(context);
                                    noteProvider.loadNotes(
                                      authProvider.currentUser!.id,
                                      includeArchived: true,
                                      includeDeleted: true,
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete_forever, color: NoteTheme.danger),
                                  title: const Text('Xóa vĩnh viễn', style: TextStyle(color: NoteTheme.danger)),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Xóa vĩnh viễn'),
                                        content: const Text('Bạn có chắc muốn xóa vĩnh viễn ghi chú này?'),
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
                                      await noteProvider.permanentlyDelete(
                                        note.id,
                                        authProvider.currentUser!.id,
                                      );
                                      noteProvider.loadNotes(
                                        authProvider.currentUser!.id,
                                        includeArchived: true,
                                        includeDeleted: true,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

