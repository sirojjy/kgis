// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:bpjtteknik/helper/db_presences.dart';
import 'package:bpjtteknik/utils/utils.dart';
import 'package:bpjtteknik/view/auth/login.dart';
import 'package:bpjtteknik/view/dashboard/dashboard_admin_page.dart';
import 'package:bpjtteknik/view/dashboard/dashboard_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
// import 'package:intl/intl.dart';
import 'package:package_info/package_info.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:workmanager/workmanager.dart';

import 'conn/API.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // AwesomeNotifications().initialize(
  //     null,
  //     [
  //       NotificationChannel(
  //         channelKey: 'key1',
  //         channelName: 'Proto Coders Point',
  //         channelDescription: "Notification example",
  //         defaultColor: Color(0XFF9050DD),
  //         ledColor: Colors.white,
  //         playSound: true,
  //         enableLights:true,
  //         enableVibration: true
  //       )
  //     ]
  // );
  
  // await Workmanager().initialize(
  //   callbackDispatcher, // The top level function, aka callbackDispatcher
  //   isInDebugMode: false // This should be false
  // );

  // await Workmanager().cancelAll();

  // await Workmanager().registerPeriodicTask(
  //     "2", 
  //     "simplePeriodicTask",
  //     frequency: Duration(minutes: 15),
  // );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var email = prefs.getString('email');
  var roleId = prefs.getString('role_id');
  var isApprove = prefs.getBool('is_approve');

  runApp(
    Phoenix(
      child: MaterialApp(
        debugShowCheckedModeBanner: false, 
        home: MyApp(email: email, isApprove: isApprove, roleId: roleId)
      ),
    )
  );
}

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     DateTime now = DateTime.now();
//     String formattedDate = DateFormat('yyyy-MM-dd').format(now);
//     print("prefPresence");
//     print(formattedDate);
//     print("prefPresence");
    
//     var prefs = SharedPreferences.getInstance();
//     prefs.catchError((onError) {
//       print(onError);
//     });
//     // String prefPresence = prefs.getString('presence');
//     // String prefEmail = prefs.getString('email');

//     // print("prefPresence");
//     // print(prefPresence);
//     // print(prefEmail);
//     // print("prefPresence");

//     AwesomeNotifications().createNotification(
//       content: NotificationContent(
//         id: 1,
//         channelKey: 'key1',
//         title: 'Reminder Absensi',
//         body: 'Anda belum melakukan absen, silahkan lakukan absen pada aplikasi KGIS'
//       )
//     );
//     return Future.value(true);
//   });
// }

class MyApp extends StatelessWidget {
  final email;
  final isApprove;
  final roleId;

  MyApp({Key key, @required this.email, @required this.isApprove, @required this.roleId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BPJT Teknik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.light,
      home: CollectionApp(email, isApprove, roleId),
    );
  }
}

class CollectionApp extends StatefulWidget {
  final email;
  final isApprove;
  final roleId;

  CollectionApp(this.email, this.isApprove, this.roleId);

  @override
  _CollectionAppState createState() => _CollectionAppState(email, isApprove, roleId);
}

class _CollectionAppState extends State<CollectionApp> {
  bool _loading = true;

  String fcmToken;

  var email;
  var isApprove;
  var roleId;
  var _user;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  
  _CollectionAppState(email, isApprove, roleId) {
    this.email = email;
    this.isApprove = isApprove;
    this.roleId = roleId;
  }
  
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
    if (email == null) {
      email = prefs.getString('email');
    } 

    if (roleId == null) {
      roleId = prefs.getString('role_id');
    }

    if (isApprove == null) {
      isApprove = prefs.getBool('is_approve');
    }
  }

  _getUser(userEmail) async {
    await API.getUserByEmail(userEmail, version).then((response) {
      setState(() {
        _user = response;
      });
    });

    return _user;
  }

  void initState() {
    super.initState();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );
    _firebaseMessaging.getToken().then((String token) {
      // assert(token != null);
      fcmToken = token;
    });

    _getInfo().then((resInfo) {
      _getPref().then((res) async {
        if (await Utils.checkConnection()) {
          _getUser(email).then((resUser) async {
            if (resUser != null) {
              if (resUser["should_logout"]) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.clear();
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginPage()), (Route<dynamic> route) => false);
              }

              if (resUser["should_update"]) {
                //TODO Show popup and action button exit(0)
              }

              if (resUser["fcm_token"] == null) {
                //Update fcm_token
              }
            }
          });
        }

        setState(() {
          _loading = false;
        });
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Theme.of(context).primaryColor,
        fontFamily: 'Lato'
      ),
      themeMode: ThemeMode.light,
      home: _loading ? 
        Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ) :
          (email != null && email != 'null') ? 
            (
              roleId.toString() == "1" ? 
              DashboardAdminPage() : 
              DashboardPage()
            ) 
          : LoginPage()
      // home: LoginPage()
    );
  }
}