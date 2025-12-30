import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import '../widgets/note_card_widget.dart';
import '../widgets/base_scaffold.dart';
import '../theme/note_theme.dart';
import 'note_editor_screen.dart';
import 'archived_notes_screen.dart';
import 'trash_screen.dart';

class NotesScreenNew extends StatefulWidget {
  const NotesScreenNew({super.key});

  @override
  State<NotesScreenNew> createState() => _NotesScreenNewState();
}

class _NotesScreenNewState extends State<NotesScreenNew> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoad();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkAuthAndLoad() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamed('/login').then((result) {
            // Sau khi đăng nhập thành công, reload notes
            if (mounted && result == true) {
              _loadNotes();
            }
          });
        }
      });
      return;
    }
    _loadNotes();
  }

  void _loadNotes() {
    if (!mounted) return;
    try {
      final authProvider = context.read<AuthProvider>();
      final noteProvider = context.read<NoteProvider>();
      if (authProvider.currentUser != null) {
        noteProvider.loadNotes(authProvider.currentUser!.id);
      }
    } catch (e) {
      print('Error loading notes: $e');
    }
  }

  void _showNoteMenu(BuildContext context, note) {
    final authProvider = context.read<AuthProvider>();
    final noteProvider = context.read<NoteProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: NoteTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(NoteTheme.bottomSheetRadius)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: NoteTheme.textPrimary,
                ),
                title: Text(note.isPinned ? 'Bỏ ghim' : 'Ghim'),
                onTap: () async {
                  await noteProvider.togglePin(note.id, authProvider.currentUser!.id);
                  Navigator.pop(context);
                  _loadNotes();
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined, color: NoteTheme.textPrimary),
                title: const Text('Lưu trữ'),
                onTap: () async {
                  await noteProvider.toggleArchive(note.id, authProvider.currentUser!.id);
                  Navigator.pop(context);
                  _loadNotes();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: NoteTheme.danger),
                title: const Text('Xóa', style: TextStyle(color: NoteTheme.danger)),
                onTap: () async {
                  Navigator.pop(context);
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
                    await noteProvider.moveToTrash(note.id, authProvider.currentUser!.id);
                    _loadNotes();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoteTheme.background,
      body: Container(
        color: NoteTheme.background,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(NoteTheme.spacingM),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final baseScaffold = BaseScaffold.of(context);
                        baseScaffold?.openMenu();
                      },
                      icon: const Icon(Icons.menu_rounded, color: NoteTheme.textPrimary),
                    ),
                    const SizedBox(width: NoteTheme.spacingS),
                    Expanded(
                      child: _isSearching
                          ? TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: NoteTheme.noteTitle,
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm...',
                                hintStyle: NoteTheme.notePreview,
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                context.read<NoteProvider>().setSearchQuery(value);
                              },
                            )
                          : const Text(
                              'Ghi chú của tôi',
                              style: NoteTheme.pageTitle,
                            ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: NoteTheme.textPrimary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                            context.read<NoteProvider>().setSearchQuery('');
                          }
                        });
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: NoteTheme.textPrimary),
                      onSelected: (value) {
                        if (value == 'archived') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ArchivedNotesScreen()),
                          );
                        } else if (value == 'trash') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TrashScreen()),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'archived',
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined, size: 20),
                              SizedBox(width: 10),
                              Text('Đã lưu trữ'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'trash',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20),
                              SizedBox(width: 10),
                              Text('Thùng rác'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Filter chips
              Consumer<NoteProvider>(
                builder: (context, noteProvider, _) {
                  final pinnedNotes = noteProvider.pinnedNotes;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: NoteTheme.spacingM),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Tất cả',
                          isSelected: !noteProvider.showPinnedOnly,
                          onTap: () {
                            noteProvider.togglePinnedOnly();
                            if (noteProvider.showPinnedOnly) {
                              noteProvider.togglePinnedOnly();
                            }
                            _loadNotes();
                          },
                        ),
                        if (pinnedNotes.isNotEmpty)
                          _FilterChip(
                            label: 'Đã ghim',
                            isSelected: noteProvider.showPinnedOnly,
                            onTap: () {
                              noteProvider.togglePinnedOnly();
                              _loadNotes();
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: NoteTheme.spacingS),
              // Notes list
              Expanded(
                child: Consumer<NoteProvider>(
                  builder: (context, noteProvider, _) {
                    if (noteProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: NoteTheme.primaryBlue),
                      );
                    }

                    final notes = noteProvider.filteredNotes;

                    if (notes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add,
                              size: 80,
                              color: NoteTheme.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: NoteTheme.spacingM),
                            Text(
                              noteProvider.searchQuery.isNotEmpty
                                  ? 'Không tìm thấy ghi chú'
                                  : 'Chưa có ghi chú nào',
                              style: NoteTheme.noteTitle.copyWith(
                                color: NoteTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: NoteTheme.spacingS),
                            Text(
                              noteProvider.searchQuery.isNotEmpty
                                  ? 'Thử tìm kiếm với từ khóa khác'
                                  : 'Nhấn nút + để tạo ghi chú mới',
                              style: NoteTheme.helperText,
                            ),
                            if (noteProvider.searchQuery.isEmpty) ...[
                              const SizedBox(height: NoteTheme.spacingL),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NoteEditorScreen(),
                                    ),
                                  );
                                  _loadNotes();
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Tạo ghi chú mới'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: NoteTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: NoteTheme.spacingL,
                                    vertical: NoteTheme.spacingS,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(NoteTheme.inputRadius),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(NoteTheme.spacingM),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return NoteCardWidget(
                          note: note,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NoteEditorScreen(note: note),
                              ),
                            );
                            _loadNotes();
                          },
                          onLongPress: () => _showNoteMenu(context, note),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _AnimatedFAB(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
          );
          _loadNotes();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: NoteTheme.spacingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NoteTheme.chipRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: NoteTheme.spacingM,
            vertical: NoteTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? NoteTheme.activePillBackground
                : NoteTheme.surface,
            borderRadius: BorderRadius.circular(NoteTheme.chipRadius),
            border: Border.all(
              color: isSelected
                  ? NoteTheme.primaryBlue
                  : NoteTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: NoteTheme.chipText.copyWith(
              color: isSelected ? NoteTheme.primaryBlue : NoteTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// Animated Floating Action Button với Ocean Mint theme
class _AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedFAB({required this.onPressed});

  @override
  State<_AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<_AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: NoteTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: NoteTheme.primaryBlue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: widget.onPressed,
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

