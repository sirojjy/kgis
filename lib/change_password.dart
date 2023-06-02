import 'package:bpjtteknik/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'conn/API.dart';
import 'main.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  bool _loading = false;
  bool _isHidePassword = true;
  bool _isHidePassword2 = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isHidePassword = !_isHidePassword;
    });
  }

  void _togglePasswordVisibility2() {
    setState(() {
      _isHidePassword2 = !_isHidePassword2;
    });
  }
  
  String prefId;

  TextEditingController oldPassword = TextEditingController();
  TextEditingController newPassword = TextEditingController();

  String appName;
  String packageName;
  String version;
  String buildNumber;

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
    setState(() {
      prefId = prefs.getString('id');
    });
  }

  _changePasswords() async {
    setState(() {
      _loading = true;
    });

    await API.changePasswords(
      prefId,
      oldPassword.text,
      newPassword.text,
      version
    ).then((response) {
      if (response["status"] == "success") {
        _showDialog(context, response["message"], "Sukses!", true);
      } else {
        _showDialog(context, response["message"], "Error!", false);
      }
    });
  }

  _showDialog(BuildContext context, String msg, String title, bool isPageChange) {
    setState(() {
      _loading = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: <Widget>[
          FlatButton(
            child: Text("Ok"),
            onPressed: () async {
              if (!isPageChange) {
                return Navigator.pop(context);
              }
              
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.clear();

              Navigator.pop(context);

              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => CollectionApp(null, null, null)), (Route<dynamic> route) => false);
              
              // return;
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
        title: Text('Ubah Password'),
        backgroundColor: colorPrimary,
      ),
      body: prefId == "" || prefId == null ? Center(child: CircularProgressIndicator()) :
        ModalProgressHUD(
          child: Container(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: heightSize * 0.01,
                  ),
                  Container(
                    width: widthSize * 0.9,
                    child: Text("Password Lama")
                  ),
                  Container(
                    width: widthSize * 0.9,
                    child: TextFormField(
                      controller: oldPassword,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            _togglePasswordVisibility();
                          },
                          child: Icon(
                            _isHidePassword ? Icons.visibility_off : Icons.visibility,
                            color: _isHidePassword ? Colors.grey : Colors.blue,
                          ),
                        ),
                      ),
                      obscureText: _isHidePassword,
                    ),
                  ),
                  SizedBox(
                    height: heightSize * 0.01,
                  ),
                  Container(
                    width: widthSize * 0.9,
                    child: Text("Password Baru")
                  ),
                  Container(
                    width: widthSize * 0.9,
                    child: TextFormField(
                      controller: newPassword,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            _togglePasswordVisibility2();
                          },
                          child: Icon(
                            _isHidePassword2 ? Icons.visibility_off : Icons.visibility,
                            color: _isHidePassword2 ? Colors.grey : Colors.blue,
                          ),
                        ),
                      ),
                      obscureText: _isHidePassword2,
                    ),
                  ),
                  SizedBox(
                    height: heightSize * 0.01,
                  ),
                  Container(
                      child: RaisedButton(
                        elevation: 0.8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        onPressed: () {
                          _changePasswords();
                        },
                        padding: EdgeInsets.all(12),
                        color: colorPrimary,
                        child: Text('SUBMIT', style: TextStyle(color: Colors.white)),
                      ),
                  ),
                  SizedBox(
                    height: heightSize * 0.05,
                  ),
                ],
              )
            )
          ),
          inAsyncCall: _loading,
        ),
    );
  }
}