import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_settings.dart';
import '../models/expense.dart';
import 'expense_repository.dart';
import 'settings_repository.dart';

/// SQLite-backed [ExpenseRepository] and [SettingsRepository].
///
/// The database is opened lazily on first use and reused afterwards. Every
/// failure is translated into a [StorageException] with a message that is safe
/// to show in the UI, while the original error is kept for diagnostics.
class ExpenseDatabase implements ExpenseRepository, SettingsRepository {
  ExpenseDatabase({DatabaseFactory? factory, String? databasePath})
    : _factory = factory ?? databaseFactory,
      _databasePath = databasePath;

  /// File name used on device.
  static const String databaseName = 'spendtrack.db';

  /// Table holding one row per expense.
  static const String tableName = 'expenses';

  /// Key/value table holding user preferences.
  static const String settingsTableName = 'app_settings';

  /// Bumped whenever the schema changes so [onUpgrade] can migrate data.
  static const int schemaVersion = 2;

  final DatabaseFactory _factory;

  /// Overrides the on-device path. Tests pass an in-memory or temp path here.
  final String? _databasePath;

  Future<Database>? _databaseFuture;

  Future<Database> get _database => _databaseFuture ??= _open();

  Future<Database> _open() async {
    try {
      final path =
          _databasePath ??
          p.join(await _factory.getDatabasesPath(), databaseName);

      return await _factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onCreate: _createSchema,
          onUpgrade: _upgradeSchema,
        ),
      );
    } catch (error) {
      // Allow a later retry instead of caching a failed open forever.
      _databaseFuture = null;
      throw StorageException(
        'Unable to open the expense database on this device.',
        error,
      );
    }
  }

  Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        note TEXT
      )
    ''');
    await database.execute(
      'CREATE INDEX idx_${tableName}_date '
      'ON $tableName (date DESC, created_at DESC)',
    );
    await _createSettingsSchema(database);
  }

  Future<void> _createSettingsSchema(Database database) async {
    await database.execute('''
      CREATE TABLE $settingsTableName (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeSchema(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createSettingsSchema(database);
    }
  }

  @override
  Future<List<Expense>> loadExpenses() async {
    try {
      final database = await _database;
      final rows = await database.query(
        tableName,
        orderBy: 'date DESC, created_at DESC',
      );
      return rows.map(_fromRow).toList(growable: false);
    } on FormatException {
      // Surface corrupt rows with the provider's format-specific message.
      rethrow;
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'Unable to load your expenses. Please try again.',
        error,
      );
    }
  }

  @override
  Future<void> insertExpense(Expense expense) async {
    try {
      final database = await _database;
      await database.insert(
        tableName,
        _toRow(expense),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on StorageException {
      rethrow;
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw StorageException(
          'An expense with this ID already exists.',
          error,
        );
      }
      throw StorageException(
        'Unable to save your expense. Please try again.',
        error,
      );
    } catch (error) {
      throw StorageException(
        'Unable to save your expense. Please try again.',
        error,
      );
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      final database = await _database;
      final values = _toRow(expense)..remove('id');
      final updated = await database.update(
        tableName,
        values,
        where: 'id = ?',
        whereArgs: <Object?>[expense.id],
      );

      if (updated == 0) {
        throw const StorageException('That expense could not be found.');
      }
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'Unable to update your expense. Please try again.',
        error,
      );
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      final database = await _database;
      final deleted = await database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );

      if (deleted == 0) {
        throw const StorageException('That expense could not be found.');
      }
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'Unable to delete your expense. Please try again.',
        error,
      );
    }
  }

  @override
  Future<void> clearExpenses() async {
    try {
      final database = await _database;
      await database.delete(tableName);
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'Unable to clear your expenses. Please try again.',
        error,
      );
    }
  }

  @override
  Future<AppSettings> loadSettings() async {
    try {
      final database = await _database;
      final rows = await database.query(settingsTableName);
      final values = <String, String?>{
        for (final row in rows)
          if (row['key'] is String && row['value'] is String)
            row['key']! as String: row['value'] as String,
      };
      return AppSettings.fromMap(values);
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'Unable to load your settings. Please try again.',
        error,
      );
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final database = await _database;
      await database.transaction((transaction) async {
        for (final entry in settings.toMap().entries) {
          await transaction.insert(settingsTableName, <String, Object?>{
            'key': entry.key,
            'value': entry.value,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'Unable to save your settings. Please try again.',
        error,
      );
    }
  }

  /// Releases the underlying database connection.
  Future<void> close() async {
    final future = _databaseFuture;
    _databaseFuture = null;
    if (future == null) {
      return;
    }

    try {
      final database = await future;
      await database.close();
    } catch (_) {
      // The database never opened successfully; nothing to release.
    }
  }

  Map<String, Object?> _toRow(Expense expense) {
    return <String, Object?>{
      'id': expense.id,
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category.name,
      'date': expense.date.toIso8601String(),
      'created_at': expense.createdAt.toIso8601String(),
      'note': expense.note,
    };
  }

  Expense _fromRow(Map<String, Object?> row) {
    return Expense.fromJson(<String, dynamic>{
      'id': row['id'],
      'title': row['title'],
      'amount': row['amount'],
      'category': row['category'],
      'date': row['date'],
      'createdAt': row['created_at'],
      'note': row['note'],
    });
  }
}
