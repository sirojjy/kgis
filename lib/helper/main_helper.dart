import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:art_sweetalert/art_sweetalert.dart';

String googleBasemapUrl = "http://{s}.google.com/vt/lyrs=s,h&x={x}&y={y}&z={z}";
List<String> googleBasemapSubdomain = ['mt0','mt1','mt2','mt3'];

String osmBasemapUrl = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
List<String> osmBasemapSubdomain = ['a', 'b', 'c'];

String arcgisBasemapUrl = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}";
List<String> arcgisBasemapSubdomain = ['a', 'b', 'c'];

String wmsBasemapAlternativeOne = "https://tiles.maps.eox.at/?";
void changeScreen(BuildContext context, Widget widget) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => widget));
}

void changeScreenReplacement(BuildContext context, Widget widget) {
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => widget));
}

void showUpdateAppsModal(BuildContext context, response) async {
  var updateUrl = await canLaunch("https://bit.ly/UpdateKGIS");

  BuildContext currentContext = context;

  if (response != null && response[0] == null && response["status"] != null) {
    if (response["status"] == "error") {
      ArtSweetAlert.show(
        context: currentContext,
        artDialogArgs: ArtDialogArgs(
          title: "Error",
          type: ArtSweetAlertType.danger,
          onDeny: (bool isConfirm) {
            if (response["data"] != null && response["data"]["url"] != null) {
              if (updateUrl) {
                launch("https://bit.ly/UpdateKGIS");
              } else {
                throw 'Could not launch url';
              }
            }
            return true;
          },
        ),
      );
    }
  }
}


String baseMap(String type) {
  if (type == "arcgis") {
    return arcgisBasemapUrl;
  } else if (type == "osm") {
    return osmBasemapUrl;
  } else if (type == 'wmsAltOne') {
    return wmsBasemapAlternativeOne;
  } else {
    return googleBasemapUrl;
  }
}

List<String> baseMapLayers(String type) {
  if (type == "osm") {
    return ["osm"];
  } else {
    return ["s2cloudless-2020"];
  }
}

List<String> baseMapSubdomain(String type) {
  if (type == "arcgis") {
    return arcgisBasemapSubdomain;
  } else if (type == "osm") {
    return osmBasemapSubdomain;
  } else {
    return googleBasemapSubdomain;
  }
}

String monthIndo(int month) {
  switch (month) {
    case 1:
      return "Januari";
    case 2:
      return "Februari";
    case 3:
      return "Maret";
    case 4:
      return "April";
    case 5:
      return "Mei";
    case 6:
      return "Juni";
    case 7:
      return "Juli";
    case 8:
      return "Agustus";
    case 9:
      return "September";
    case 10:
      return "Oktober";
    case 11:
      return "November";
    case 12:
      return "Desember";
  }

  return "";
}

String date(DateTime tm) {
  DateTime today = DateTime.now();
  Duration oneDay = const Duration(days: 1);
  Duration twoDay = const Duration(days: 2);
  // Duration oneWeek = new Duration(days: 7);
  String month;
  String day ='';

  month = monthIndo(tm.month);
  
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

  if (tm.hour > 0 || tm.minute > 0 || tm.second > 0) {
    var _24hour = DateFormat('HH:mm:ss').format(tm);
    return '$day, ${tm.day} $month ${tm.year} ${_24hour.toString()}';
  }
  return '$day, ${tm.day} $month ${tm.year}';
}