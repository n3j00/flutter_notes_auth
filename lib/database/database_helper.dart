// Database Helper - SQLite Database Management
// Author: Nikodem Stach

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        profile_picture TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        priority TEXT NOT NULL DEFAULT 'normal',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE note_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          priority TEXT NOT NULL DEFAULT 'normal',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE notes ADD COLUMN priority TEXT NOT NULL DEFAULT "normal"');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE notes ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE users ADD COLUMN profile_picture TEXT');
      await db.execute('''
        CREATE TABLE note_images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          note_id INTEGER NOT NULL,
          image_path TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;

    final existingUser = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (existingUser.isNotEmpty) {
      return {
        'success': false,
        'message': 'Email already registered',
      };
    }

    try {
      final hashedPassword = _hashPassword(password);
      final id = await db.insert('users', {
        'name': name,
        'email': email.toLowerCase(),
        'password': hashedPassword,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Registration successful',
        'userId': id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);

    try {
      final result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email.toLowerCase(), hashedPassword],
      );

      if (result.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      }

      final user = result.first;
      return {
        'success': true,
        'message': 'Login successful',
        'user': {
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> updateUserName({
    required int userId,
    required String newName,
  }) async {
    final db = await database;

    try {
      final count = await db.update(
        'users',
        {'name': newName},
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (count == 0) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      return {
        'success': true,
        'message': 'Name updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update name: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateUserPassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final db = await database;

    try {
      final hashedCurrentPassword = _hashPassword(currentPassword);
      final result = await db.query(
        'users',
        where: 'id = ? AND password = ?',
        whereArgs: [userId, hashedCurrentPassword],
      );

      if (result.isEmpty) {
        return {
          'success': false,
          'message': 'Current password is incorrect',
        };
      }

      final hashedNewPassword = _hashPassword(newPassword);
      final count = await db.update(
        'users',
        {'password': hashedNewPassword},
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (count == 0) {
        return {
          'success': false,
          'message': 'Failed to update password',
        };
      }

      return {
        'success': true,
        'message': 'Password updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update password: $e',
      };
    }
  }

  // ===== NOTES CRUD =====
  
  Future<Map<String, dynamic>> createNote({
    required int userId,
    required String title,
    required String content,
    String priority = 'normal',
  }) async {
    final db = await database;

    try {
      final now = DateTime.now().toIso8601String();
      final id = await db.insert('notes', {
        'user_id': userId,
        'title': title,
        'content': content,
        'priority': priority,
        'created_at': now,
        'updated_at': now,
      });

      return {
        'success': true,
        'message': 'Note created successfully',
        'noteId': id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create note: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getNotesByUser(int userId) async {
    final db = await database;
    return await db.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getNoteById(int noteId) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
    
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<Map<String, dynamic>> updateNote({
    required int noteId,
    required String title,
    required String content,
    String? priority,
  }) async {
    final db = await database;

    try {
      final updateData = {
        'title': title,
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (priority != null) {
        updateData['priority'] = priority;
      }
      
      final count = await db.update(
        'notes',
        updateData,
        where: 'id = ?',
        whereArgs: [noteId],
      );

      if (count == 0) {
        return {
          'success': false,
          'message': 'Note not found',
        };
      }

      return {
        'success': true,
        'message': 'Note updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update note: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteNote(int noteId) async {
    final db = await database;

    try {
      final count = await db.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [noteId],
      );

      if (count == 0) {
        return {
          'success': false,
          'message': 'Note not found',
        };
      }

      return {
        'success': true,
        'message': 'Note deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete note: $e',
      };
    }
  }

  Future<Map<String, dynamic>> togglePinNote(int noteId) async {
    final db = await database;

    try {
      final result = await db.query(
        'notes',
        columns: ['is_pinned'],
        where: 'id = ?',
        whereArgs: [noteId],
      );

      if (result.isEmpty) {
        return {
          'success': false,
          'message': 'Note not found',
        };
      }

      final currentPinState = result.first['is_pinned'] as int;
      final newPinState = currentPinState == 1 ? 0 : 1;

      final count = await db.update(
        'notes',
        {
          'is_pinned': newPinState,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [noteId],
      );

      if (count == 0) {
        return {
          'success': false,
          'message': 'Failed to update pin status',
        };
      }

      return {
        'success': true,
        'message': newPinState == 1 ? 'Note pinned' : 'Note unpinned',
        'isPinned': newPinState == 1,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to toggle pin: $e',
      };
    }
  }

  // ===== USER PROFILE PICTURE =====
  
  Future<Map<String, dynamic>> updateProfilePicture(int userId, String? imagePath) async {
    final db = await database;

    try {
      final count = await db.update(
        'users',
        {'profile_picture': imagePath},
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (count == 0) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      return {
        'success': true,
        'message': 'Profile picture updated',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile picture: $e',
      };
    }
  }

  // ===== NOTE IMAGES =====
  
  Future<Map<String, dynamic>> addNoteImage(int noteId, String imagePath) async {
    final db = await database;

    try {
      final id = await db.insert('note_images', {
        'note_id': noteId,
        'image_path': imagePath,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Image added to note',
        'imageId': id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add image: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getNoteImages(int noteId) async {
    final db = await database;
    return await db.query(
      'note_images',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at ASC',
    );
  }

  Future<Map<String, dynamic>> deleteNoteImage(int imageId) async {
    final db = await database;

    try {
      final count = await db.delete(
        'note_images',
        where: 'id = ?',
        whereArgs: [imageId],
      );

      if (count == 0) {
        return {
          'success': false,
          'message': 'Image not found',
        };
      }

      return {
        'success': true,
        'message': 'Image deleted',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete image: $e',
      };
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
