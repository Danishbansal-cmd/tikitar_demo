
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

class DatabaseHelper {
  static final _databaseName = "tikitar.db";
  static final _databaseVersion = 2;

  static final table = 'locations';
  static final columnId = '_id';
  static final columnName = 'name';
  static final columnLatitude = 'latitude';
  static final columnLongitude = 'longitude';

  // make this a singleton class
  DatabaseHelper.privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper.privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    developer.log("_initDatabase executed", name: "MyApp");
    String path = join(await getDatabasesPath(), _databaseName);
    await deleteDatabase(path);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnName TEXT NOT NULL,
            $columnLatitude TEXT NOT NULL,
            $columnLongitude TEXT NOT NULL
          )
          ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Example: Add a new column instead of dropping the table
          await db.execute('ALTER TABLE $table ADD COLUMN some_new_column TEXT');
        }
      }
    );
  }

  // insert
  Future<int> insertData(Map<String, dynamic> rowData) async {
    Database db = await database;
    return await db.insert(table, rowData);
  }

  // retreive all
  Future<List<Map<String, dynamic>>> retrieveAllData() async {
    Database db = await database;
    return await db.query(table);
  }

  // UPDATE
  Future<int> updateData(Map<String, dynamic> rowData) async {
    // here we need to add the
    Database db = await database;
    int id = rowData[columnId];
    return await db.update(
      table,
      rowData,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // DELETE
  Future<int> deleteData(int id) async {
    Database db = await database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}