import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bpjtteknik/conn/API.dart';
import 'package:bpjtteknik/helper/db_problems.dart';
import 'package:bpjtteknik/utils/utils.dart';
import 'package:bpjtteknik/view/tracking/problem_list_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:package_info/package_info.dart';
import 'package:search_choices/search_choices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetalert/sweetalert.dart';

class AddTrackingPage extends StatefulWidget {
  @override
  _AddTrackingPageState createState() => _AddTrackingPageState();
}

class _AddTrackingPageState extends State<AddTrackingPage> {
  bool _loading = false;

  String _selectedSegment;
  String _selectedPriorityStatus;
  String districtSubdistrict;
  String cityRegion;
  String _image;
  String appName;
  String packageName;
  String version;
  String buildNumber;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  var prefSegment;

  Position _position;
  
  List prefSegments = List();
  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];
  List _segments = List();

  TextEditingController _problemController = new TextEditingController();
  TextEditingController _locationController = new TextEditingController();
  TextEditingController _staController = new TextEditingController();
  
  DbProblems dbProblem = DbProblems();
  
  _getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }
  
  _getImage() async {
    if (_selectedSegment == null) {
      SweetAlert.show(
        context,
        title: "Error",
        subtitle: "Silahkan Pilih Ruas",
        style: SweetAlertStyle.error,
        onPress: (bool isConfirm) {
          return true;
        }
      );

      return;
    }

    if (_problemController.text == "") {
      SweetAlert.show(
        context,
        title: "Error",
        subtitle: "Laporan Harus Diisi",
        style: SweetAlertStyle.error,
        onPress: (bool isConfirm) {
          return true;
        }
      );

      return;
    }

    if (_locationController.text == "") {
      SweetAlert.show(
        context,
        title: "Error",
        subtitle: "Lokasi Harus Diisi",
        style: SweetAlertStyle.error,
        onPress: (bool isConfirm) {
          return true;
        }
      );

      return;
    }

    if (_staController.text == "") {
      SweetAlert.show(
        context,
        title: "Error",
        subtitle: "STA Harus Diisi",
        style: SweetAlertStyle.error,
        onPress: (bool isConfirm) {
          return true;
        }
      );

      return;
    }

    File image;
    String _path;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy – kk:mm').format(now);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text("Pilih Foto/File"),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context); //close the dialog box
                image = await ImagePicker.pickImage(
                    source: ImageSource.gallery);
                setState(() {
                  _image = image.path;
                  if (image.path != "") {
                    
                  }
                });
              },
              child: const Text('Gallery'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context); //close the dialog box
                image =
                    await ImagePicker.pickImage(source: ImageSource.camera);
                
                img.Image im = img.decodeImage(image.readAsBytesSync());

                img.Image convertImage = img.copyResize(im, width: 800);

                img.Image drawName = img.drawString(img.Image.from(convertImage), img.arial_24, 0, 0, prefName);
                img.Image drawDateTime = img.drawString(img.Image.from(drawName), img.arial_24, 0, 30, formattedDate);
                img.Image drawSegment = img.drawString(img.Image.from(drawDateTime), img.arial_24, 0, 60, _selectedSegment);
                img.Image drawLongLat = img.drawString(img.Image.from(drawSegment), img.arial_24, 0, 90, '${_position.latitude} ${_position.longitude}');
                img.Image drawDistrictSubdistrict = img.drawString(img.Image.from(drawLongLat), img.arial_24, 0, 120,districtSubdistrict);
                img.Image drawCityRegion = img.drawString(img.Image.from(drawDistrictSubdistrict), img.arial_24, 0, 150,cityRegion);
                img.Image drawSTA = img.drawString(img.Image.from(drawCityRegion), img.arial_24, 0, 180, _staController.text);
                img.Image drawAltitude = img.drawString(img.Image.from(drawSTA), img.arial_24, 0, 210, '${_position.altitude}');

                File(image.path).writeAsBytesSync(img.encodeNamedImage(drawAltitude, image.path));

                setState(() {
                  if (image != null) {
                    _image = image.path;
                  }
                  if (image.path != "") {

                  }
                });
              },
              child: const Text('Kamera'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                // _path = await FilePicker.getFilePath(
                //     type: FileType.custom, allowedExtensions: ["pdf"]);
                FilePickerResult pickfileResult = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );

                _path = pickfileResult.files.first.path;
                // _path
                setState(() {
                  _image = _path;
                  if (_path != "") {

                  }
                });
              },
              child: const Text('File'),
            ),
          ]
        );
      }
    );
  }
  
  _listSegment() async {
    await API.getSegment("", "", "", "true", version).then((response) {
      setState(() {
        _segments = response;
      });
    });
  }

  _submit() async {
    setState(() {
      _loading = true;
    });

    if (_selectedSegment == null) {
      setState(() {
        _loading = false;
      });

      SweetAlert.show(
        context,
        title: "Error",
        subtitle: "Silahkan Pilih Ruas",
        style: SweetAlertStyle.error,
        onPress: (bool isConfirm) {
          return true;
        }
      );

      return;
    }

    if (_problemController.text == "") {
      setState(() {
        _loading = false;
      });

      SweetAlert.show(
        context,
        title: "Error",
        subtitle: "Laporan Harus Diisi",
        style: SweetAlertStyle.error,
        onPress: (bool isConfirm) {
          return true;
        }
      );

      return;
    }

    if (_locationController.text == "") {
      setState(() {
        _loading = false;
      });

      SweetAlert.show(
        context,
        title: "Error",
        subtitle: "Lokasi Harus Diisi",
        style: SweetAlertStyle.error,
        onPress: (bool isConfirm) {
          return true;
        }
      );

      return;
    }

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);

    Map<String, dynamic> params = Map<String, dynamic>();
    params["user_id"] = prefId;
    params["problem"] = _problemController.text;
    params["long"] = _position.longitude.toString();
    params["lat"] = _position.latitude.toString();
    params["segment"] = _selectedSegment;
    params["priority"] = _selectedPriorityStatus;
    params["location"] = _locationController.text;
    params["files"] = _image;
    params["date"] = formattedDate;

    dbProblem.insert(params);

    SweetAlert.show(context,
      title: "Sukses",
      subtitle: "Sukses menambahkan permasalahan",
      style: SweetAlertStyle.success,
      onPress: (bool isConfirm) {
        if (isConfirm) {
          Navigator.of(context).pop();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => ProblemListPage()));
        }
        return;
      }
    );
  }

  Widget displaySelectedFile(String path) {
    String extension;
    String filename;

    if (path != null && path != "") {
      filename = path.split('/').last;
      extension = path.split('.').last;
    }
    
    return SizedBox(
      width: 300.0,
      height: 170.0,
      child: path == "/" || path == null
          ? Image.asset("assets/images/no_image.png",)
          : (extension == "pdf")
              ? Column(
                  children: <Widget>[
                    Image.asset(
                      "assets/images/pdf_placeholder.png",
                      height: 150.0,
                    ),
                    Text(filename, style: TextStyle(fontSize: 10.0))
                  ],
                )
              : Image.file(File(path)),
    );
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
    prefSegment = prefs.getString('segment');
    prefSegments = jsonDecode(prefs.getString('segments'));
  }
  
  @override
  void initState() {
    super.initState();
    if (!mounted) return;
    _getInfo().then((resInfo) {
      _getPref().then((response) {
        _checkPermission();
        _getCurrentPosition();
        _addLocationStream();
        _listSegment().then((resSegment){
          if (prefCompanyField == "PMI") {
            setState(() {
              _segments.clear();
              _segments = prefSegments;          
            });
          }
        });
      });
    });
  }

   _getCurrentPosition() async {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      setState(() {
        _position = position;
        _locationController = new TextEditingController(text: '${placemarks.first.subLocality}, ${placemarks.first.locality}, ${placemarks.first.subAdministrativeArea}, ${placemarks.first.administrativeArea}');
        districtSubdistrict = "${placemarks.first.subLocality}, ${placemarks.first.locality}";
        cityRegion = "${placemarks.first.subAdministrativeArea}, ${placemarks.first.administrativeArea}";
      });
  }

  _addLocationStream() {
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.high, distanceFilter: 10)
        .listen((Position position) {

      setState(() {
        _position = position;
      });
      // _sendLocationData();
    });
    _streamSubscriptions.add(positionStream);
  }

  _checkPermission() async {
    await Geolocator.checkPermission();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lapor Tracking'),
        backgroundColor: colorPrimary,
      ),
      body: ModalProgressHUD(
        child: Container(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
              ),
              _buildTextFields(context),
              Padding(
                padding: const EdgeInsets.all(10.0),
              ),
              _buildButtons(),
              Padding(
                padding: const EdgeInsets.all(10.0),
              ),
            ],
          ),
        ),
        inAsyncCall: _loading,
      )
    );
  }

  Widget _buildTextFields(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text("Ruas")
            ),
            Container(
              child: ListTile(
                title: SearchChoices.single(
                  items: _segments.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(item, style: TextStyle(fontSize: 12.0, color: Colors.black),)
                      )
                    );
                  }).toList(),
                  selectedValueWidgetFn: (item) {
                    return Container(
                      transform: Matrix4.translationValues(-10,0,0),
                      alignment: Alignment.centerLeft,
                      child: Text(item, style: TextStyle(fontSize: 12.0, color: Colors.black),)
                    );
                  },
                  hint: Container(
                    transform: Matrix4.translationValues(-10,0,0),
                    child: Text("Pilih Ruas", style: TextStyle(color: Colors.black),)
                  ),
                  searchHint: "Pilih Ruas",
                  onChanged: (value) {
                    setState(() {
                      if (value == null) {
                        _selectedSegment = null;
                      } else {
                        _selectedSegment = value;
                      }
                    });
                  },
                  value: _selectedSegment,
                  isExpanded: true,
                  displayClearIcon: false,
                  underline: Container(color:Colors.black, height:0.5),
                  icon: Container(
                    transform: Matrix4.translationValues(10,0,0),
                    child: Icon(Icons.arrow_drop_down)
                  ),
                ),
              )
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text("Lokasi")
        ),
        Container(
          child: ListTile(
            title: TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: "Lokasi",
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text("STA")
        ),
        Container(
          child: ListTile(
            title: TextField(
              controller: _staController,
              decoration: InputDecoration(
                hintText: "STA",
              ),
              minLines: 1
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text("Laporan")
        ),
        Container(
          child: ListTile(
            title: TextField(
              controller: _problemController,
              decoration: InputDecoration(
                hintText: "Isi Laporan...",
              ),
              maxLines: 4,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text("Prioritas")
        ),
        Container(
          child: ListTile(
            title: DropdownButton(
              selectedItemBuilder: (BuildContext context) {
                return <String>['Low', 'Medium', 'High'].map<Widget>((String item) {
                  return Text(item, style: TextStyle(color: Colors.black),);
                }).toList();
              },
              isExpanded: true,
              hint: Row(
                children: <Widget>[
                  Text('Pilih Prioritas', style: TextStyle(color: Colors.black),),
                ],
              ),
              items: <String>[
                'Low', 'Medium', 'High'
              ].map((String item) {
                return DropdownMenuItem(
                  value: item.toString(),
                  child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(item, style: TextStyle(fontSize: 13.0, color: Colors.black),)
                  )
                );
              }).toList(),
              onChanged: (newVal) {
                setState(() {
                  _selectedPriorityStatus = newVal;
                });
              },
              value: _selectedPriorityStatus,
              underline: Container(color:Colors.black, height:0.5),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
          child: Text("File Laporan")
        ),
        Container(
          child: GestureDetector(
            onTap: () {
              _getImage();
            },
            child: Center(
              child: displaySelectedFile(_image),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
              child: RaisedButton(
                elevation: 0.8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                onPressed: () {
                  _submit();
                },
                padding: EdgeInsets.all(12),
                color: colorPrimary,
                child: Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
          ),
        ],
      ),
    );
  }
}