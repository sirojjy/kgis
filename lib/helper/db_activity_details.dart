import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'db.dart';

class DbActivityDetails {
  static DbActivityDetails? _dbActivityDetails;
  static Database? _database;

  static final columnIsSync = 'is_sync';

  DbActivityDetails._createObject();

  factory DbActivityDetails() {
    if (_dbActivityDetails == null) {
      _dbActivityDetails = DbActivityDetails._createObject();
    }
    return _dbActivityDetails!;
  }

  Future<Database> get database async {
    var db = new Db();
    if (_database == null) {
      _database = await db.init();
    }
    return _database!;
  }

  Future<List<Map<String, dynamic>>> select() async {
    Database db = await this.database;
    var mapList = await db.query('activity_details', orderBy: 'id');
    return mapList;
  }

  Future<List<Map<String, dynamic>>> selectWhereActivityId(String activityId) async {
    Database db = await this.database;
    var mapList = await db.query('activity_details', where: 'activity_id=?', whereArgs: [activityId]);
    return mapList;
  }

  Future<List<Map<String, dynamic>>> selectUnsync() async {
    Database db = await this.database;
    var mapList = await db.query('activity_details', where: 'is_sync=?', whereArgs: [0]);
    return mapList;
  }

  Future<int> insert(Map<String, dynamic> params) async {
    Database db = await this.database;
    int count = await db.insert('activity_details', params);
    return count;
  }
  
  Future<int> update(Map<String, dynamic> object, int id) async {
    Database db = await this.database;
    int count = await db.update('activity_details', object, 
                                where: 'id=?',
                                whereArgs: [id]);
    return count;
  }

  Future<int> delete(int id) async {
    Database db = await this.database;
    int count = await db.delete('activity_details', 
                                where: 'id=?', 
                                whereArgs: [id]);
    return count;
  }
}