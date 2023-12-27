import 'package:flutter/material.dart';
import 'package:myapp/services/auth/auth_service.dart';
import 'package:myapp/services/crud/notes_services.dart';
import 'package:myapp/utilities/generics/get_argument.dart';

class CreateUpdateNewNotesView extends StatefulWidget {
  const CreateUpdateNewNotesView({super.key});

  @override
  State<CreateUpdateNewNotesView> createState() =>
      _CreateUpdateNewNotesViewState();
}

class _CreateUpdateNewNotesViewState extends State<CreateUpdateNewNotesView> {
  DatabaseNote? _note;
  late final NoteService _noteService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _noteService = NoteService();
    _textController = TextEditingController();
    super.initState();
  }

  void _textControllerListener() async {
    final note = _note;
    final text = _textController.text;

    if (note == null) {
      return;
    }
    await _noteService.updateNotes(
      note: note,
      text: text,
    );
  }

  void _setupTextControllerListener() {
    _textController.removeListener((_textControllerListener));
    _textController.addListener((_textControllerListener));
  }

  Future<DatabaseNote> createOrGetExistingNote(BuildContext context) async {
    final widgetNote = context.getArgument<DatabaseNote>();
    if (widgetNote != null) {
      _note = widgetNote;
      _textController.text = widgetNote.text;
      return widgetNote;
    }

    final existingNote = _note;

    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email;
    final owner = await _noteService.getUser(email: email);
    final newNote = await _noteService.createNote(owner: owner);
    _note = newNote;
    return newNote;
  }

  void _saveNoteIfTextIsNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (note != null && _textController.text.isNotEmpty) {
      await _noteService.updateNotes(note: note, text: text);
    }
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      _noteService.deleteNote(id: note.id);
    }
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextIsNotEmpty();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: FutureBuilder(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _note = snapshot.data as DatabaseNote;
              _setupTextControllerListener();
              return TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration:
                    const InputDecoration(hintText: 'Type your notes here...'),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
