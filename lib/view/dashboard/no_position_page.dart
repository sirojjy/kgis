import 'dart:convert';
import 'package:bpjt_k_gis_mobile_master/conn/API.dart';
import 'package:bpjt_k_gis_mobile_master/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sweetalert/sweetalert.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'package:package_info/package_info.dart';

class NoPositionPage extends StatefulWidget {
  @override
  _NoPositionPageState createState() => _NoPositionPageState();
}

class _NoPositionPageState extends State<NoPositionPage> {
  bool _loading = false;

  String? _selectedCompanyField;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  List prefSegments = [];
  var prefMapType;
  var prefPosition;

  late String appName;
  late String packageName;
  late String version;
  late String buildNumber;

  List _positions = [];

  _getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
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
    prefSegments = jsonDecode(prefs.getString('segments')!);
    prefMapType = prefs.getString('map_type');
    prefPosition = prefs.getString('position');
  }

  void _submit() async {
    setState(() {
      _loading = true;
    });

    Map<String, dynamic> params = Map<String, dynamic>();
    params["id"] = prefId;
    params["position"] = _selectedCompanyField;

    await API.editUsers(
      params,
      version
    ).then((response) async {
      if (response["status"] == "success") {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('position', _selectedCompanyField!);
        Alert(
          context: context,
          type: AlertType.success,
          title: "Sukses",
          desc: response["message"],
          buttons: [
            DialogButton(child: const Text("OK "), onPressed: () {return;})
          ]
        ).show();
        // SweetAlert.show(context,
        //   title: "Sukses",
        //   subtitle: response["message"],
        //   style: SweetAlertStyle.success,
        //   onPress: (bool isConfirm) {
        //     if (isConfirm) {
        //       Phoenix.rebirth(context);
        //     }
        //     return;
        //   }
        // );
      } else {
        Alert(
            context: context,
            type: AlertType.error,
            title: "Error",
            desc: response["message"],
            buttons: [
              DialogButton(child: const Text("OK "), onPressed: () {return;})
            ]
        ).show();
        // SweetAlert.show(context,
        //   title: "Error",
        //   subtitle: response["message"],
        //   style: SweetAlertStyle.error,
        //   onPress: (bool isConfirm) {
        //     if (isConfirm) {
        //       Navigator.of(context).pop(true);
        //     }
        //     return;
        //   }
        // );
      }
    });
  }

  _getPositions() async {
    await API.getPosition(version).then((response) {
      if (!mounted) return;
      setState(() {
        _positions = response;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _getInfo().then((resInfo) {
      _getPositions();
      _getPref().then((response) {
        
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Data Anda'),
        backgroundColor: colorPrimary,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading, 
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0),
              padding: const EdgeInsets.only(left: 0.0, right: 10.0),
              child: ListTile(
                title: DropdownButton(
                  selectedItemBuilder: (BuildContext context) {
                    return _positions.map<Widget>((item) {
                      return Text(item['position'], style: const TextStyle(color: Colors.black),);
                    }).toList();
                  },
                  isExpanded: true,
                  hint: const Row(
                    children: <Widget>[
                      Text('Pilih Jabatan', style: TextStyle(color: Colors.black),),
                    ],
                  ),
                  items: _positions.map((item) {
                    return DropdownMenuItem(
                      value: item['position'].toString(),
                      child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(item['position'], style: const TextStyle(fontSize: 13.0, color: Colors.black),)
                      )
                    );
                  }).toList(),
                  onChanged: (newVal) {
                    setState(() {
                      _selectedCompanyField = newVal;
                    });
                  },
                  value: _selectedCompanyField,
                  underline: Container(color:Colors.black, height:0.5),
                ),
              ),
            ),
            Container(
              // width: MediaQuery.of(context).size.width * 0.8,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0.8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: const EdgeInsets.all(12),
                  backgroundColor: colorPrimary,
                ),
                onPressed: () {
                  _submit();
                },
                child: const Text('SUBMIT', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        )
      )
    );
  }
}