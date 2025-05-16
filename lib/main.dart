import 'package:flutter/material.dart';
import 'package:tikitar_demo/features/auth/login_screen.dart';
import 'package:tikitar_demo/features/other/splash_screen.dart';
import 'package:tikitar_demo/features/webview/company_list_screen.dart';
import 'package:tikitar_demo/features/webview/dashboard_screen.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';
import 'package:tikitar_demo/features/webview/my_profile_screen.dart';
import 'package:tikitar_demo/features/webview/task_screen.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "tikitar.db";
  static final _databaseVersion = 1;

  static final table = 'locations';
  static final columnId = '_id';
  static final columnName = 'name';
  static final columnLatitude = 'latitude';
  static final columnLongitude = 'longitude';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure this line is there
  //You're calling SharedPreferences.getInstance() before Flutter is fully ready,
  //most likely before WidgetsFlutterBinding.ensureInitialized() is called.
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{
  DatabaseHelper dbHelper = DatabaseHelper._privateConstructor();
  List<Map<String, dynamic>> _locations = [];

  
  @override
  void initState() {
    super.initState();
    _performDatabaseOperations();
  }

  Future<void> _performDatabaseOperations() async {
    // Insert sample data
    int insertedId = await dbHelper.insertData({
      'name': 'Sample Place',
      'latitude': '28.7041',
      'longitude': '77.1025',
    });
    print('Inserted ID: $insertedId');

    // Retrieve all rows
    List<Map<String, dynamic>> allRows = await dbHelper.retrieveAllData();
    print('All rows: $allRows');

    // Update the inserted row
    await dbHelper.updateData({
      '_id': insertedId,
      'name': 'Updated Place',
      'latitude': '28.7000',
      'longitude': '77.1000',
    });

    // Retrieve again
    List<Map<String, dynamic>> updatedRows = await dbHelper.retrieveAllData();
    print('After update: $updatedRows');

    // Delete the row
    await dbHelper.deleteData(insertedId);

    // Check final state
    List<Map<String, dynamic>> finalRows = await dbHelper.retrieveAllData();
    print('After delete: $finalRows');

    // Update UI with current DB data
    setState(() {
      _locations = finalRows;
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // initial route when app starts
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/task': (context) => TaskScreen(),
        '/profile': (context) => MyProfileScreen(),
        '/meetingList': (context) => MeetingListScreen(),
        '/companyList': (context) => CompanyListScreen(),
        '/addTask': (context) => TaskScreen(),
        // Add other screens here like '/profile': (context) => ProfileScreen(),
      },
      // home: WebviewScreen(url: "https://tikidemo.com/tikitar-app/dev/company-list.php#"),
    );
  }
}
