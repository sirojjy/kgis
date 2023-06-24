import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import '../conn/API.dart';
import 'db.dart';

class DbPresences {
  static DbPresences? _dbPresences;
  static Database? _database;

  static const columnIsSync = 'is_sync';

  DbPresences._createObject();

  Future<Map<String, dynamic>> getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    Map<String, dynamic> ret = Map<String, dynamic>();

    ret['app_name'] = packageInfo.appName;
    ret['package_name'] = packageInfo.packageName;
    ret['version'] = packageInfo.version;
    ret['build_number'] = packageInfo.buildNumber;

    return ret;
  }
  
  factory DbPresences() {
    _dbPresences ??= DbPresences._createObject();
    return _dbPresences!;
  }

  Future<int> getCount() async {
      //database connection
      Database db = await database;
      var x = await db.rawQuery("SELECT COUNT (*) from presences WHERE status = 'in' OR status = 'out'");
      int count = Sqflite.firstIntValue(x)!;
      return count;
  }

  Future<int> getCountPresent(String date) async {
      //database connection
      Database db = await database;
      var x = await db.rawQuery("SELECT COUNT (*) from presences WHERE status = 'in' AND date = '$date'");
      int count = Sqflite.firstIntValue(x)!;
      return count;
  }

  Future<int> getCountAttendanceLocal(String date) async {
    print("ASDASD");
    print(date);
    print("ASDASD");

    // Database db = await this.database;
    Directory directory = await getApplicationDocumentsDirectory();
    String pathActivity = '${directory.path}/bpjt_teknik.db';
    print("ASDASD");
    Database db = await openDatabase(pathActivity);
    print("ASDASD");
    var x = await db.rawQuery("SELECT COUNT (*) from presences WHERE (status = 'in' OR status = 'permit') AND date = '$date'");
    int count = Sqflite.firstIntValue(x)!;

    return count;
  }

  Future<int> getCountPermit(String date) async {
      //database connection
      Database db = await database;
      var x = await db.rawQuery("SELECT COUNT (*) from presences WHERE status = 'permit' AND date = '$date'");
      int count = Sqflite.firstIntValue(x)!;
      return count;
  }

  Future<Database> get database async {
    var db = Db();
    _database ??= await db.init();
    return _database!;
  }

  Future<List<Map<String, dynamic>>> select() async {
    Database db = await database;
    var mapList = await db.query('presences', orderBy: 'id');
    return mapList;
  }

  Future<List<Map<String, dynamic>>> selectUnsync() async {
    Database db = await database;
    var mapList = await db.query('presences', where: 'is_sync=?', whereArgs: [0]);
    return mapList;
  }

//create databases
  Future<int> insert(Map<String, dynamic> params) async {
    Database db = await database;
    print(db);
    int count = await db.insert('presences', params);
    print(count);
    return count;
  }
//update databases
  Future<int> update(Map<String, dynamic> object, int id) async {
    Database db = await database;
    int count = await db.update('presences', object, 
                                where: 'id=?',
                                whereArgs: [id]);
    return count;
  }

//delete databases
  Future<int> delete(int id) async {
    Database db = await database;
    int count = await db.delete('presences', 
                                where: 'id=?', 
                                whereArgs: [id]);
    return count;
  }

  Future<bool> sendPresencesUnsync() async {
    Map<String, dynamic> version = await getInfo();
    var presencesMapList = await selectUnsync();
    int count = presencesMapList.length;
    for (int i=0; i<count; i++) {
      Map<String, dynamic> params = Map<String, dynamic>();
      params["user_id"] = presencesMapList[i]["user_id"];
      params["long"] = presencesMapList[i]["long"];
      params["lat"] = presencesMapList[i]["lat"];
      params["status"] = presencesMapList[i]["status"];
      params["note"] = presencesMapList[i]["note"];
      params["location"] = presencesMapList[i]["location"];
      params["time"] = '${presencesMapList[i]["date"]} ${presencesMapList[i]["time"]}';

      await API.storeAttendance(
        params,
        presencesMapList[i]["files"],
        version["version"]
      ).then((response) {
        print("Sync to server");
        print(response);
        if (response["status"] == "success") {
          Map<String, dynamic> row = {
            DbPresences.columnIsSync: 1
          };
          update(row, presencesMapList[i]["id"]);
        }
      });
    }
    return true;
  }
}