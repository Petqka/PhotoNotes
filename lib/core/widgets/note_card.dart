import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/note_model.dart';
import '../../features/notes/note_detail_screen.dart';
import '../../../features/home/providers/notes_provider.dart';

class NoteCard extends StatelessWidget {
  final Note note;

  const NoteCard({super.key, required this.note});

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromRGBO(245, 246, 248, 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Видалити нотатку?",
          style: TextStyle(
            color: Color.fromRGBO(23, 47, 38, 1),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Ви впевнені, що хочете видалити '${note.title}'?",
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Скасувати",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<NotesProvider>().deleteNote(note.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Нотатку видалено")));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Видалити"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color.fromRGBO(245, 246, 248, 1);
    const fontColor = Color.fromRGBO(23, 28, 38, 1);
    const tagBackgroundColor = Color.fromRGBO(222, 228, 241, 1);
    const tagFontColor = Color.fromRGBO(23, 28, 38, 1);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fontColor,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            context.read<NotesProvider>().toggleFavorite(note);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              note.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: note.isFavorite
                                  ? const Color.fromRGBO(200, 0, 0, 1)
                                  : Colors.grey,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showDeleteDialog(context),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromRGBO(23, 28, 38, 1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (note.tags.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: note.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: tagBackgroundColor,
                        side: BorderSide.none,
                        labelStyle: const TextStyle(
                          color: tagFontColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
