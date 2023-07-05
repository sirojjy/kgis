import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:http/http.dart' as http;
import '../helper/db_segments.dart';
import '../utils/util.dart';

const baseUrl = "http://simk.bpjt.pu.go.id/bpjt-teknik/public/index.php/api";
// const baseUrl = "http://103.6.53.254:13480/bpjt-teknik/public/index.php/api";
// const baseUrl = "http://192.168.100.4:8000/api";

class API {
  static Future authorize(String email, String password, String fcmToken, bool isLogout, String version) async {

    var url = Uri.parse(baseUrl + '/authorizes');
    
    var data = json.encode({
      "email": email,
      "password": password,
      "fcm_token": fcmToken,
      "should_logout": isLogout
    });

    var headers = {
      'Content-Type' : 'application/json',
      'Accept': 'application/json',
      'x-build-number': version
    };
  
    final response = await http.post(url, body: data, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  }

  static Future getAllTrackingProblems(String date, String segment, String userId, String role, String region, String version) async {
    var url = baseUrl + '/tracking_problems?all=true&is_hidden=false&';
    
    if (date != '') {
      url = url + 'date='+date.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    if (userId != '') {
      url = url + 'user_id='+userId.toString()+'&';
    }

    if (role != '') {
      url = url + 'role='+role.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }

    url = url + 'date[\$gte]=2022-06-01';

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future getAllActivities(String date, String segment, String userId, String role, String region, String version) async {
    var url = baseUrl + '/activities?all=true&is_hidden=false&';
    
    if (date != '') {
      url = url + 'date='+date.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    if (userId != '') {
      url = url + 'user_id='+userId.toString()+'&';
    }

    if (role != '') {
      url = url + 'role='+role.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }

    url = url + 'date[\$gte]=2022-06-01';

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };
    print(url);
    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future getTrackingProblems(int page, String dateFrom, String dateTo, String segment, String userId, String position, String name, String role, String region, String version) async {
    var url = baseUrl + '/tracking_problems?is_hidden=false&';

    if (page > 0) {
      url = url + 'page='+page.toString()+'&';
    }
    
    if (dateFrom != '') {
      url = url + 'date[\$gte]='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'date[\$lte]='+dateTo.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    if (userId != '') {
      url = url + 'user_id='+userId.toString()+'&';
    }

    if (position != '') {
      url = url + 'position='+position.toString()+'&';
    }

    if (name != '') {
      url = url + 'name='+name.toString()+'&';
    }

    if (role != '') {
      url = url + 'role='+role.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }
    
    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);

    print(url);

    var ret = json.decode(response.body);

    return ret;
  } 
  
  static Future getActivities(int page, String dateFrom, String dateTo, String segment, String userId, String position, String name, String role, String region, String version) async {
    var url = baseUrl + '/activities?';

    if (page > 0) {
      url = url + 'page='+page.toString()+'&';
    }
    
    if (dateFrom != '') {
      url = url + 'date[\$gte]='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'date[\$lte]='+dateTo.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    if (userId != '') {
      url = url + 'user_id='+userId.toString()+'&';
    }

    if (position != '') {
      url = url + 'position='+position.toString()+'&';
    }

    if (name != '') {
      url = url + 'name='+name.toString()+'&';
    }

    if (role != '') {
      url = url + 'role='+role.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };
    
    print(url);
    
    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future users(Map<String, dynamic> params, String version) async {
    var url = baseUrl + '/users';
    
    var data = json.encode(params);

    var headers = {
      'Content-Type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };
  
    final response = await http.post(url as Uri, body: data, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  }
  
  static Future storeTrackingProblem(Map<String, dynamic> params, String files, String version) async {
    //create multipart request for POST or PATCH method
    var request = http.MultipartRequest("POST", Uri.parse(baseUrl + "/tracking_problems"));
    //add text fields
    params.forEach((k,v){
      request.fields[k.toString()] = v.toString();
    });
    
    String filePath;

    if (files != "") {
      filePath = files.toString();

      if (filePath != "/") {
        if (!(files.toString()).contains(".pdf")) {
          // ImageProperties properties = await FlutterNativeImage.getImageProperties(files);
          
          File compressedFile = await FlutterNativeImage.compressImage(files, quality: 90);
          filePath = compressedFile.path;
        }
            
        //create multipart using filepath, string or bytes
        var pic = await http.MultipartFile.fromPath("files", filePath);
        //add multipart to request
        request.files.add(pic);
      }
    }
    request.headers["x-build-number"] = version;

    var response = await request.send();
    //Get the response from the server
    var responseData = await response.stream.toBytes();
    print(String.fromCharCodes(responseData));
    return json.decode(String.fromCharCodes(responseData));
  }

  static Future getUsers(bool isVerified, String params, String companyField, String segment, int page, String version) async {
    var url = baseUrl + '/user_or?role_id=0&';
    
    if (isVerified) {
      url = url + 'is_approve=true&';
    } else {
      url = url + 'is_approve=false&';
    }

    if (page > 0) {
      url = url + 'page='+page.toString()+'&';
    }

    if (companyField != '') {
      url = url + 'company_field='+companyField.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    if (params != "" && params != 'null') {
      url = url + 'name='+params+'&' + 'company='+params+'&' + 'phone='+params+'&' + 'email='+params+'&';
    }

    var headers = {
      'Connection': 'Keep-Alive',
      'x-build-number': version,
      'Content-type' : 'application/json',
      'Accept': 'application/json'
    };
    print(url);
    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future getUserByEmail(String email, String version) async {
    if (email == null) {
      return;
    }
    var url = baseUrl + '/users/'+email;

    var headers = {
      'Connection': 'Keep-Alive',
      'x-build-number': version,
      'Content-type' : 'application/json',
      'Accept': 'application/json'
    };
    
    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future getSegmentStatus(String version) async {
    var url = baseUrl + '/services/map/status';

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };
    print(url);
    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future getSegmentSubStatus(String status, String version) async {
    var url = baseUrl + '/services/map/sub_status?';

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    if (status != '') {
      url = url + 'status='+status.toString()+'&';
    }
    
    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future getSegmentRegion(String status, String subStatus, String version) async {
    var url = baseUrl + '/wms_layers/region?';

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    if (status != '') {
      url = url + 'status='+status.toString()+'&';
    }

    if (subStatus != '') {
      url = url + 'sub_status='+subStatus.toString()+'&';
    }
    print(url);
    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future getSegment(String status, String subStatus, String region, String isGroup, String version) async {
    // var url = baseUrl + '/services/map/segment?';
    var url = baseUrl + '/wms_layers/segment?';

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    if (status != '') {
      url = url + 'status='+status.toString()+'&';
    }

    if (subStatus != '') {
      url = url + 'sub_status='+subStatus.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }

    if (isGroup != '') {
      url = url + 'is_group='+isGroup.toString()+'&';
      if (!await Utils.checkServerStatus("google.com")) {
        List res = [];
        DbSegments dbSegment = DbSegments();

        List<Map<String, dynamic>> segments = await dbSegment.select();

        for (int i = 0; i < segments.length; i++) {
          res.add(segments[i]['segment']);
        }
        
        return res;
      }
    }
    print(url);
    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);
    print(ret);

    return ret;
  } 

  static Future getMapService(String status, String subStatus, String region, String segment, String version) async {
    var url = baseUrl + '/wms_layers/segment?';

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    if (status != '') {
      url = url + 'status='+status.toString()+'&';
    }

    if (subStatus != '') {
      url = url + 'sub_status='+subStatus.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    final response = await http.get(url as Uri, headers: headers);
    print(url);
    var ret = json.decode(response.body);

    return ret;
  } 

  static Future getFeatureServer(String destUrl, String type, String key, String version) async {
    var url = destUrl + '/query?f=json&geometry=&maxRecordCountFactor=30&outFields=*&outSR=4326&resultType=tile&returnExceededLimitFeatures=false&spatialRel=esriSpatialRelIntersects&where=1=1&geometryType=esriGeometryEnvelope';

    final response = await http.get(url as Uri);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future forgotPassword(String email, String version) async {
    var url = baseUrl + '/reset-password';
    
    var data = json.encode({
      "email": email
    });

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };
    print(data);
    final response = await http.post(url as Uri, body: data, headers: headers);
    print(url);
    var ret = json.decode(response.body);
    
    return ret;
  }

  static Future storeAttendance(Map<String, dynamic> params, String files, String version) async {
    //create multipart request for POST or PATCH method
    var request = http.MultipartRequest("POST", Uri.parse(baseUrl + "/attendances"));
    //add text fields
    params.forEach((k,v){
      request.fields[k.toString()] = v.toString();
    });
    print(request.fields);
    String filePath;

    filePath = files.toString();

    if (filePath != "/") {
      if (!(files.toString()).contains(".pdf")) {
        File compressedFile = await FlutterNativeImage.compressImage(files, quality: 90);
        filePath = compressedFile.path;
      }
          
      //create multipart using filepath, string or bytes
      var pic = await http.MultipartFile.fromPath("files", filePath);
      //add multipart to request
      request.files.add(pic);
    }

    request.headers["x-build-number"] = version;
    
    var response = await request.send();
    //Get the response from the server
    var responseData = await response.stream.toBytes();
    print(String.fromCharCodes(responseData));
    return json.decode(String.fromCharCodes(responseData));
  }

  static Future storeAvatar(Map<String, dynamic> params, String files, String version) async {
    //create multipart request for POST or PATCH method
    var request = http.MultipartRequest("POST", Uri.parse(baseUrl + "/avatars"));
    //add text fields
    params.forEach((k,v){
      request.fields[k.toString()] = v.toString();
    });
    print(request.fields);
    String filePath;

    filePath = files.toString();

    if (filePath != "/") {
      if (!(files.toString()).contains(".pdf")) {
        ImageProperties? properties = await FlutterNativeImage.getImageProperties(files);
        File compressedFile = await FlutterNativeImage.compressImage(files, quality: 80,
            targetWidth: 800,
            targetHeight: (properties?.height ?? 0 * 800 / (properties?.width ?? 1)).round()
        );
        filePath = compressedFile.path;
      }
          
      //create multipart using filepath, string or bytes
      var pic = await http.MultipartFile.fromPath("files", filePath);
      //add multipart to request
      request.files.add(pic);
    }

    request.headers["x-build-number"] = version;
    
    var response = await request.send();
    //Get the response from the server
    var responseData = await response.stream.toBytes();
    print(String.fromCharCodes(responseData));
    return json.decode(String.fromCharCodes(responseData));
  }

  static Future getAttendances(String time, String userId, String segment, String position, String dateFrom, String dateTo, int page, String name, String region, String version) async {
    var url = baseUrl + '/attendances?';

    if (time != '') {
      url = url + 'time='+time.toString()+'&';
    }

    if (userId != '') {
      url = url + 'user_id='+userId.toString()+'&';
    }

    if (page > 0) {
      url = url + 'page='+page.toString()+'&';
    }

    if (dateFrom != '') {
      url = url + 'time[\$gte]='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'time[\$lte]='+dateTo.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }

    if (position != '') {
      url = url + 'position='+position.toString()+'&';
    }

    if (name != '') {
      url = url + 'name='+name.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future getAttendancesAll(String time, String userId, String segment, String position, String dateFrom, String dateTo, int page, String name, String region, String version) async {
    var url = baseUrl + '/attendances?all=true&';

    if (time != '') {
      url = url + 'time='+time.toString()+'&';
    }

    if (userId != '') {
      url = url + 'user_id='+userId.toString()+'&';
    }

    if (page > 0) {
      url = url + 'page='+page.toString()+'&';
    }

    if (dateFrom != '') {
      url = url + 'time[\$gte]='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'time[\$lte]='+dateTo.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }

    if (position != '') {
      url = url + 'position='+position.toString()+'&';
    }

    if (name != '') {
      url = url + 'name='+name.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    print(url);
    
    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  } 

  static Future getUsersAll(int page, String segment, String position, String dateFrom, String dateTo, String name, String region, String companyField, String version) async {
    var url = baseUrl + '/users?';

    if (page > 0) {
      url = url + 'page='+page.toString()+'&';
    }

    if (dateFrom != '') {
      url = url + 'created_at[\$gte]='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'created_at[\$lte]='+dateTo.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }

    if (position != '') {
      url = url + 'position='+position.toString()+'&';
    }

    if (name != '') {
      url = url + 'name='+name.toString()+'&';
    }

    if (companyField != '') {
      url = url + 'company_field='+companyField.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };
    print(url);
    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  }

  static Future getRecaps(int page, String segment, String position, String dateFrom, String dateTo, String name, String version) async {
    var url = baseUrl + '/recaps?';

    if (page > 0) {
      url = url + 'page='+page.toString()+'&';
    }

    if (dateFrom != '') {
      url = url + 'date_from='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'date_to='+dateTo.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    if (position != '') {
      url = url + 'position='+position.toString()+'&';
    }

    if (name != '') {
      url = url + 'name='+name.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);
    print(url);
    var ret = json.decode(response.body);

    return ret;
  }
  
  static Future storeActivity(Map<String, dynamic> params, List files, String version) async {
    //create multipart request for POST or PATCH method
    print(params);
    var request = http.MultipartRequest("POST", Uri.parse(baseUrl + "/activities"));
    //add text fields
    params.forEach((k,v){
      request.fields[k.toString()] = v.toString();
    });
    
    for (var i = 0; i < files.length; i++) {
      String filePath;

      filePath = files[i].toString();

      if (!(files[i].toString()).contains(".pdf")) {
        // ImageProperties properties = await FlutterNativeImage.getImageProperties(files[i]);
        File compressedFile = await FlutterNativeImage.compressImage(files[i], quality: 90);
        filePath = compressedFile.path;
      }
          
      //create multipart using filepath, string or bytes
      var pic = await http.MultipartFile.fromPath("files['$i']", filePath);
      //add multipart to request
      request.files.add(pic);
    }
    
    request.headers["x-build-number"] = version;
    
    var response = await request.send();
    //Get the response from the server
    var responseData = await response.stream.toBytes();
    print(String.fromCharCodes(responseData));
    return json.decode(String.fromCharCodes(responseData));
  }

  static Future changePasswords(
    String id,
    String oldPassword,
    String newPassword
  , String version) async {
    var url = baseUrl + '/users/'+id;

    var data = json.encode({
      "old_password": oldPassword,
      "password": newPassword
    });

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.patch(url as Uri, body: data, headers: headers);

    var ret = json.decode(response.body);
    
    return ret;
  }

  static Future editUsers(Map<String, dynamic> params, String version) async {

    var url = baseUrl + '/users/'+params['id'];
    
    var data = json.encode(params);

    var headers = {
      'Content-Type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.patch(url as Uri, body: data, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  }

  static Future getSummaryData(String dateFrom, String dateTo, String region, String segment, String version) async {
    var url = baseUrl + '/dashboards/data_summary?';

    if (dateFrom != '') {
      url = url + 'date_from='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'date_to='+dateTo.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  }

  static Future getTotalUserPerCategory(String dateFrom, String dateTo, String region, String segment, String version) async {
    var url = baseUrl + '/dashboards/total_user_per_category?';

    if (dateFrom != '') {
      url = url + 'date_from='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'date_to='+dateTo.toString()+'&';
    }

    if (region != '') {
      url = url + 'region='+region.toString()+'&';
    }

    if (segment != '') {
      url = url + 'segment='+segment.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  }

  static Future getActivityChart(String dateFrom, String dateTo, String version) async {
    var url = baseUrl + '/charts/activity?';

    if (dateFrom != '') {
      url = url + 'date_from='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'date_to='+dateTo.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  }

  static Future getProblemChart(String dateFrom, String dateTo, String version) async {
    var url = baseUrl + '/charts/problem?';

    if (dateFrom != '') {
      url = url + 'date_from='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'date_to='+dateTo.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  }

  static Future getAttendanceChart(String dateFrom, String dateTo, String version) async {
    var url = baseUrl + '/charts/attendance?';

    if (dateFrom != '') {
      url = url + 'date_from='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'date_to='+dateTo.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  }

  static Future getUserTotalPerSegmentChart(String companyField, String dateFrom, String dateTo, String version) async {
    var url = baseUrl + '/charts/user_total_per_segment/'+companyField+'?';

    if (dateFrom != '') {
      url = url + 'date_from='+dateFrom.toString()+'&';
    }

    if (dateTo != '') {
      url = url + 'date_to='+dateTo.toString()+'&';
    }

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);

    var ret = json.decode(response.body);

    return ret;
  }

  static Future getFeatureInfo(String url) async {
    var headers = {
      'Content-type' : 'application/json',
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);
    
    var ret;

    if (response.statusCode < 300) {
      ret = json.decode(response.body);
    } else {
      ret = {
        "data": null
      };
    }

    return ret;
  }

  static Future getPosition(String version) async {
    var url = baseUrl + '/positions?all=true';

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };
    
    final response = await http.get(url as Uri, headers: headers);
    
    var ret = json.decode(response.body);

    return ret;
  }

  static Future getDateTime(String version, String timezone) async {
    var url = baseUrl + '/datetimes?timezone=$timezone';

    var headers = {
      'Content-type' : 'application/json',
      'x-build-number': version,
      'Accept': 'application/json'
    };
    
    final response = await http.get(url as Uri, headers: headers);
    
    var ret = json.decode(response.body);

    return ret;
  }

  static Future measureDistance(String originLat, String originLong, String destLat, String destLong) async {
    var url = baseUrl + '/measure_distances?origin_latitude=$originLat&origin_longitude=$originLong&destination_latitude=$destLat&destination_longitude=$destLong';

    var headers = {
      'Content-type' : 'application/json',
      'Accept': 'application/json'
    };

    final response = await http.get(url as Uri, headers: headers);
    print(url);
    var ret = json.decode(response.body);

    return ret;
  } 
}