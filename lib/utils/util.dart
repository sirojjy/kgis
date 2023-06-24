import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Constants.dart';

class Utils {
  static Future<bool> checkConnection() async {
    ConnectivityResult connectivityResult = await (Connectivity().checkConnectivity());
    if ((connectivityResult == ConnectivityResult.mobile) ||
        (connectivityResult == ConnectivityResult.wifi)) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> checkServerStatus(String ip) async {
    try {
      final result = await InternetAddress.lookup(ip).timeout(
        Duration(seconds: 3)
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch(_) {
      return false;
    } on HttpException catch(_) {
      return false;
    } on Exception catch(_) {
      return false;
    }
  }  

  static bool isAndroidPlatform(){
    if (Platform.isAndroid) {
      return true;
      // Android-specific code
    } else if (Platform.isIOS) {
      // iOS-specific code
      return false;
    }
    return false;
  }

  // static void syncPresenceTrackings() async {
  //   if (await Utils.checkConnection()) {
  //     await dbPresence.sendPresencesUnsync();
  //   } else {
  //     print("disconnected");
  //   }
  // }

  // static void syncPermitTrackings() async {
  //   if (await Utils.checkConnection()) {
  //     await dbPresence.sendPermitUnsync();
  //   } else {
  //     print("disconnected");
  //   }
  // }

  static void showAlert(
      BuildContext context, String title, String text, VoidCallback onPressed,bool cancelable) {
    var alert = Utils.isAndroidPlatform() ? AlertDialog(
      title: Text(title,overflow: TextOverflow.ellipsis,),

      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(text),
          ],
        ),
      ),

      actions: <Widget>[
        TextButton (
            onPressed: onPressed,
            child: Text(
              "OK",
              style: TextStyle(color: Constants.clr_blue),
            )
        )
      ],
    ) : CupertinoAlertDialog (

      title: Text(title,overflow: TextOverflow.ellipsis,),

      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(text),
          ],
        ),
      ),

      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: onPressed,
          child: Text(
            "OK",
            style: TextStyle(color: Constants.clr_blue),
          )
        ),
      ],
    );

    showDialog(
        context: context,
        barrierDismissible: cancelable,
        builder: (_) {
          return alert;
        });
  }

  static void showOkCancelAlert(
      BuildContext context, String title, String text, VoidCallback onPressed) {
    var alert = AlertDialog(
      title: Text(title),
      content: Container(
        child: Row(
          children: <Widget>[Text(text)],
        ),
      ),
      actions: <Widget>[
        TextButton (
            onPressed: onPressed,
            child: Text(
              "OK",
              style: TextStyle(color: Colors.black87),
            )),
        TextButton (
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Constants.clr_blue),
            ))
      ],
    );

    showDialog(
        context: context,
        builder: (_) {
          return alert;
        });
  }


  static int getColorHexFromStr(String colorStr)
  {
    colorStr = "FF" + colorStr;
    colorStr = colorStr.replaceAll("#", "");
    int val = 0;
    int len = colorStr.length;
    for (int i = 0; i < len; i++) {
      int hexDigit = colorStr.codeUnitAt(i);
      if (hexDigit >= 48 && hexDigit <= 57) {
        val += (hexDigit - 48) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 65 && hexDigit <= 70) {
        // A..F
        val += (hexDigit - 55) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 97 && hexDigit <= 102) {
        // a..f
        val += (hexDigit - 87) * (1 << (4 * (len - 1 - i)));
      } else {
        throw new FormatException("An error occurred when converting a color");
      }
    }
    return val;
  }

  static String date(DateTime tm) {
    DateTime today = new DateTime.now();
    Duration oneDay = new Duration(days: 1);
    Duration twoDay = new Duration(days: 2);
    // Duration oneWeek = new Duration(days: 7);
    String? month;
    String? day;
    switch (tm.month) {
      case 1:
        month = "Januari";
        break;
      case 2:
        month = "Februari";
        break;
      case 3:
        month = "Maret";
        break;
      case 4:
        month = "April";
        break;
      case 5:
        month = "Mei";
        break;
      case 6:
        month = "Juni";
        break;
      case 7:
        month = "Juli";
        break;
      case 8:
        month = "Agustus";
        break;
      case 9:
        month = "September";
        break;
      case 10:
        month = "Oktober";
        break;
      case 11:
        month = "November";
        break;
      case 12:
        month = "Desember";
        break;
    }

    Duration difference = today.difference(tm);

    if (difference.compareTo(oneDay) < 1) {
      day = "Hari Ini";
    } else if (difference.compareTo(twoDay) < 1) {
      day = "Kemarin";
    } else {
      switch (tm.weekday) {
        case 1:
          day = "Senin";
          break;
        case 2:
          day = "Selasa";
          break;
        case 3:
          day = "Rabu";
          break;
        case 4:
          day = "Kamis";
          break;
        case 5:
          day = "Jumat";
          break;
        case 6:
          day = "Sabtu";
          break;
        case 7:
          day = "Minggu";
          break;
      } 
    }

    return '$day, ${tm.day} $month ${tm.year}';
  }
}