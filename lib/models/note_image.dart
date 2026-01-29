class NoteImage {
  final int id;
  final int noteId;
  final String imagePath;
  final DateTime createdAt;

  NoteImage({
    required this.id,
    required this.noteId,
    required this.imagePath,
    required this.createdAt,
  });

  factory NoteImage.fromMap(Map<String, dynamic> map) {
    return NoteImage(
      id: map['id'] as int,
      noteId: map['note_id'] as int,
      imagePath: map['image_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'NoteImage(id: $id, noteId: $noteId, path: $imagePath)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteImage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
