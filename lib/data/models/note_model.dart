import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String date;
  final List<String> tags;
  final bool isFavorite;
  final List<String> imageUrls;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.tags,
    this.isFavorite = false,
    this.imageUrls = const [],
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: data['date'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      isFavorite: data['isFavorite'] ?? false,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': date,
      'tags': tags,
      'isFavorite': isFavorite,
      'imageUrls': imageUrls,
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
    List<String>? tags,
    bool? isFavorite,
    List<String>? imageUrls,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
