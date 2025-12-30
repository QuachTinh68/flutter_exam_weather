class Note {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String color;
  final String type; // text | checklist | mixed
  final String? folderId; // nullable
  final List<String> tags; // string[]
  final bool isPinned;
  final bool isArchived;
  final DateTime? reminderAt; // nullable
  final String? repeatRule; // nullable: daily/weekly/monthly/custom
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt; // soft delete

  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.color,
    required this.type,
    this.folderId,
    this.tags = const [],
    this.isPinned = false,
    this.isArchived = false,
    this.reminderAt,
    this.repeatRule,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'color': color,
      'type': type,
      'folderId': folderId,
      'tags': tags,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'reminderAt': reminderAt?.toIso8601String(),
      'repeatRule': repeatRule,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String? ?? 'Untitled',
      content: json['content'] as String? ?? '',
      color: json['color'] as String? ?? '#FFFFFF',
      type: json['type'] as String? ?? 'text',
      folderId: json['folderId'] as String?,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List)
          : [],
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      reminderAt: json['reminderAt'] != null
          ? DateTime.parse(json['reminderAt'] as String)
          : null,
      repeatRule: json['repeatRule'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Note copyWith({
    String? id,
    String? userId,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      type: type ?? this.type,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      reminderAt: reminderAt ?? this.reminderAt,
      repeatRule: repeatRule ?? this.repeatRule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Helper methods
  bool get isDeleted => deletedAt != null;
  bool get hasReminder => reminderAt != null;
  String get displayTitle => title.isEmpty ? 'Untitled' : title;
}
