import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/note_model.dart';
import '../../features/home/providers/notes_provider.dart';
import '../../features/notes/note_detail_screen.dart';
import '../../core/widgets/note_card.dart';

class HomeScreenFull extends StatefulWidget {
  const HomeScreenFull({super.key});

  @override
  State<HomeScreenFull> createState() => _HomeScreenFullState();
}

class _HomeScreenFullState extends State<HomeScreenFull> {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  void _logCreateNoteEvent() {
    final user = FirebaseAuth.instance.currentUser;
    _analytics.logEvent(
      name: 'create_note_pressed',
      parameters: {
        'user_email': user?.email ?? 'anonymous',
        'press_timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromRGBO(39, 83, 75, 1);
    const primaryColor = Color.fromRGBO(53, 182, 127, 1);
    const cardColor = Color.fromRGBO(245, 246, 248, 1);
    const fabColor = Color.fromRGBO(251, 228, 127, 1);
    const fontColor = Color.fromRGBO(23, 47, 38, 1);

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final isAllFilterActive = notesProvider.activeFilter == NotesFilter.all;
        final isFavoritesFilterActive =
            notesProvider.activeFilter == NotesFilter.favorites;

        return Scaffold(
          backgroundColor: backgroundColor,
          floatingActionButton: SizedBox(
            width: 70,
            height: 70,
            child: FloatingActionButton(
              onPressed: () {
                _logCreateNoteEvent();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteDetailScreen(
                      note: Note(
                        id: '',
                        title: '',
                        content: '',
                        date: '',
                        tags: [],
                        imageUrls: [],
                      ),
                    ),
                  ),
                );
              },
              backgroundColor: fabColor,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: fontColor, size: 40),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PhotoNotes',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/account');
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color.fromRGBO(255, 231, 157, 1),
                            child: Icon(
                              Icons.star,
                              color: Color.fromRGBO(39, 83, 75, 1),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Привіт! Петро',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('👋', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    onChanged: (value) {
                      notesProvider.setSearchQuery(value);
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Пошук',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: const Color.fromRGBO(60, 101, 94, 1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      ActionChip(
                        label: const Text('Всі нотатки'),
                        avatar: Icon(
                          Icons.notes_rounded,
                          color: isAllFilterActive ? Colors.white : fontColor,
                        ),
                        onPressed: () {
                          notesProvider.setFilter(NotesFilter.all);
                        },
                        backgroundColor: isAllFilterActive
                            ? primaryColor
                            : cardColor,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: isAllFilterActive ? Colors.white : fontColor,
                          fontWeight: FontWeight.bold,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ActionChip(
                        label: const Text('Улюблені'),
                        avatar: Icon(
                          isFavoritesFilterActive
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavoritesFilterActive
                              ? Colors.white
                              : fontColor,
                        ),
                        onPressed: () {
                          notesProvider.setFilter(NotesFilter.favorites);
                        },
                        backgroundColor: isFavoritesFilterActive
                            ? primaryColor
                            : cardColor,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: isFavoritesFilterActive
                              ? Colors.white
                              : fontColor,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(child: _buildBody(notesProvider)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(NotesProvider notesProvider) {
    if (notesProvider.notes.isEmpty) {
      return const Center(
        child: Text(
          'Нотаток не знайдено',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: notesProvider.notes.length,
      itemBuilder: (context, index) {
        final note = notesProvider.notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: NoteCard(note: note),
        );
      },
    );
  }
}
