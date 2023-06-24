import 'package:sqflite/sqflite.dart';
import 'dart:async';

import 'db.dart';

class DbProblemDetails {
  static DbProblemDetails? _dbProblemDetails;
  static Database? _database;

  static const columnIsSync = 'is_sync';

  DbProblemDetails._createObject();

  factory DbProblemDetails() {
    _dbProblemDetails ??= DbProblemDetails._createObject();
    return _dbProblemDetails!;
  }

  Future<Database> get database async {
    var db = Db();
    _database ??= await db.init();
    return _database!;
  }

  Future<List<Map<String, dynamic>>> select() async {
    Database db = await database;
    var mapList = await db.query('problem_details', orderBy: 'id');
    return mapList;
  }

  Future<List<Map<String, dynamic>>> selectWhereProblemId(String problemId) async {
    Database db = await database;
    var mapList = await db.query('problem_details', where: 'problem_id=?', whereArgs: [problemId]);
    return mapList;
  }

  Future<List<Map<String, dynamic>>> selectUnsync() async {
    Database db = await database;
    var mapList = await db.query('problem_details', where: 'is_sync=?', whereArgs: [0]);
    return mapList;
  }

  Future<int> insert(Map<String, dynamic> params) async {
    Database db = await database;
    int count = await db.insert('problem_details', params);
    return count;
  }
  
  Future<int> update(Map<String, dynamic> object, int id) async {
    Database db = await database;
    int count = await db.update('problem_details', object, 
                                where: 'id=?',
                                whereArgs: [id]);
    return count;
  }

  Future<int> delete(int id) async {
    Database db = await database;
    int count = await db.delete('problem_details', 
                                where: 'id=?', 
                                whereArgs: [id]);
    return count;
  }
}