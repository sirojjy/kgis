import 'dart:convert';

import 'package:art_sweetalert/art_sweetalert.dart';
import 'package:bpjt_k_gis_mobile_master/conn/API.dart';
import 'package:bpjt_k_gis_mobile_master/utils/utils.dart';
import 'package:bpjt_k_gis_mobile_master/view/dashboard/dashboard_admin_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/dashboard/dashboard_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:search_choices/search_choices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'package:package_info/package_info.dart';
// import 'package:searchable_dropdown/searchable_dropdown.dart';
// import 'package:sweetalert/sweetalert.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late String appName;
  late String packageName;
  late String version;
  late String buildNumber;
  late String fcmToken;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  _getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  bool _loading = false;

  TextEditingController user = TextEditingController();
  TextEditingController pass = TextEditingController();

  final TextEditingController _regName = TextEditingController();
  final TextEditingController _regCompanyName = TextEditingController();
  final TextEditingController _regEmail = TextEditingController();
  final TextEditingController _regPhone = TextEditingController();
  final TextEditingController _regPassword = TextEditingController();
  final TextEditingController _regConfirmPass = TextEditingController();

  final TextEditingController _forgotEmail = TextEditingController();

  List _segments = [];

  String? _selectedCompanyField;

  int countPackage = 0;
  final List<String?> _selectedSegments = [];

  _listSegment() async {
    await API.getSegment("", "", "", "true", version).then((response) {
      setState(() {
        _segments = response;
      });
    });
  }

  void _login() async {
    var updateUrl = await canLaunchUrl(Uri.parse("https://bit.ly/UpdateKGIS"));

    setState(() {
      _loading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    _firebaseMessaging.getToken().then((String? token) async {
      // assert(token != null);
      await API
          .authorize(user.text, pass.text, token!, false, version
              //TODO pass fcmToken and update to users
              //TODO update should_logout false
              )
          .then((response) async {
        setState(() {
          _loading = false;
        });

        if (response["status"] == "success") {
          prefs.setString('id', "${response['user']['id']}");
          prefs.setString('name', response['user']['name']);
          prefs.setString('company', response['user']['company']);
          prefs.setString('company_field', response['user']['company_field']);
          prefs.setString('phone', response['user']['phone']);
          prefs.setString('email', response['user']['email']);
          prefs.setString('segment', response['user']['segment']);
          prefs.setString('role_id', "${response['user']['role_id']}");
          prefs.setString('segments', jsonEncode(response['user']['segments']));
          prefs.setBool('is_approve', response['user']['is_approve']);
          prefs.setString('position', response['user']['position']);

          Alert(
            context: context,
            type: AlertType.success,
            title: "Sukses",
            desc: response["message"],
            buttons: [
              DialogButton(
                child: const Text('OK'),
                onPressed: () {
                  if (response['user']['role_id'] < 1) {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => DashboardPage()),
                        (Route<dynamic> route) => false);
                  } else {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => DashboardAdminPage()),
                        (Route<dynamic> route) => false);
                  }
                  return;
                },
              ),
            ],
          ).show();

        } else {
          Alert(
            context: context,
            type: AlertType.error,
            title: "Error",
            desc: "message",
            buttons: [
              DialogButton(
                child: const Text('OK'),
                onPressed: () {
                  if (response["data"] != null && response["url"] != null) {
                    if (updateUrl) {
                      launchUrl(Uri.parse("https://bit.ly/UpdateKGIS"));
                    } else {
                      throw 'Could not launch url';
                    }
                  }
                },
              ),
            ],
          ).show();
          // ArtSweetAlert.show(
          //     context: context,
          //     artDialogArgs: ArtDialogArgs(
          //         type: ArtSweetAlertType.success,
          //         title: "Sukses",
          //         text: "message"),
          //     onPress: (bool isConfirm) {
          //       if (isConfirm) {
          //         if (response['user']['role_id'] < 1) {
          //           Navigator.of(context).pushAndRemoveUntil(
          //               MaterialPageRoute(
          //                   builder: (context) => DashboardPage()),
          //               (Route<dynamic> route) => false);
          //         } else {
          //           Navigator.of(context).pushAndRemoveUntil(
          //               MaterialPageRoute(
          //                   builder: (context) => DashboardAdminPage()),
          //               (Route<dynamic> route) => false);
          //         }
          //       }
          //       return;
          //     });
          // title: "Sukses",
          // subtitle: response["message"],
          // style: SweetAlertStyle.success,

          //else

          // ArtSweetAlert response = await ArtSweetAlert.show(
          //     context: context,
          //     artDialogArgs: ArtDialogArgs(
          //         type: ArtSweetAlertType.danger,
          //         title: "Error",
          //         text: "message"),
          //
          //     // title: "Error",
          //     // subtitle: response["message"],
          //     // style: SweetAlertStyle.error,
          //     onPress: (bool isConfirm) {
          //       if (response["data"] != null && response["url"] != null) {
          //         if (updateUrl) {
          //           launch("https://bit.ly/UpdateKGIS");
          //         } else {
          //           throw 'Could not launch url';
          //         }
          //       }
          //       return true;
          //     });
        }
      });
    });
  }

  _forgotPassword() async {
    setState(() {
      _loading = true;
    });
    if (_forgotEmail.text == "") {
      Alert(
        context: context,
        type: AlertType.error,
        title: "Error",
        desc: "Harap isikan email",
        buttons: [
          DialogButton(
            child: const Text("OK"),
            onPressed: () {
              return;
            },
          )
        ]
      ).show();
      // SweetAlert.show(context,
      //     title: "Error",
      //     subtitle: "Harap isikan email",
      //     style: SweetAlertStyle.error, onPress: (bool isConfirm) {
      //   return true;
      // });
    }

    await API.forgotPassword(_forgotEmail.text, version).then((response) {
      setState(() {
        _loading = false;
      });
      if (response["status"] == "success") {
        Alert(
            context: context,
            type: AlertType.success,
            title: "Sukses",
            desc: response["message"],
            buttons: [
              DialogButton(
                child: const Text("OK"),
                onPressed: () {
                  gotoLogin();
                },
              )
            ]
        ).show();
        // SweetAlert.show(context,
        //     title: "Sukses",
        //     subtitle: response["message"],
        //     style: SweetAlertStyle.success, onPress: (bool isConfirm) {
        //   if (isConfirm) {
        //     gotoLogin();
        //   }
        //   return;
        // });
      } else {
        Alert(
            context: context,
            type: AlertType.error,
            title: "Error",
            desc: response["message"],
            buttons: [
              DialogButton(
                child: const Text("OK"),
                onPressed: () {
                  return;
                },
              )
            ]
        ).show();
        // SweetAlert.show(context,
        //     title: "Error",
        //     subtitle: response["message"],
        //     style: SweetAlertStyle.error, onPress: (bool isConfirm) {
        //   return true;
        // });
      }
    });
  }

  void _signup() async {
    setState(() {
      _loading = true;
    });

    if (_regPassword.text != _regConfirmPass.text) {
      setState(() {
        _loading = false;
      });
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: "Password dan Konfirmasi Password Tidak Cocok",
          buttons: [
            DialogButton(
              child: const Text("OK"),
              onPressed: () {
                return;
              },
            )
          ]
      ).show();
      return;
      // SweetAlert.show(context,
      //     title: "Error",
      //     subtitle: "Password dan Konfirmasi Password Tidak Cocok",
      //     style: SweetAlertStyle.error, onPress: (bool isConfirm) {
      //   return true;
      // });
    }

    if (_regName.text == "") {
      setState(() {
        _loading = false;
      });
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: "Nama Harus Diisi",
          buttons: [
            DialogButton(
              child: const Text("OK"),
              onPressed: () {
                return;
              },
            )
          ]
      ).show();
      return;
      // SweetAlert.show(context,
      //     title: "Error",
      //     subtitle: "Nama Harus Diisi",
      //     style: SweetAlertStyle.error, onPress: (bool isConfirm) {
      //   return true;
      // });
    }

    if (_selectedCompanyField == null) {
      setState(() {
        _loading = false;
      });
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: "Harus Pilih Instansi",
          buttons: [
            DialogButton(
              child: const Text("OK"),
              onPressed: () {
                return;
              },
            )
          ]
      ).show();
      return;
      // SweetAlert.show(context,
      //     title: "Error",
      //     subtitle: "Harus Pilih Instansi",
      //     style: SweetAlertStyle.error, onPress: (bool isConfirm) {
      //   return true;
      // });
    }

    if (_regPhone.text == "") {
      setState(() {
        _loading = false;
      });
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: "No. HP Harus Diisi",
          buttons: [
            DialogButton(
              child: const Text("OK"),
              onPressed: () {
                return;
              },
            )
          ]
      ).show();
      return;
      // SweetAlert.show(context,
      //     title: "Error",
      //     subtitle: "No. HP Harus Diisi",
      //     style: SweetAlertStyle.error, onPress: (bool isConfirm) {
      //   return true;
      // });
      // return;
    }

    if (_regEmail.text == "") {
      setState(() {
        _loading = false;
      });
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: "Email Harus Diisi",
          buttons: [
            DialogButton(
              child: const Text("OK"),
              onPressed: () {
                return;
              },
            )
          ]
      ).show();
      return;
      //
      // SweetAlert.show(context,
      //     title: "Error",
      //     subtitle: "Email Harus Diisi",
      //     style: SweetAlertStyle.error, onPress: (bool isConfirm) {
      //   return true;
      // });
      //
      // return;
    }

    if (_regPassword.text == "" || _regConfirmPass.text == "") {
      setState(() {
        _loading = false;
      });
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: "Password Harus Diisi",
          buttons: [
            DialogButton(
              child: const Text("OK"),
              onPressed: () {
                return;
              },
            )
          ]
      ).show();
      return;
      // SweetAlert.show(context,
      //     title: "Error",
      //     subtitle: "Password Harus Diisi",
      //     style: SweetAlertStyle.error, onPress: (bool isConfirm) {
      //   return true;
      // });
      //
      // return;
    }

    if (_selectedCompanyField == "PMI" &&
        (_selectedSegments.length == 1 && _selectedSegments[0] == null)) {
      setState(() {
        _loading = false;
      });
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: "Ruas Harus Diisi Minimal 1",
          buttons: [
            DialogButton(
              child: const Text("OK"),
              onPressed: () {
                return;
              },
            )
          ]
      ).show();
      return;
      // SweetAlert.show(context,
      //     title: "Error",
      //     subtitle: "Ruas Harus Diisi Minimal 1",
      //     style: SweetAlertStyle.error, onPress: (bool isConfirm) {
      //   return true;
      // });
      //
      // return;
    }

    Map<String, dynamic> params = <String, dynamic>{};
    params["name"] = _regName.text;
    params["company"] = _regCompanyName.text;
    params["company_field"] = _selectedCompanyField;
    params["phone"] = _regPhone.text;
    params["email"] = _regEmail.text;
    params["segments"] = _selectedSegments;
    params["password"] = _regPassword.text;

    await API.users(params, version).then((response) {
      setState(() {
        _loading = false;
      });


      if (response["status"] == "success") {
        Alert(
            context: context,
            type: AlertType.success,
            title: "Sukses",
            desc: response["message"],
            buttons: [
              DialogButton(
                child: const Text("OK"),
                onPressed: () {
                  gotoLogin();
                },
              )
            ]
        ).show();
        // SweetAlert.show(context,
        //     title: "Sukses",
        //     subtitle: response["message"],
        //     style: SweetAlertStyle.success, onPress: (bool isConfirm) {
        //   if (isConfirm) {
        //     gotoLogin();
        //     return true;
        //   }
        // });
      } else {
        Alert(
            context: context,
            type: AlertType.error,
            title: "Error",
            desc: response["message"],
            buttons: [
              DialogButton(
                child: const Text("OK"),
                onPressed: () {
                  return;
                },
              )
            ]
        ).show();
        // SweetAlert.show(context,
        //     title: "Error",
        //     subtitle: response["message"],
        //     style: SweetAlertStyle.error, onPress: (bool isConfirm) {
        //   return true;
        // });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getInfo().then((res) {
      _listSegment();
    });
    _selectedSegments.add;
    ///>>> _selectedSegments.add(null);
  }

  Widget loginPage() {
    return ModalProgressHUD(
        inAsyncCall: _loading,
        child: ListView(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: colorPrimary,
                image: DecorationImage(
                  colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.25), BlendMode.dstATop),
                  image: const AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(
                        top: 100.0, left: 100.0, right: 100.0, bottom: 35.0),
                    child: Center(
                        child: Image.asset("assets/images/logo_rectangle.png",
                            height: 100.0)),
                  ),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            "Email",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 40.0, right: 40.0, top: 10.0),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white,
                            width: 0.5,
                            style: BorderStyle.solid),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            controller: user,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'foo@bar.com',
                              hintStyle: TextStyle(
                                  fontFamily: "LatoLight", color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 24.0,
                  ),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            "PASSWORD",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 40.0, right: 40.0, top: 10.0),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white,
                            width: 0.5,
                            style: BorderStyle.solid),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            controller: pass,
                            obscureText: true,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '*********',
                              hintStyle: TextStyle(
                                  fontFamily: "LatoLight", color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 24.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0, left: 20.0),
                        child: ElevatedButton(
                          child: const Text(
                            "Lupa Password?",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                            textAlign: TextAlign.end,
                          ),
                          onPressed: () => gotoForgotPassword(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 5.0, left: 5.0),
                        child: ElevatedButton(
                          child: const Text(
                            "Tidak Punya Akun?",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                            textAlign: TextAlign.end,
                          ),
                          onPressed: () => gotoSignup(),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 30.0, right: 30.0, top: 20.0),
                    alignment: Alignment.center,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              backgroundColor: colorPrimary,
                            ),
                            onPressed: () => {
                              _login()
                              // Navigator.of(context).push(
                              //   MaterialPageRoute(
                              //     builder: (context) => DashboardPage()
                              //   )
                              // )
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 20.0,
                                horizontal: 20.0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      "LOGIN",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontFamily: "LatoLight",
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                      version == ""
                          ? 'Loading Version...'
                          : "Versi $version",
                      style: const TextStyle(
                          color: Colors.white, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center)
                ],
              ),
            ),
          ],
        ));
  }

  Widget forgotPasswordPage() {
    return ModalProgressHUD(
        inAsyncCall: _loading,
        child: ListView(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: colorPrimary,
                image: DecorationImage(
                  colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.25), BlendMode.dstATop),
                  image: const AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(
                        top: 100.0, left: 100.0, right: 100.0, bottom: 35.0),
                    child: Center(
                        child: Image.asset("assets/images/logo_rectangle.png",
                            height: 100.0)),
                  ),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            "Email",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 40.0, right: 40.0, top: 10.0),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white,
                            width: 0.5,
                            style: BorderStyle.solid),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            controller: _forgotEmail,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'foo@bar.com',
                              hintStyle: TextStyle(
                                  fontFamily: "LatoLight", color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0, left: 20.0),
                        child: ElevatedButton(
                          child: const Text(
                            "Sudah Punya Akun?",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                            textAlign: TextAlign.end,
                          ),
                          onPressed: () => gotoLogin(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0, left: 20.0),
                        child: ElevatedButton(
                          child: const Text(
                            "Tidak Punya Akun?",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                            textAlign: TextAlign.end,
                          ),
                          onPressed: () => gotoSignup(),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 30.0, right: 30.0, top: 20.0),
                    alignment: Alignment.center,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              backgroundColor: colorPrimary,
                            ),
                            onPressed: () => {_forgotPassword()},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 20.0,
                                horizontal: 20.0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      "FORGOT PASSWORD",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontFamily: "LatoLight",
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  Widget signupPage() {
    return ModalProgressHUD(
        inAsyncCall: _loading,
        child: ListView(
          children: [
            Container(
              // height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: colorPrimary,
                image: DecorationImage(
                  colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.25), BlendMode.dstATop),
                  image: const AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(
                        top: 15.0, left: 100.0, right: 100.0, bottom: 35.0),
                    child: Center(
                        child: Image.asset("assets/images/logo_rectangle.png",
                            height: 100.0)),
                  ),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            "NAMA",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 40.0, right: 40.0, top: 10.0),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white,
                            width: 0.5,
                            style: BorderStyle.solid),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _regName,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'John Doe',
                              hintStyle: TextStyle(
                                  fontFamily: "LatoLight", color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 24.0,
                  ),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            "INSTANSI",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                        left: 30.0, right: 30.0, top: 10.0),
                    padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                    child: ListTile(
                      title: DropdownButton(
                        selectedItemBuilder: (BuildContext context) {
                          return <String>[
                            'BPJT',
                            'PMI',
                            'Tim Konsultan SIMK',
                            'PMO'
                          ].map<Widget>((String item) {
                            return Text(
                              item,
                              style: const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                        isExpanded: true,
                        hint: const Row(
                          children: <Widget>[
                            Text(
                              'Pilih Instansi',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        items: <String>[
                          'BPJT',
                          'PMI',
                          'Tim Konsultan SIMK',
                          'PMO'
                        ].map((String item) {
                          return DropdownMenuItem(
                              value: item.toString(),
                              child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                        fontSize: 13.0, color: Colors.black),
                                  )));
                        }).toList(),
                        onChanged: (newVal) {
                          setState(() {
                            _selectedCompanyField = newVal!;
                            if (newVal == 'PMI') {
                              countPackage = 0;
                              _selectedSegments.clear();
                              _selectedSegments.add(null);
                              /// _selectedSegments.add(null);
                            }
                          });
                        },
                        value: _selectedCompanyField,
                        underline: Container(color: Colors.white, height: 0.5),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 24.0,
                  ),
                  Visibility(
                    visible: _selectedCompanyField == "PMI" ? true : false,
                    child: Column(children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 40.0),
                              child: Text(
                                "Ruas 1",
                                style: TextStyle(
                                  fontFamily: "LatoLight",
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 15.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                          margin: const EdgeInsets.only(
                              left: 30.0, right: 30.0, top: 10.0),
                          padding:
                              const EdgeInsets.only(left: 0.0, right: 10.0),
                          child: ListTile(
                            title: SearchChoices.single(
                              items: _segments.map((item) {
                                return DropdownMenuItem(
                                    value: item,
                                    child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.black),
                                        )));
                              }).toList(),
                              selectedValueWidgetFn: (item) {
                                return Container(
                                    transform:
                                        Matrix4.translationValues(-10, 0, 0),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                          fontSize: 12.0, color: Colors.white),
                                    ));
                              },
                              hint: Container(
                                  transform:
                                      Matrix4.translationValues(-10, 0, 0),
                                  child: const Text(
                                    "Pilih Ruas",
                                    style: TextStyle(color: Colors.white),
                                  )),
                              searchHint: "Pilih Ruas",
                              onChanged: (value) {
                                setState(() {
                                  if (value == null) {
                                    _selectedSegments[0] = null;
                                    /// _selectedSegments[0] = null;
                                  } else {
                                    _selectedSegments[0] = value;
                                  }
                                });
                              },
                              value: _selectedSegments[0],
                              isExpanded: true,
                              displayClearIcon: false,
                              underline:
                                  Container(color: Colors.white, height: 0.5),
                              icon: Container(
                                  transform:
                                      Matrix4.translationValues(10, 0, 0),
                                  child: const Icon(Icons.arrow_drop_down)),
                            ),
                          )),
                      countPackage > 0
                          ? getSegmentWidgets(context, countPackage)
                          : Container(),
                      SizedBox(
                          width: 150.0,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(0.0),
                            ),
                            onPressed: () {
                              setState(() {
                                countPackage = countPackage + 1;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    HexColor("#253f5c"),
                                    HexColor("#1d5f7f"),
                                  ],
                                ),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(15, 10, 15, 10),
                              child: const Text('Tambah Ruas',
                                  style: TextStyle(fontSize: 14.0)),
                            ),
                          )),
                      const Divider(
                        height: 24.0,
                      ),
                    ]),
                  ),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            "EMAIL",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 40.0, right: 40.0, top: 10.0),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white,
                            width: 0.5,
                            style: BorderStyle.solid),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _regEmail,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'foo@bar.com',
                              hintStyle: TextStyle(
                                  fontFamily: "LatoLight", color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 24.0,
                  ),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            "PHONE",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 40.0, right: 40.0, top: 10.0),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white,
                            width: 0.5,
                            style: BorderStyle.solid),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _regPhone,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '081232123xxx',
                              hintStyle: TextStyle(
                                  fontFamily: "LatoLight", color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 24.0,
                  ),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            "PASSWORD",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 40.0, right: 40.0, top: 10.0),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white,
                            width: 0.5,
                            style: BorderStyle.solid),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _regPassword,
                            style: const TextStyle(color: Colors.white),
                            obscureText: true,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '*********',
                              hintStyle: TextStyle(
                                  fontFamily: "LatoLight", color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 24.0,
                  ),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            "CONFIRM PASSWORD",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 40.0, right: 40.0, top: 10.0),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.white,
                            width: 0.5,
                            style: BorderStyle.solid),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _regConfirmPass,
                            style: const TextStyle(color: Colors.white),
                            obscureText: true,
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '*********',
                              hintStyle: TextStyle(
                                  fontFamily: "LatoLight", color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 24.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: ElevatedButton(
                          child: const Text(
                            "Sudah Punya Akun?",
                            style: TextStyle(
                              fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15.0,
                            ),
                            textAlign: TextAlign.end,
                          ),
                          onPressed: () => gotoLogin(),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 30.0, right: 30.0, top: 20.0),
                    alignment: Alignment.center,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              backgroundColor: colorPrimary,
                            ),
                            onPressed: () => {_signup()},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 20.0,
                                horizontal: 20.0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      "SIGN UP",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontFamily: "LatoLight",
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 15.0,
                  )
                ],
              ),
            ),
          ],
        ));
  }

  gotoLogin() {
    //controller_0To1.forward(from: 0.0);
    _controller.animateToPage(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.bounceOut,
    );
  }

  gotoSignup() {
    //controller_minus1To0.reverse(from: 0.0);
    _controller.animateToPage(
      1,
      duration: const Duration(milliseconds: 800),
      curve: Curves.bounceOut,
    );
  }

  gotoForgotPassword() {
    //controller_minus1To0.reverse(from: 0.0);
    _controller.animateToPage(
      2,
      duration: const Duration(milliseconds: 800),
      curve: Curves.bounceOut,
    );
  }

  final PageController _controller =
      PageController(initialPage: 0, viewportFraction: 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: PageView(
              controller: _controller,
              physics: const AlwaysScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                loginPage(),
                signupPage(),
                forgotPasswordPage(),
              ],
            )));
  }

  Widget getSegmentWidgets(context, int count) {
    List<Widget> listWidget = [];
    _selectedSegments.add(null);

    for (var i = 1; i <= count; i++) {
      listWidget.add(
        Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: Text(
                  "Ruas ${i + 1}",
                  style: const TextStyle(
                    fontFamily: "LatoLight",
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      listWidget.add(
        Container(
            margin: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0),
            padding: const EdgeInsets.only(left: 0.0, right: 10.0),
            child: ListTile(
              title: SearchChoices.single(
                items: _segments.map((item) {
                  return DropdownMenuItem(
                      value: item,
                      child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            item,
                            style:
                                const TextStyle(fontSize: 12.0, color: Colors.black),
                          )));
                }).toList(),
                selectedValueWidgetFn: (item) {
                  return Container(
                      transform: Matrix4.translationValues(-10, 0, 0),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 12.0, color: Colors.white),
                      ));
                },
                hint: Container(
                    transform: Matrix4.translationValues(-10, 0, 0),
                    child: const Text(
                      "Pilih Ruas",
                      style: TextStyle(color: Colors.white),
                    )),
                searchHint: "Pilih Ruas",
                onChanged: (value) {
                  setState(() {
                    if (value == null) {
                      _selectedSegments[i] = null;
                    } else {
                      _selectedSegments[i] = value;
                    }
                  });
                },
                value: _selectedSegments[i],
                isExpanded: true,
                displayClearIcon: false,
                underline: Container(color: Colors.white, height: 0.5),
                icon: Container(
                    transform: Matrix4.translationValues(10, 0, 0),
                    child: const Icon(Icons.arrow_drop_down)),
              ),
            )),
      );
      listWidget.add(
        const Padding(
          padding: EdgeInsets.all(10.0),
        ),
      );
    }

    return Column(
      children: listWidget,
    );
  }
}
