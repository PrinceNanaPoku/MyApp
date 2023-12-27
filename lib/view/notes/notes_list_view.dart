import 'package:flutter/material.dart';
import 'package:myapp/services/crud/notes_services.dart';
import 'package:myapp/utilities/dialog/delete_dialog.dart';

typedef NoteCallback = void Function(DatabaseNote note);

class NotesListView extends StatelessWidget {
  final List<DatabaseNote> note;
  final NoteCallback onDeleteNote;
  final NoteCallback onTap;

  const NotesListView({
    Key? key,
    required this.note,
    required this.onDeleteNote,
    required this.onTap,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: note.length,
      itemBuilder: (context, index) {
        final notes = note[index];
        return ListTile(
          title: Text(
            notes.text,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            onPressed: () async {
              final shouldDelete = await showDeleteDialog(context);
              if (shouldDelete) {
                onDeleteNote(notes);
              }
            },
            icon: const Icon(Icons.delete),
          ),
        );
      },
    );
  }
}
