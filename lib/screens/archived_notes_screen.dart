import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import '../widgets/note_card_widget.dart';
import '../theme/note_theme.dart';
import 'note_editor_screen.dart';

class ArchivedNotesScreen extends StatelessWidget {
  const ArchivedNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final noteProvider = context.read<NoteProvider>();

    // Load archived notes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      noteProvider.loadNotes(authProvider.currentUser!.id, includeArchived: true);
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
        title: const Text('Đã lưu trữ', style: NoteTheme.pageTitle),
      ),
      body: Container(
        color: NoteTheme.background,
        child: SafeArea(
          child: Consumer<NoteProvider>(
            builder: (context, noteProvider, _) {
              final archivedNotes = noteProvider.archivedNotes;

              if (archivedNotes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 80,
                        color: NoteTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: NoteTheme.spacingM),
                      Text(
                        'Chưa có ghi chú nào được lưu trữ',
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
                itemCount: archivedNotes.length,
                itemBuilder: (context, index) {
                  final note = archivedNotes[index];
                  return NoteCardWidget(
                    note: note,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NoteEditorScreen(note: note),
                        ),
                      );
                      noteProvider.loadNotes(
                        authProvider.currentUser!.id,
                        includeArchived: true,
                      );
                    },
                    onLongPress: () {
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
                                  leading: const Icon(Icons.unarchive, color: NoteTheme.textPrimary),
                                  title: const Text('Bỏ lưu trữ'),
                                  onTap: () async {
                                    await noteProvider.toggleArchive(
                                      note.id,
                                      authProvider.currentUser!.id,
                                    );
                                    Navigator.pop(context);
                                    noteProvider.loadNotes(
                                      authProvider.currentUser!.id,
                                      includeArchived: true,
                                    );
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

