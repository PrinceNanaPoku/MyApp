import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

class NoteService {
  Database? _db;
  List<DatabaseNote> _note = [];

  static final NoteService _shared = NoteService._sharedInstance();
  NoteService._sharedInstance();
  factory NoteService() => _shared;

  final _notesStreamController =
      StreamController<List<DatabaseNote>>.broadcast();
  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream;

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on UserDoesNotExist {
      final user = await createUser(email: email);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheNote() async {
    final allNotes = await getAllNotes();
    _note = allNotes.toList();
    _notesStreamController.add(_note);
  }

  //user should be able to update notes
  Future<DatabaseNote> updateNotes({
    required DatabaseNote note,
    required String text,
  }) async {
    await _ensureDbIsAlreadyOpen();
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id);

    final updateCount = await db.update(notesTable, {
      textColumn: text,
      syncdWithCloudColumn: 0,
    });

    if (updateCount == 0) {
      throw CouldNotUpdateNotes();
    } else {
      final updatedNotes = await getNote(id: note.id);
      _note.removeWhere((note) => note.id == updatedNotes.id);
      _note.add(updatedNotes);
      _notesStreamController.add(_note);
      return updatedNotes;
    }
  }

  //user should be able to fetch all notes
  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsAlreadyOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(notesTable);

    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
  }

  //user should be able to fetch one note
  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsAlreadyOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      notesTable,
      limit: 1,
      where: 'id= ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNotes();
    } else {
      final note = DatabaseNote.fromRow(notes.first);
      _note.removeWhere((note) => note.id == id);
      _note.add(note);
      _notesStreamController.add(_note);
      return note;
    }
  }

  //user should be able to delete all rows
  Future<int> deleteAllNotes() async {
    await _ensureDbIsAlreadyOpen();
    final db = _getDatabaseOrThrow();
    _note = [];
    _notesStreamController.add(_note);
    final numberOfDeletions = await db.delete(notesTable);
    return numberOfDeletions;
  }

  //user should be able to delete note using id
  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsAlreadyOpen();
    final db = _getDatabaseOrThrow();
    final deleteCount = await db.delete(
      notesTable,
      where: 'email = ?',
      whereArgs: ['id'],
    );
    if (deleteCount == 0) {
      throw CouldNotDeleteNote();
    } else {
      _note.removeWhere((note) => note.id == id);
      _notesStreamController.add(_note);
    }
  }

  //checks if owner exists in the database with the correct id
  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    await _ensureDbIsAlreadyOpen();
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw UserDoesNotExist();
    }
    //create notes
    const text = '';
    final db = _getDatabaseOrThrow();
    final noteId = await db.insert(notesTable, {
      userIdColumn: owner.id,
      textColumn: '',
      syncdWithCloudColumn: 1,
    });
    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      syncdWithCloud: true,
    );
    _note.add(note);
    _notesStreamController.add(_note);
    return note;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsAlreadyOpen();
    final db = _getDatabaseOrThrow();
    final result =
        await db.query(userTable, limit: 1, where: 'email = ?', whereArgs: [
      email.toLowerCase(),
    ]);
    if (result.isEmpty) {
      throw UserDoesNotExist();
    } else {
      return DatabaseUser.fromRow(result.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsAlreadyOpen();
    final db = _getDatabaseOrThrow();
    final result =
        await db.query(userTable, limit: 1, where: 'email = ?', whereArgs: [
      email.toLowerCase(),
    ]);
    if (result.isNotEmpty) {
      throw UserAlreadyExist();
    }
    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });
    return DatabaseUser(
      id: userId,
      email: email,
    );
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsAlreadyOpen();
    final db = _getDatabaseOrThrow();
    final deleteCount = await db.delete(userTable,
        where: 'email = ?', whereArgs: [email.toLowerCase()]);
    if (deleteCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsAlreadyOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpen {
      //empty
    }
  }

  Future<void> open() async {
    if (_db != null) throw DatabaseAlreadyOpen();
    try {
      final docPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docPath.path, notesFileName);
      final db = await openDatabase(dbPath);
      _db = db;

//create user table
      await db.execute(createUserTable);

//create note table
      await db.execute(createNoteTable);
      await _cacheNote();
    } on MissingPlatformDirectoryException {
      throw UnableToFindDirectory();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });
  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool syncdWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.syncdWithCloud,
  });
  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        syncdWithCloud = (map[syncdWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, ID = $id, UserId = $userId, SyncdWithCloud = $syncdWithCloud';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const notesFileName = 'note.db';
const userTable = 'user';
const notesTable = 'note';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const syncdWithCloudColumn = 'syncd_with_cloud';
const createUserTable = '''CREATE TABLE IF NOT EXIST"user" (
	"Id"	INTEGER NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("Id" AUTOINCREMENT)
);
''';
const createNoteTable = '''CREATE TABLE IF NOT EXISTS"note" (
	"id"	INTEGER NOT NULL,
	"user_id"	INTEGER NOT NULL,
	"text"	TEXT,
	"syncd_with_cloud"	INTEGER NOT NULL DEFAULT 0,
	FOREIGN KEY("id") REFERENCES "user"("Id"),
	PRIMARY KEY("id")
);
''';
