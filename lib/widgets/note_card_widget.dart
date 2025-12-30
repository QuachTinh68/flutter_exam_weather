import 'package:flutter/material.dart';
import '../models/note.dart';
import '../theme/note_theme.dart';

class NoteCardWidget extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NoteCardWidget({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: NoteTheme.spacingM),
        decoration: BoxDecoration(
          color: NoteTheme.surface,
          borderRadius: BorderRadius.circular(NoteTheme.cardRadius),
          border: Border.all(color: NoteTheme.border, width: 1),
          boxShadow: NoteTheme.cardShadow,
        ),
        child: Stack(
          children: [
            // Accent stripe ở góc trái
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: NoteTheme.accentMint,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(NoteTheme.cardRadius),
                    bottomLeft: Radius.circular(NoteTheme.cardRadius),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(NoteTheme.cardRadius),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(NoteTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Pin icon + Tags
                      Row(
                        children: [
                          if (note.isPinned)
                            const Icon(
                              Icons.push_pin,
                              size: 16,
                              color: NoteTheme.primaryBlue,
                            ),
                          if (note.isPinned) const SizedBox(width: NoteTheme.spacingXS),
                          Expanded(
                            child: Wrap(
                              spacing: NoteTheme.spacingXS,
                              children: note.tags.take(3).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: NoteTheme.spacingS,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NoteTheme.accentMint.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(NoteTheme.chipRadius),
                                    border: Border.all(
                                      color: NoteTheme.accentMint.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: NoteTheme.chipText.copyWith(
                                      color: NoteTheme.accentMint,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                  if (note.isPinned || note.tags.isNotEmpty)
                    const SizedBox(height: NoteTheme.spacingS),
                  // Title
                  Text(
                    note.displayTitle,
                    style: NoteTheme.noteTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: NoteTheme.spacingXS),
                  // Content preview
                  Text(
                    note.content,
                    style: NoteTheme.notePreview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: NoteTheme.spacingS),
                  // Footer: Reminder + Date
                  Row(
                    children: [
                      if (note.hasReminder)
                        Row(
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              size: 14,
                              color: NoteTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatReminder(note.reminderAt!),
                              style: NoteTheme.helperText,
                            ),
                            const SizedBox(width: NoteTheme.spacingS),
                          ],
                        ),
                      const Spacer(),
                      Text(
                        _formatDate(note.updatedAt),
                        style: NoteTheme.helperText,
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
      return 'Ngày mai';
    } else {
      return '${reminder.day}/${reminder.month}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

