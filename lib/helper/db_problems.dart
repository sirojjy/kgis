import 'package:bpjtteknik/conn/API.dart';
import 'package:bpjtteknik/helper/db_problem_details.dart';
import 'package:package_info/package_info.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

import 'db.dart';

class DbProblems {
  static DbProblems _dbProblems;
  static Database _database;
  
  DbProblemDetails dbProblemDetail = DbProblemDetails();

  static final columnIsSync = 'is_sync';

  DbProblems._createObject();

  Future<Map<String, dynamic>> getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    Map<String, dynamic> ret = Map<String, dynamic>();

    ret['app_name'] = packageInfo.appName;
    ret['package_name'] = packageInfo.packageName;
    ret['version'] = packageInfo.version;
    ret['build_number'] = packageInfo.buildNumber;

    return ret;
  }
  
  factory DbProblems() {
    if (_dbProblems == null) {
      _dbProblems = DbProblems._createObject();
    }
    return _dbProblems;
  }

  Future<Database> get database async {
    var db = new Db();
    if (_database == null) {
      _database = await db.init();
    }
    return _database;
  }

  Future<List<Map<String, dynamic>>> select() async {
    Database db = await this.database;
    var mapList = await db.query('problems', orderBy: 'id');
    return mapList;
  }

  Future<List<Map<String, dynamic>>> selectUnsync() async {
    Database db = await this.database;
    var mapList = await db.query('problems', where: 'is_sync=?', whereArgs: [0]);
    return mapList;
  }

//create databases
  Future<int> insert(Map<String, dynamic> params) async {
    Database db = await this.database;
    int count = await db.insert('problems', params);
    return count;
  }
//update databases
  Future<int> update(Map<String, dynamic> object, int id) async {
    Database db = await this.database;
    int count = await db.update('problems', object, 
                                where: 'id=?',
                                whereArgs: [id]);
    return count;
  }

//delete databases
  Future<int> delete(int id) async {
    Database db = await this.database;
    int count = await db.delete('problems', 
                                where: 'id=?', 
                                whereArgs: [id]);
    return count;
  }

  Future<bool> sendProblemsUnsync() async {
    Map<String, dynamic> version = await getInfo();
    
    var problemsMapList = await selectUnsync();
    int count = problemsMapList.length;
    for (int i=0; i<count; i++) {

      Map<String, dynamic> params = Map<String, dynamic>();
      params["user_id"] = problemsMapList[i]["user_id"];
      params["problem"] = problemsMapList[i]["problem"];
      params["long"] = problemsMapList[i]["long"];
      params["lat"] = problemsMapList[i]["lat"];
      params["segment"] = problemsMapList[i]["segment"];
      params["priority"] = problemsMapList[i]["priority"];
      params["location"] = problemsMapList[i]["location"];

      await API.storeTrackingProblem(
        params,
        problemsMapList[i]["files"],
        version["version"]
      ).then((response) {
        print("Sync to server");
        print(response);
        if (response["status"] == "success") {
          Map<String, dynamic> row = {
            DbProblems.columnIsSync: 1
          };
          update(row, problemsMapList[i]["id"]);
        }
      });
    }
    return true;
  }
}