  import 'dart:async';
  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../../../data/models/note_model.dart';
  import '../../../data/repositories/notes_repository.dart';

  enum NotesFilter { all, favorites }

  class NotesProvider extends ChangeNotifier {
    final NotesRepository _repository = NotesRepository();

    List<Note> _allNotes = [];
    List<Note> _displayNotes = [];

    List<Note> get notes => _displayNotes;

    NotesFilter _activeFilter = NotesFilter.all;
    String _searchQuery = '';
    static const String _filterKey = 'notes_filter_preference';

    NotesFilter get activeFilter => _activeFilter;

    StreamSubscription<List<Note>>? _notesSubscription;

    void init() async {
      final prefs = await SharedPreferences.getInstance();
      final savedFilterIndex = prefs.getInt(_filterKey) ?? 0;
      _activeFilter = NotesFilter.values[savedFilterIndex];

      _notesSubscription = _repository.getNotesStream().listen((notesData) {
        _allNotes = notesData;
        _applyFilterAndSearch();
        notifyListeners();
      });
    }

    void setSearchQuery(String query) {
      _searchQuery = query.toLowerCase();
      _applyFilterAndSearch();
      notifyListeners();
    }

    Future<void> setFilter(NotesFilter newFilter) async {
      _activeFilter = newFilter;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_filterKey, newFilter.index);

      _applyFilterAndSearch();
      notifyListeners();
    }

    void _applyFilterAndSearch() {
      var tempNotes = _activeFilter == NotesFilter.favorites
          ? _allNotes.where((note) => note.isFavorite).toList()
          : List<Note>.from(_allNotes);

      if (_searchQuery.isNotEmpty) {
        tempNotes = tempNotes.where((note) {
          return note.title.toLowerCase().contains(_searchQuery) ||
              note.content.toLowerCase().contains(_searchQuery);
        }).toList();
      }

      _displayNotes = tempNotes;
    }

    Future<void> addNote(Note note) => _repository.addNote(note);

    Future<void> updateNote(Note note) => _repository.updateNote(note);

    Future<void> deleteNote(String id) => _repository.deleteNote(id);

    Future<void> toggleFavorite(Note note) {
      final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
      return _repository.updateNote(updatedNote);
    }

    Future<String> uploadImage(File file) => _repository.uploadImage(file);

    @override
    void dispose() {
      _notesSubscription?.cancel();
      super.dispose();
    }
  }
