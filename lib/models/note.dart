enum NotePriority {
  high('high', 'High'),
  medium('medium', 'Medium'),
  normal('normal', 'Normal'),
  low('low', 'Low');

  final String value;
  final String label;

  const NotePriority(this.value, this.label);

  static NotePriority fromString(String value) {
    return NotePriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => NotePriority.normal,
    );
  }
}

class Note {
  final int id;
  final int userId;
  final String title;
  final String content;
  final NotePriority priority;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.priority = NotePriority.normal,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      priority: NotePriority.fromString(map['priority'] as String? ?? 'normal'),
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'priority': priority.value,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Note copyWith({
    int? id,
    int? userId,
    String? title,
    String? content,
    NotePriority? priority,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get contentPreview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  @override
  String toString() => 'Note(id: $id, title: $title, priority: ${priority.value})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
