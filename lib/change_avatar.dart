import 'dart:io';

import 'package:bpjt_k_gis_mobile_master/utils/utils.dart';
import 'package:bpjt_k_gis_mobile_master/helper/main_helper.dart' as helper;
import 'package:bpjt_k_gis_mobile_master/view/dashboard/dashboard_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import 'conn/API.dart';

class ChangeAvatarPage extends StatefulWidget {
  @override
  _ChangeAvatarPageState createState() => _ChangeAvatarPageState();
}

class _ChangeAvatarPageState extends State<ChangeAvatarPage> {
  bool _loading = false;
  
  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;

  var userDetail;

  String? appName;
  String? packageName;
  String? version;
  String? buildNumber;

  String? _imagePath;
  final ImagePicker picker = ImagePicker();
  
  _getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  _userDetail() async {
    await API.getUserByEmail(prefEmail, version!).then((response) {
      if (!mounted) return;
      helper.showUpdateAppsModal(context, response);
      setState(() {
        userDetail = response;
      });
    });
  }
  
  void _pickImage() async {
    PickedFile? file;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text("Pilih Foto/File"),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context); //close the dialog box
                file = await picker.getImage(source: ImageSource.gallery);
                setState(() {
                  _imagePath = file?.path;
                });
              },
              child: const Text('Gallery'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context); //close the dialog box
                file = await picker.getImage(source: ImageSource.camera);
                setState(() {
                  _imagePath = file?.path;
                });
              },
              child: const Text('Kamera'),
            ),
          ]
        );
      }
    );
  }
  
  _getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefId = prefs.getString('id');
      prefName = prefs.getString('name');
      prefCompany = prefs.getString('company');
      prefCompanyField = prefs.getString('company_field');
      prefPhone = prefs.getString('phone');
      prefEmail = prefs.getString('email');
      prefRoleId = prefs.getString('role_id');
      prefIsApprove = prefs.getBool('is_approve');
    });
  }

  _changeAvatars() async {
    setState(() {
      _loading = true;
    });

    Map<String, dynamic> params = Map<String, dynamic>();
    params["id"] = prefId;

    await API.storeAvatar(
      params,
      _imagePath ?? 'path kosong',
      version ?? 'versi kosong',
    ).then((response) {
      if (response["status"] == "success") {
        _showDialog(context, response["message"], "Sukses!");
      } else {
        _showDialog(context, response["message"], "Error!");
      }
    });
  }

  _showDialog(BuildContext context, String msg, String title) {
    setState(() {
      _loading = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: <Widget>[
          TextButton (
            child: Text("Ok"),
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => DashboardPage()));
              return;
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getInfo().then((resInfo) {
      _getPref().then((res) {
        _userDetail();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double widthSize = MediaQuery.of(context).size.width;
    double heightSize = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Foto Profil'),
        backgroundColor: colorPrimary,
      ),
      body: prefId == "" || prefId == null ? const Center(child: CircularProgressIndicator()) :
      ModalProgressHUD(
          inAsyncCall: _loading,
          child: Container(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: heightSize * 0.01,
                  ),
                  displaySelectedFile(_imagePath!),
                  SizedBox(
                    height: heightSize * 0.01,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0.8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),

                      padding: EdgeInsets.all(12),
                      backgroundColor: colorPrimary,
                    ),
                    onPressed: () {
                      _changeAvatars();
                    },
                    child: Text('SUBMIT', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(
                    height: heightSize * 0.05,
                  ),
                ],
              )
            )
          ),
        ),
    );
  }

  Widget displaySelectedFile(String filePath) {
    var file;

    if (userDetail != null && filePath == null) {
      if (userDetail["filepath"] != null && userDetail["filename"] != null) {
        file = NetworkImage("http://103.6.53.254:13480/bpjt-teknik/public"+userDetail["filepath"]+"/"+userDetail["filename"]);
      } else {
        userDetail = 'user detail kososng';
        filePath = 'file path kosong';
      }
    } else {
      if (filePath == null) {
        file = FileImage(File('/'));
      } else {
        file = FileImage(File(filePath));
      }
    }

    return GestureDetector(
      onTap: this._pickImage,
      child: Container(
          width: 200.0,
          height: 250.0,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover, 
              image: filePath == null && userDetail == null
                ? const AssetImage('assets/images/person_6x8.png')
                : file
            ),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(color: HexColor("D8BFD8")),
            color: Colors.redAccent,
          ),
        ),
    );
  }
}