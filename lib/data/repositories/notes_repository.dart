import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/note_model.dart';
import 'package:firebase_core/firebase_core.dart';

class NotesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'photonotes-db',
  );

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _notesCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  Stream<List<Note>> getNotesStream() {
    return _notesCollection.orderBy('date', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
    });
  }

  Future<void> addNote(Note note) async {
    await _notesCollection.add(note.toMap());
  }

  Future<void> updateNote(Note note) async {
    await _notesCollection.doc(note.id).update(note.toMap());
  }

  Future<void> deleteNote(String noteId) async {
    await _notesCollection.doc(noteId).delete();
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      if (!await imageFile.exists()) {
        throw Exception('Файл не знайдено: ${imageFile.path}');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$userId/images/$fileName');
      final uploadTask = ref.putFile(imageFile);
      await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Таймаут завантаження фото (60 сек)');
        },
      );

      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      rethrow;
    }
  }
}
