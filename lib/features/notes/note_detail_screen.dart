import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/note_model.dart';
import '../home/providers/notes_provider.dart';

class ContentBlock {
  final String id;
  final BlockType type;
  String content;
  late final TextEditingController controller;

  ContentBlock({required this.type, required this.content})
    : id = DateTime.now().millisecondsSinceEpoch.toString() {
    if (type == BlockType.text) {
      controller = TextEditingController(text: content);
    }
  }

  void dispose() {
    if (type == BlockType.text) {
      controller.dispose();
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type == BlockType.text ? 'text' : 'image',
    'content': content,
  };
}

enum BlockType { text, image }

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late final TextEditingController _titleController;
  late List<String> _tags;
  bool _isSaving = false;
  late List<ContentBlock> _contentBlocks;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _tags = List<String>.from(widget.note.tags);
    _contentBlocks = _parseContent(widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var block in _contentBlocks) {
      block.dispose();
    }
    super.dispose();
  }

  List<ContentBlock> _parseContent(String content) {
    if (content.isEmpty) {
      return [ContentBlock(type: BlockType.text, content: '')];
    }

    try {
      final List<dynamic> decoded = jsonDecode(content);
      return decoded
          .map((item) {
            if (item is Map<String, dynamic>) {
              final type = item['type'] == 'image'
                  ? BlockType.image
                  : BlockType.text;
              final blockContent = item['content'] ?? '';
              return ContentBlock(type: type, content: blockContent);
            }
            return null;
          })
          .whereType<ContentBlock>()
          .toList();
    } catch (_) {
      return [ContentBlock(type: BlockType.text, content: content)];
    }
  }

  String _serializeContent() {
    final blocks = _contentBlocks.map((b) => b.toJson()).toList();
    return jsonEncode(blocks);
  }

  void _addTextBlock({int afterIndex = -1}) {
    setState(() {
      final newBlock = ContentBlock(type: BlockType.text, content: '');
      if (afterIndex < 0) {
        _contentBlocks.add(newBlock);
      } else {
        _contentBlocks.insert(afterIndex + 1, newBlock);
      }
    });
  }

  void _deleteBlock(int index) {
    setState(() {
      if (_contentBlocks.length > 1) {
        _contentBlocks[index].dispose();
        _contentBlocks.removeAt(index);
      }
    });
  }

  Future<void> _pickAndInsertImage(int afterIndex) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (pickedFile == null || !mounted) return;

      setState(() => _isSaving = true);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                Color.fromRGBO(53, 182, 127, 1),
              ),
            ),
          ),
        );
      }

      final provider = context.read<NotesProvider>();
      final file = File(pickedFile.path);
      final url = await provider.uploadImage(file);

      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _isSaving = false);

      setState(() {
        final imageBlock = ContentBlock(type: BlockType.image, content: url);
        _contentBlocks.insert(afterIndex + 1, imageBlock);
        if (afterIndex + 1 == _contentBlocks.length - 1) {
          _contentBlocks.add(ContentBlock(type: BlockType.text, content: ''));
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Фото успішно додано!'),
          backgroundColor: Color.fromRGBO(53, 182, 127, 1),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).maybePop();
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) {
      return DateFormat('dd MMMM yyyy р.', 'uk_UA').format(DateTime.now());
    }
    try {
      if (dateString.length <= 10) {
        final inputFormat = DateFormat('dd/MM/yyyy');
        final date = inputFormat.parse(dateString);
        return DateFormat('dd MMMM yyyy р.', 'uk_UA').format(date);
      }
      return dateString;
    } catch (_) {
      return dateString;
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заголовок не може бути пустим!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final provider = context.read<NotesProvider>();
    final navigator = Navigator.of(context);

    try {
      final dateToSave = widget.note.id.isEmpty
          ? DateFormat('dd/MM/yyyy').format(DateTime.now())
          : widget.note.date;

      final serializedContent = _serializeContent();

      final updated = widget.note.copyWith(
        title: _titleController.text,
        content: serializedContent,
        tags: _tags,
        date: dateToSave,
      );

      if (widget.note.id.isEmpty) {
        await provider.addNote(updated).timeout(const Duration(seconds: 5));
      } else {
        await provider.updateNote(updated).timeout(const Duration(seconds: 5));
      }

      if (mounted) navigator.pop();
    } on TimeoutException {
      if (mounted) {
        setState(() => _isSaving = false);
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteNote() {
    if (widget.note.id.isEmpty) return;
    final provider = context.read<NotesProvider>();
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromRGBO(245, 246, 248, 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Видалити нотатку?',
          style: TextStyle(color: Colors.black),
        ),
        content: const Text(
          'Цю дію неможливо скасувати.',
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ні', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteNote(widget.note.id);
              if (mounted) navigator.pop();
              ScaffoldMessenger.of(
                // ignore: use_build_context_synchronously
                context,
              ).showSnackBar(const SnackBar(content: Text('Нотатку видалено')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Так, видалити'),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    final tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(245, 246, 248, 1),
        title: const Text('Новий тег', style: TextStyle(color: Colors.black)),
        content: TextField(
          controller: tagController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Назва тегу...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Скасувати',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (tagController.text.trim().isNotEmpty) {
                setState(() => _tags.add(tagController.text.trim()));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(53, 182, 127, 1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Додати'),
          ),
        ],
      ),
    );
  }

  void _showAddMenu(int afterIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(60, 60, 60, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.white),
                title: const Text(
                  'Текст',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addTextBlock(afterIndex: afterIndex);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.white),
                title: const Text(
                  'Фото',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndInsertImage(afterIndex);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromRGBO(39, 83, 75, 1);
    const primaryColor = Color.fromRGBO(53, 182, 127, 1);
    const tagBackgroundColor = Color.fromRGBO(245, 246, 248, 1);
    const tagFontColor = Color.fromRGBO(83, 91, 113, 1);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(_contentBlocks.length - 1),
        backgroundColor: const Color.fromRGBO(251, 228, 127, 1),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Color.fromRGBO(23, 47, 38, 1),
          size: 32,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          _formatDate(widget.note.date),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (widget.note.id.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _deleteNote,
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white, size: 28),
              onPressed: _saveNote,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Заголовок',
                          hintStyle: TextStyle(
                            color: Colors.white30,
                            fontSize: 24,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showAddTagDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'Додати тег',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_tags.isNotEmpty) const SizedBox(width: 8),
                    ...List.generate(
                      _tags.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: tagBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: GestureDetector(
                            onLongPress: () {
                              setState(() => _tags.removeAt(i));
                            },
                            child: Text(
                              _tags[i],
                              style: const TextStyle(
                                color: tagFontColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_contentBlocks.length, (index) {
                  final block = _contentBlocks[index];
                  return _buildContentBlock(block, index);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBlock(ContentBlock block, int index) {
    if (block.type == BlockType.text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: TextField(
          controller: block.controller,
          maxLines: null,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
          ),
          decoration: const InputDecoration.collapsed(
            hintText: 'Введіть текст...',
            hintStyle: TextStyle(color: Colors.white30),
          ),
          onChanged: (value) {
            block.content = value;
          },
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[900],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  block.content,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Text(
                          'Помилка завантаження фото',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _deleteBlock(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
