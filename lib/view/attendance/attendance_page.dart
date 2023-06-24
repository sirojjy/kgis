import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:art_sweetalert/art_sweetalert.dart';
import 'package:bpjt_k_gis_mobile_master/conn/API.dart';
import 'package:bpjt_k_gis_mobile_master/helper/db.dart';
import 'package:bpjt_k_gis_mobile_master/helper/db_presences.dart';
import 'package:bpjt_k_gis_mobile_master/helper/main_helper.dart' as helper;
import 'package:bpjt_k_gis_mobile_master/helper/main_helper.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:bpjt_k_gis_mobile_master/utils/utils.dart';
import 'package:bpjt_k_gis_mobile_master/view/dashboard/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sweetalert/sweetalert.dart';
import 'package:flutter_native_timezone_updated_gradle/flutter_native_timezone.dart';
///ganti flutter_native_timezone ke flutter_native_timezone_updated_gradle

class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late BuildContext dialogContext;

  String _timezone = 'Unknown';

  bool _loading = false;
  bool _disableButton = false;
  bool isPopupInitShow = false;
  
  late Timer timerGetTime;
  
  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  var prefSegment;

  late StateSetter timeState;

  late String _timeString;
  late String districtSubdistrict;
  late String cityRegion;
  late String completeLocation;
  late String appName;
  late String packageName;
  late String version;
  late String buildNumber;
  
  int countPresent = 0;
  int countPermit = 0;
  int countPresentHoliday = 0;
  int countPresentWeekend = 0;
  
  late Position _position;
  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];
  
  late File _image;

  TextEditingController _reasonController = new TextEditingController();

  DbPresences dbPresences = DbPresences();

  _getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }
  
  Future _getImage() async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy – kk:mm').format(now);
    final ImagePicker _imagePicker = ImagePicker();
    // var image = await _imagePicker.pickImage(source: ImageSource.camera);
    // img.Image? im = img.decodeImage(image?.readAsBytesSync());
    XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      img.Image? im = img.decodeImage(await image.readAsBytes());
      if (im != null) {
        img.Image convertImage = img.copyResize(im, width: 800);

        img.Image drawName = img.drawString(img.Image.from(convertImage), font: img.arial24, prefName);
        img.Image drawDateTime = img.drawString(img.Image.from(drawName), font: img.arial24, formattedDate);
        img.Image drawSegment = img.drawString(img.Image.from(drawDateTime), font: img.arial24, prefSegment);
        img.Image drawLongLat = img.drawString(img.Image.from(drawSegment), font: img.arial24, '${_position.latitude} ${_position.longitude}');
        img.Image drawDistrictSubdistrict = img.drawString(img.Image.from(drawLongLat), font: img.arial24,districtSubdistrict);
        img.Image drawCityRegion = img.drawString(img.Image.from(drawDistrictSubdistrict), font: img.arial24, cityRegion);
        img.Image drawAltitude = img.drawString(img.Image.from(drawCityRegion), font: img.arial24, '${_position.altitude}');

        List<int> encodedImage = img.encodePng(drawAltitude);
        File(image.path).writeAsBytesSync(encodedImage);
        setState(() {
          _image = File(image.path);
        });
      }
    }
  }
  
  _getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefId = prefs.getString('id');
    prefName = prefs.getString('name');
    prefCompany = prefs.getString('company');
    prefCompanyField = prefs.getString('company_field');
    prefPhone = prefs.getString('phone');
    prefEmail = prefs.getString('email');
    prefRoleId = prefs.getString('role_id');
    prefIsApprove = prefs.getBool('is_approve');
    prefSegment = prefs.getString('segments');
    if (jsonDecode(prefSegment).isEmpty) {
      prefSegment = "NO SEGMENT";
    } else {
      prefSegment = jsonDecode(prefSegment)[0];
    }
  }
  
  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }
  
  Future<void> initTimezone() async {
    String timezone;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      timezone = await FlutterNativeTimezone.getLocalTimezone();
    } on PlatformException {
      timezone = 'Failed to get the timezone.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _timezone = timezone;
    });
  }

  @override
  void initState() {
    super.initState();
    initTimezone().then((value) {
      _timeString = _formatTime(DateTime.now());
      timerGetTime = Timer.periodic(Duration(seconds: 1), (Timer t) => _getTime());
    });

    Db.syncToServer();
    _getInfo().then((resInfo) {
      _getPref().then((response) {
        _checkAttendance();
        _checkPermission();
        _getCurrentPosition();
        _addLocationStream();
        _checkRangeSummary();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timerGetTime?.cancel();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatTime(now);
    if (!mounted) return;
    // timeState(() {
    //   _timeString = formattedDateTime;
    // });
  }

  _getCurrentPosition() async {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      setState(() {
        _position = position;
        districtSubdistrict = "${placemarks.first.subLocality}, ${placemarks.first.locality}";
        cityRegion = "${placemarks.first.subAdministrativeArea}, ${placemarks.first.administrativeArea}";
        completeLocation = "${placemarks.first.street}, $districtSubdistrict, $cityRegion";
      });
  }

  _addLocationStream() {
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.high, distanceFilter: 10)
        .listen((Position position) {

      setState(() {
        _position = position;
      });
    });
    _streamSubscriptions.add(positionStream);
  }

  _checkPermission() async {
    await Geolocator.checkPermission();
  }

  _checkAttendance() async {
    await API.getAttendances(DateFormat('yyyy-MM-dd').format(DateTime.now()), prefId, "", "", "", "", 0, "", "", version).then((response) {
      if (!mounted) return;
      helper.showUpdateAppsModal(context, response);
      setState(() {
        if (response != null) {
          if (response["data"].length > 0) {
            _disableButton = true;
          }
        }
      });
    });
  }

  _checkRangeSummary() async {
    await API.getAttendancesAll("", prefId, "", "", "${DateFormat('yyyy-MM').format(DateTime.now())}-01", "${DateFormat('yyyy-MM-dd').format(DateTime.now())} 23:59:59", 0, "", "", version).then((response) {
      if (!mounted) return;
      helper.showUpdateAppsModal(context, response);
      int totalPresent = 0;
      int totalPermit = 0;
      int totalPresentHoliday = 0;
      int totalPresentWeekend = 0;

      if (response != null) {
        var res = response["data"];
        int resLength = res.length;
        for (var i = 0; i < resLength; i++) {
          if (res[i]["status"] == "in") {
            totalPresent += 1;
          } else if (res[i]["status"] == "permit") {
            totalPermit += 1;
          } else if (res[i]["status"] == "holiday") {
            totalPresentHoliday += 1;
          } else if (res[i]["status"] == "weekend") {
            totalPresentWeekend += 1;
          }
        }
      }

      setState(() {
        countPresent = totalPresent;
        countPermit = totalPermit;
        countPresentHoliday = totalPresentHoliday;
        countPresentWeekend = totalPresentWeekend;
      });

      _summaryAttendance(context);
    });
  }

  _permitAttendance(BuildContext context) async {
    if (_image == null) {
      setState(() {
        _loading = false;
      });

      ArtSweetAlert.show(
          context: context,
          artDialogArgs: ArtDialogArgs(
              type: ArtSweetAlertType.danger,
              title: "Error",
              text: "Silahkan lakukan foto terlebih dahulu."
          )
        // context,
        // title: "Error",
        // subtitle: "Silahkan lakukan foto terlebih dahulu",
        // style: SweetAlertStyle.error,
        // onPress: (bool isConfirm) {
        //   return true;
        // }
      );

      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context){
        dialogContext = context;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: contentBox(context),
        );
      }
    );
  }

  _summaryAttendance(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: contentSummaryBox(context),
        );
      }
    );
  }

  _submit(String attendanceType, String permitReason) async {
    setState(() {
      _loading = true;
    });
    
    if (_image == null) {
      setState(() {
        _loading = false;
      });

      ArtSweetAlert.show(
          context: context,
          artDialogArgs: ArtDialogArgs(
              type: ArtSweetAlertType.danger,
              title: "Error",
              text: "Silahkan lakukan foto terlebih dahulu"
          )
        // context,
        // title: "Error",
        // subtitle: "Silahkan lakukan foto terlebih dahulu",
        // style: SweetAlertStyle.error,
        // onPress: (bool isConfirm) {
        //   return true;
        // }
      );

      return;
    }

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('H:m:s').format(now);

    await API.getDateTime(version, _timezone).then((response) {
      if (!mounted) return;
      helper.showUpdateAppsModal(context, response);
      setState(() {
        if (response != null) {
          print(_timezone);
          formattedDate = response['date'];
          formattedTime = response['time'];
        }
      });
    });

    Map<String, dynamic> params = Map<String, dynamic>();
    params["user_id"] = prefId;
    params["long"] = _position.longitude.toString();
    params["lat"] = _position.latitude.toString();
    params["status"] = attendanceType;
    params["note"] = permitReason;
    params["location"] = completeLocation;
    params["files"] = _image.path;
    params["date"] = formattedDate;
    params["time"] = formattedTime;
    dbPresences.insert(params);
    if (attendanceType == "permit") {
      Navigator.pop(dialogContext);
    }
    ArtSweetAlert response = await ArtSweetAlert.show(
        context: context,
        artDialogArgs: ArtDialogArgs(
            type: ArtSweetAlertType.success,
            title: "Sukses",
            text: "Sukses melakukan absen"
        )
    //   title: "Sukses",
    //   subtitle: "Sukses melakukan absen",
    //   style: SweetAlertStyle.success,
    //   onPress: (bool isConfirm) {
    //     if (isConfirm) {
    //       Navigator.of(context).pop();
    //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => DashboardPage()));
    //     }
    //     return;
    //   }
    );
    if(response != null) {
      Navigator.of(context).pop();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => DashboardPage()));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Absensi Petugas'),
        backgroundColor: colorPrimary,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        child: Container(
          padding: EdgeInsets.all(15.0),
          child: ListView(
            children: [
              Text(
                completeLocation == null ?
                "Sedang Mengkalibrasi Posisi Anda" :
                completeLocation,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.0,
                  fontStyle: FontStyle.italic
                ),
              ),
              Text(
                _position == null ?
                "Sedang Mengkalibrasi Koordinat Anda" :
                "Lat : ${_position.latitude.toString()}, Long : ${_position.longitude.toString()}",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.0,
                  fontStyle: FontStyle.italic
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                _disableButton ?
                "Anda sudah absen hari ini!" :
                "Silahkan Absen",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center
              ),
              Text(
                _position == null ?
                "Harap Tunggu Sedang Mengkalibrasi Jarak Akurat Anda" :
                "Akurat Hingga "+_position.accuracy.toStringAsFixed(0).toString()+" Meter",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center
              ),
              // SizedBox(height: 5.0),
              // StatefulBuilder(
              //   builder: (context, setState) {
              //     timeState = setState;

              //     return Container(
              //       child: Align(
              //         alignment: Alignment.center,
              //         child: Text(
              //           _timeString,
              //           style: TextStyle(
              //             color: colorSecondary, fontSize: 50.0
              //           )
              //         ),
              //       ),
              //     );
              //   }
              // ),
              SizedBox(height: 10.0),
              displaySelectedFile(_image),
              Container(
                child: Text('*Klik Pada Gambar Diatas Untuk Mengambil Foto Anda', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.0),textAlign: TextAlign.center,),
              ),
              SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (!_disableButton) {
                            _permitAttendance(context);
                          }
                        },
                        child: Icon(Icons.remove_circle),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(width: 0.5, color: Colors.grey),
                          primary: _disableButton ? Colors.grey : Colors.red,
                          backgroundColor: Colors.white,
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                          shadowColor: Colors.white
                        ),
                      ),
                      SizedBox(height: 5.0),
                      Text(
                        "Ijin",
                        style: TextStyle(
                          fontSize: 11.0
                        ),
                      )
                    ],
                  ),
                  // Column(
                  //   children: [
                  //     ElevatedButton(
                  //       onPressed: () {
                  //         if (!_disableButton) {
                  //           _permitAttendance(context);
                  //         }
                  //       },
                  //       child: Icon(Icons.calendar_today_outlined),
                  //       style: OutlinedButton.styleFrom(
                  //         side: BorderSide(width: 0.5, color: Colors.grey),
                  //         primary: _disableButton ? Colors.grey : Colors.red,
                  //         backgroundColor: Colors.white,
                  //         shape: CircleBorder(),
                  //         padding: EdgeInsets.all(15),
                  //         shadowColor: Colors.white
                  //       ),
                  //     ),
                  //     SizedBox(height: 5.0),
                  //     Text(
                  //       "Absen Libur Nasional",
                  //       style: TextStyle(
                  //         fontSize: 11.0
                  //       ),
                  //     )
                  //   ],
                  // ),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _summaryAttendance(context);
                        },
                        child: Icon(Icons.my_library_books_outlined),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(width: 0.5, color: Colors.grey),
                          primary: colorPrimary,
                          backgroundColor: Colors.white,
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                          shadowColor: Colors.white
                        ),
                      ),
                      SizedBox(height: 5.0),
                      Text(
                        "Summary Absen",
                        style: TextStyle(
                          fontSize: 11.0
                        ),
                      )
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              Container(
                margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.25, left: MediaQuery.of(context).size.width * 0.25),
                // width: MediaQuery.of(context).size.width * 0.35,
                child: MaterialButton(
                  padding: EdgeInsets.all(2.0),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(3.0),
                        child: Text("Absen Sekarang", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                  onPressed: () {
                    if (!_disableButton) {
                      _submit("in", "-");
                    }
                  },
                  color: _disableButton ? Colors.grey : colorPrimary,
                  // disabledColor: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  contentBox(context){
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 20.0,top: 5.0
              + 20.0, right: 20.0,bottom: 20.0
          ),
          margin: EdgeInsets.only(top: 45.0),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(color: Colors.black,offset: Offset(0,10),
              blurRadius: 10
              ),
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("Isikan Alasan Ijin Anda", style: TextStyle(fontSize: 22,fontWeight: FontWeight.w600),),
              SizedBox(height: 15,),
              TextField(
                controller: _reasonController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Masukkan Alasan Anda...',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey
                  ),
                  fillColor: Colors.white, filled: true
                ),
              ),
              SizedBox(height: 22,),
              Align(
                alignment: Alignment.bottomRight,
                child: MaterialButton(
                    color: colorPrimary,
                    onPressed: () async {
                      await _submit("permit", _reasonController.text);
                    },
                    child: Text("Ijin Sekarang", style: TextStyle(fontSize: 15, color: Colors.white))
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  contentSummaryBox(context){
    DateTime now = DateTime.now();
    String formattedDate = monthIndo(int.parse(DateFormat('M').format(now)));

    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 20.0,top: 5.0
              + 20.0, right: 20.0,bottom: 20.0
          ),
          margin: EdgeInsets.only(top: 45.0),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(color: Colors.black,offset: Offset(0,10),
              blurRadius: 10
              ),
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("Summary Absen", style: TextStyle(fontSize: 22,fontWeight: FontWeight.w600),),
              SizedBox(height: 5,),
              Text("Periode $formattedDate", style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600),),
              SizedBox(height: 15,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text("$countPresent", style: TextStyle(fontSize: 45,fontWeight: FontWeight.w600, color: Colors.green)),
                      Text("Hadir", style: TextStyle(fontSize: 15))
                    ],
                  ),
                  Column(
                    children: [
                      Text("$countPermit", style: TextStyle(fontSize: 45,fontWeight: FontWeight.w600, color: Colors.orange)),
                      Text("Tidak Hadir", style: TextStyle(fontSize: 15))
                    ],
                  )
                ],
              ),
              SizedBox(height: 15,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text("$countPresentWeekend", style: TextStyle(fontSize: 45,fontWeight: FontWeight.w600, color: Colors.red)),
                      Text("Hadir\nWeekend", style: TextStyle(fontSize: 15), textAlign: TextAlign.center)
                    ],
                  ),
                  Column(
                    children: [
                      Text("$countPresentHoliday", style: TextStyle(fontSize: 45,fontWeight: FontWeight.w600, color: Colors.red)),
                      Text("Hadir\nLibur Nasional", style: TextStyle(fontSize: 15), textAlign: TextAlign.center)
                    ],
                  )
                ],
              ),
              SizedBox(height: 22,),
              Align(
                alignment: Alignment.bottomRight,
                child: MaterialButton(
                    color: colorPrimary,
                    onPressed: () async {
                      Navigator.of(context).pop();
                    },
                    child: Text("Tutup", style: TextStyle(fontSize: 15, color: Colors.white))
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget displaySelectedFile(File file) {
    return GestureDetector(
      onTap: _disableButton == true ? null : this._getImage,
      child: SizedBox(
        height: 230.0,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 35),
          decoration: BoxDecoration(
            color: colorTertiary.withOpacity(0.2),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(width: 3.0, color: HexColor("D8BFD8")),
          ),
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: file == null
                ? Image.asset(
                  "assets/images/person_6x8.png",
                  height: 100.0,
                )
                : Image.file(file, fit: BoxFit.fitHeight,),
            ),
          )
        )
      ),
    );
  }
}