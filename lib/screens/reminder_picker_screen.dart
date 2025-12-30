import 'package:flutter/material.dart';
import '../theme/note_theme.dart';

class ReminderPickerScreen extends StatefulWidget {
  final DateTime? initialDate;

  const ReminderPickerScreen({super.key, this.initialDate});

  @override
  State<ReminderPickerScreen> createState() => _ReminderPickerScreenState();
}

class _ReminderPickerScreenState extends State<ReminderPickerScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.initialDate!);
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: NoteTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: NoteTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _setQuickReminder(int hours) {
    final now = DateTime.now();
    setState(() {
      _selectedDate = now.add(Duration(hours: hours));
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoteTheme.background,
      appBar: AppBar(
        backgroundColor: NoteTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: NoteTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Đặt nhắc nhở', style: NoteTheme.pageTitle),
        actions: [
          TextButton(
            onPressed: () {
              if (_selectedDate != null && _selectedTime != null) {
                final reminder = DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                  _selectedTime!.hour,
                  _selectedTime!.minute,
                );
                Navigator.pop(context, reminder);
              }
            },
            child: const Text('Lưu', style: TextStyle(color: NoteTheme.primaryBlue)),
          ),
        ],
      ),
      body: Container(
        color: NoteTheme.background,
        child: SafeArea(
          child: Column(
            children: [
              // Quick options
              Padding(
                padding: const EdgeInsets.all(NoteTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nhanh', style: NoteTheme.noteTitle),
                    const SizedBox(height: NoteTheme.spacingS),
                    Wrap(
                      spacing: NoteTheme.spacingS,
                      runSpacing: NoteTheme.spacingS,
                      children: [
                        _QuickOptionChip(
                          label: 'Sau 1 giờ',
                          onTap: () => _setQuickReminder(1),
                        ),
                        _QuickOptionChip(
                          label: 'Sau 3 giờ',
                          onTap: () => _setQuickReminder(3),
                        ),
                        _QuickOptionChip(
                          label: 'Ngày mai',
                          onTap: () => _setQuickReminder(24),
                        ),
                        _QuickOptionChip(
                          label: 'Tuần sau',
                          onTap: () => _setQuickReminder(168),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Date picker
              ListTile(
                leading: const Icon(Icons.calendar_today, color: NoteTheme.primaryBlue),
                title: const Text('Ngày', style: NoteTheme.noteTitle),
                subtitle: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Chọn ngày',
                  style: NoteTheme.notePreview,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),
              // Time picker
              ListTile(
                leading: const Icon(Icons.access_time, color: NoteTheme.primaryBlue),
                title: const Text('Giờ', style: NoteTheme.noteTitle),
                subtitle: Text(
                  _selectedTime != null
                      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                      : 'Chọn giờ',
                  style: NoteTheme.notePreview,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectTime,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickOptionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickOptionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NoteTheme.chipRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NoteTheme.spacingM,
          vertical: NoteTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: NoteTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(NoteTheme.chipRadius),
          border: Border.all(color: NoteTheme.primaryBlue.withOpacity(0.3)),
        ),
        child: Text(label, style: NoteTheme.chipText.copyWith(color: NoteTheme.primaryBlue)),
      ),
    );
  }
}

