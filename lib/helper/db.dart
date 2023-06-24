import 'package:bpjt_k_gis_mobile_master/helper/db_segments.dart';
import 'package:bpjt_k_gis_mobile_master/utils/util.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'db_activities.dart';
import 'db_presences.dart';
import 'db_problems.dart';

class Db {
  Future<Database> init() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String pathActivity = '${directory.path}/bpjt_teknik.db';

    var db = await openDatabase(pathActivity, version: 1, onCreate: _createDbSchema);

    return db;
  }

    //buat tabel baru dengan nama activities
  void _createDbSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        name TEXT,
        company_field TEXT,
        phone TEXT,
        email TEXT,
        position TEXT,
        activity TEXT,
        long TEXT,
        lat TEXT,
        segment TEXT,
        date TEXT,
        is_active TEXT,
        is_delete TEXT,
        is_hidden TEXT,
        priority TEXT,
        location TEXT,
        is_sync INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id TEXT,
        files TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE presences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        date TEXT,
        time TEXT,
        long TEXT,
        lat TEXT,
        status TEXT,
        note TEXT,
        identifier TEXT,
        location TEXT,
        files TEXT,
        is_sync INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE problem_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        problem_id TEXT,
        problem TEXT,
        type TEXT,
        files TEXT,
        suggestion TEXT,
        long TEXT,
        lat TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE problems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        problem TEXT,
        long TEXT,
        lat TEXT,
        files TEXT,
        segment TEXT,
        date TEXT,
        priority TEXT,
        location TEXT,
        is_sync INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE segments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        segment TEXT
      )
    ''');
  }

  static void syncToServer() async {
    DbPresences dbPresence = DbPresences();
    DbProblems dbProblem = DbProblems();
    DbActivities dbActivity = DbActivities();
    DbSegments dbSegment = DbSegments();

    if (await Utils.checkConnection()) {
      await dbPresence.sendPresencesUnsync();
      await dbProblem.sendProblemsUnsync();
      await dbActivity.sendActivitiesUnsync();
      await dbSegment.select();

    } else {
      print("disconnected");
    }
  }

  Future deleteDb() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/bpjt_teknik.db';
    
    try{
      deleteDatabase(path);
    } catch(e) {
      print(e.toString());
    }
  }
}