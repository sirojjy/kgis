import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bpjt_k_gis_mobile_master/conn/API.dart';
import 'package:bpjt_k_gis_mobile_master/helper/db_problems.dart';
import 'package:bpjt_k_gis_mobile_master/utils/utils.dart';
import 'package:bpjt_k_gis_mobile_master/view/tracking/problem_list_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:search_choices/search_choices.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'package:package_info/package_info.dart';
// import 'package:sweetalert/sweetalert.dart';

class AddTrackingPage extends StatefulWidget {
  @override
  _AddTrackingPageState createState() => _AddTrackingPageState();
}

class _AddTrackingPageState extends State<AddTrackingPage> {
  bool _loading = false;

  String? _selectedSegment;
  String? _selectedPriorityStatus;
  late String districtSubdistrict;
  late String cityRegion;
  late String _image;
  late String appName;
  late String packageName;
  late String version;
  late String buildNumber;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  var prefSegment;

  late Position _position;
  
  List prefSegments = [];
  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];
  List _segments = [];

  TextEditingController _problemController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _staController = TextEditingController();
  
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
      Alert(
        context: context,
        type: AlertType.error,
        title: "Error",
        desc:"Silahkan Pilih Ruas",
        buttons: [
          DialogButton(child: const Text("OK"), onPressed: () {return;},)
        ]
      ).show();
      return;
      // SweetAlert.show(
      //   context,
      //   title: "Error",
      //   subtitle: "Silahkan Pilih Ruas",
      //   style: SweetAlertStyle.error,
      //   onPress: (bool isConfirm) {
      //     return true;
      //   }
      // );
    }

    if (_problemController.text == "") {
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc:"Laporan Harus Diisi",
          buttons: [
            DialogButton(child: const Text("OK"), onPressed: () {return;},)
          ]
      ).show();
      return;
      // SweetAlert.show(
      //   context,
      //   title: "Error",
      //   subtitle: "Laporan Harus Diisi",
      //   style: SweetAlertStyle.error,
      //   onPress: (bool isConfirm) {
      //     return true;
      //   }
      // );
      // return;
    }

    if (_locationController.text == "") {
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc:"Lokasi Harus Diisi",
          buttons: [
            DialogButton(child: const Text("OK"), onPressed: () {return;},)
          ]
      ).show();
      return;
      // SweetAlert.show(
      //   context,
      //   title: "Error",
      //   subtitle: "Lokasi Harus Diisi",
      //   style: SweetAlertStyle.error,
      //   onPress: (bool isConfirm) {
      //     return true;
      //   }
      // );
      //
      // return;
    }

    if (_staController.text == "") {
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc:"STA Harus Diisi",
          buttons: [
            DialogButton(child: const Text("OK"), onPressed: () {return;},)
          ]
      ).show();
      return;
      // SweetAlert.show(
      //   context,
      //   title: "Error",
      //   subtitle: "STA Harus Diisi",
      //   style: SweetAlertStyle.error,
      //   onPress: (bool isConfirm) {
      //     return true;
      //   }
      // );
      //
      // return;
    }

    File image;
    String? _path;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy – kk:mm').format(now);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text("Pilih Foto/File"),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context); //close the dialog box
                final picker = ImagePicker();
                XFile? image = await picker.pickImage(source: ImageSource.gallery);
                setState(() {
                  _image = image!.path;
                  if (image.path != "") {
                  }
                });
              },
              child: const Text('Gallery'),
            ),
            /// before
            // SimpleDialogOption(
            //   onPressed: () async {
            //     Navigator.pop(context); //close the dialog box
            //     image = await ImagePicker.pickImage(
            //         source: ImageSource.gallery);
            //     setState(() {
            //       _image = image.path;
            //       if (image.path != "") {
            //       }
            //     });
            //   },
            //   child: const Text('Gallery'),
            // ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context); //close the dialog box
                final picker = ImagePicker();
                XFile? image = await picker.pickImage(source: ImageSource.camera);

                if (image != null) {
                  Uint8List? imageBytes = await image.readAsBytes();
                  img.Image? im = img.decodeImage(imageBytes);

                  img.Image convertImage = img.copyResize(im!, width: 800);

                  img.Image drawName = img.drawString(img.Image.from(convertImage), font: img.arial24, prefName);
                  img.Image drawDateTime = img.drawString(img.Image.from(drawName), font: img.arial24, formattedDate);
                  img.Image drawSegment = img.drawString(img.Image.from(drawDateTime), font: img.arial24, _selectedSegment!);
                  img.Image drawLongLat = img.drawString(img.Image.from(drawSegment), font: img.arial24, '${_position.latitude} ${_position.longitude}');
                  img.Image drawDistrictSubdistrict = img.drawString(img.Image.from(drawLongLat), font: img.arial24, districtSubdistrict);
                  img.Image drawCityRegion = img.drawString(img.Image.from(drawDistrictSubdistrict), font: img.arial24,cityRegion);
                  img.Image drawSTA = img.drawString(img.Image.from(drawCityRegion), font: img.arial24, _staController.text);
                  img.Image drawAltitude = img.drawString(img.Image.from(drawSTA), font: img.arial24, '${_position.altitude}');

                  List<int> encodedImage = img.encodePng(drawAltitude);
                  File(image.path).writeAsBytesSync(encodedImage);

                  setState(() {
                    if (image != null) {
                      _image = image.path;
                    }
                    if (image.path != "") {

                    }
                  });
                }
              },
              child: const Text('Kamera'),
            ),
            ///sebelumnya
            // SimpleDialogOption(
            //   onPressed: () async {
            //     Navigator.pop(context); //close the dialog box
            //
            //     image = await ImagePicker.pickImage(source: ImageSource.camera);
            //
            //     img.Image im = img.decodeImage(image.readAsBytesSync());
            //
            //     img.Image convertImage = img.copyResize(im, width: 800);
            //
            //     img.Image drawName = img.drawString(img.Image.from(convertImage), img.arial_24, 0, 0, prefName);
            //     img.Image drawDateTime = img.drawString(img.Image.from(drawName), img.arial_24, 0, 30, formattedDate);
            //     img.Image drawSegment = img.drawString(img.Image.from(drawDateTime), img.arial_24, 0, 60, _selectedSegment);
            //     img.Image drawLongLat = img.drawString(img.Image.from(drawSegment), img.arial_24, 0, 90, '${_position.latitude} ${_position.longitude}');
            //     img.Image drawDistrictSubdistrict = img.drawString(img.Image.from(drawLongLat), img.arial_24, 0, 120,districtSubdistrict);
            //     img.Image drawCityRegion = img.drawString(img.Image.from(drawDistrictSubdistrict), img.arial_24, 0, 150,cityRegion);
            //     img.Image drawSTA = img.drawString(img.Image.from(drawCityRegion), img.arial_24, 0, 180, _staController.text);
            //     img.Image drawAltitude = img.drawString(img.Image.from(drawSTA), img.arial_24, 0, 210, '${_position.altitude}');
            //
            //     File(image.path).writeAsBytesSync(img.encodeNamedImage(drawAltitude, image.path));
            //
            //     setState(() {
            //       if (image != null) {
            //         _image = image.path;
            //       }
            //       if (image.path != "") {
            //
            //       }
            //     });
            //   },
            //   child: const Text('Kamera'),
            // ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                // _path = await FilePicker.getFilePath(
                //     type: FileType.custom, allowedExtensions: ["pdf"]);
                FilePickerResult? pickfileResult = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );

                _path = pickfileResult?.files.first.path;
                // _path
                setState(() {
                  _image = _path!;
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

      Alert(
        context: context,
        type: AlertType.error,
        title: "Error",
        desc: "Silahkan Pilih Ruas",
          buttons: [ DialogButton(
            child: const Text("Ok"),
            onPressed: () { return; },
          ),]
      ).show();
      return;

      // SweetAlert.show(
      //   context,
      //   title: "Error",
      //   subtitle: "Silahkan Pilih Ruas",
      //   style: SweetAlertStyle.error,
      //   onPress: (bool isConfirm) {
      //     return true;
      //   }
      // );
      // return;
    }

    if (_problemController.text == "") {
      setState(() {
        _loading = false;
      });
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: "Laporan Harus Diisi",
          buttons: [ DialogButton(
            child: const Text("Ok"),
            onPressed: () { return; },
          ),]
      ).show();
      return;

      // SweetAlert.show(
      //   context,
      //   title: "Error",
      //   subtitle: "Laporan Harus Diisi",
      //   style: SweetAlertStyle.error,
      //   onPress: (bool isConfirm) {
      //     return true;
      //   }
      // );
      //
      // return;
    }

    if (_locationController.text == "") {
      setState(() {
        _loading = false;
      });
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: "Lokasi Harus Diisi",
          buttons: [ DialogButton(
            child: const Text("Ok"),
            onPressed: () { return; },
          ),]
      ).show();
      return;

      // SweetAlert.show(
      //   context,
      //   title: "Error",
      //   subtitle: "Lokasi Harus Diisi",
      //   style: SweetAlertStyle.error,
      //   onPress: (bool isConfirm) {
      //     return true;
      //   }
      // );
      //
      // return;
    }

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);

    Map<String, dynamic> params = <String, dynamic>{};
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
    Alert(
        context: context,
        type: AlertType.error,
        title: "Error",
        desc: "Lokasi Harus Diisi",
        buttons: [ DialogButton(
          child: const Text("Ok"),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => ProblemListPage()));
          },
        ),]
    ).show();
    return;

    // SweetAlert.show(context,
    //   title: "Sukses",
    //   subtitle: "Sukses menambahkan permasalahan",
    //   style: SweetAlertStyle.success,
    //   onPress: (bool isConfirm) {
    //     if (isConfirm) {
    //       Navigator.of(context).pop();
    //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => ProblemListPage()));
    //     }
    //     return;
    //   }
    // );
  }

  Widget displaySelectedFile(String path) {
    String? extension;
    String? filename;

    if (path != "") {
      filename = path.split('/').last;
      extension = path.split('.').last;
    }
    
    return SizedBox(
      width: 300.0,
      height: 170.0,
      child: path == "/"
          ? Image.asset("assets/images/no_image.png",)
          : (extension == "pdf")
              ? Column(
                  children: <Widget>[
                    Image.asset(
                      "assets/images/pdf_placeholder.png",
                      height: 150.0,
                    ),
                    Text(filename!, style: const TextStyle(fontSize: 10.0))
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
    prefSegments = jsonDecode(prefs.getString('segments')!);
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
        _locationController = TextEditingController(text: '${placemarks.first.subLocality}, ${placemarks.first.locality}, ${placemarks.first.subAdministrativeArea}, ${placemarks.first.administrativeArea}');
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
        title: const Text('Lapor Tracking'),
        backgroundColor: colorPrimary,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(10.0),
            ),
            _buildTextFields(context),
            const Padding(
              padding: EdgeInsets.all(10.0),
            ),
            _buildButtons(),
            const Padding(
              padding: EdgeInsets.all(10.0),
            ),
          ],
        ),
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
              child: const Text("Ruas")
            ),
            ListTile(
              title: SearchChoices.single(
                items: _segments.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(item, style: const TextStyle(fontSize: 12.0, color: Colors.black),)
                    )
                  );
                }).toList(),
                selectedValueWidgetFn: (item) {
                  return Container(
                    transform: Matrix4.translationValues(-10,0,0),
                    alignment: Alignment.centerLeft,
                    child: Text(item, style: const TextStyle(fontSize: 12.0, color: Colors.black),)
                  );
                },
                hint: Container(
                  transform: Matrix4.translationValues(-10,0,0),
                  child: const Text("Pilih Ruas", style: TextStyle(color: Colors.black),)
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
                  child: const Icon(Icons.arrow_drop_down)
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0),
          child: const Text("Lokasi")
        ),
        ListTile(
          title: TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              hintText: "Lokasi",
            ),
            minLines: 2,
            maxLines: 4,
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0),
          child: const Text("STA")
        ),
        ListTile(
          title: TextField(
            controller: _staController,
            decoration: const InputDecoration(
              hintText: "STA",
            ),
            minLines: 1
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0),
          child: const Text("Laporan")
        ),
        ListTile(
          title: TextField(
            controller: _problemController,
            decoration: const InputDecoration(
              hintText: "Isi Laporan...",
            ),
            maxLines: 4,
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0),
          child: const Text("Prioritas")
        ),
        ListTile(
          title: DropdownButton(
            selectedItemBuilder: (BuildContext context) {
              return <String>['Low', 'Medium', 'High'].map<Widget>((String item) {
                return Text(item, style: const TextStyle(color: Colors.black),);
              }).toList();
            },
            isExpanded: true,
            hint: const Row(
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
                    child: Text(item, style: const TextStyle(fontSize: 13.0, color: Colors.black),)
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
        Container(
          padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
          child: const Text("File Laporan")
        ),
        GestureDetector(
          onTap: () {
            _getImage();
          },
          child: Center(
            child: displaySelectedFile(_image),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0.8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(12),
                backgroundColor: colorPrimary,
              ),
              onPressed: () {
                _submit();
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
        ),
      ],
    );
  }
}