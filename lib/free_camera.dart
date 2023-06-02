import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bpjtteknik/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetalert/sweetalert.dart';

class FreeCameraPage extends StatefulWidget {
  @override
  _FreeCameraPageState createState() => _FreeCameraPageState();
}

class _FreeCameraPageState extends State<FreeCameraPage> {
  Position _position;
  
  TextEditingController _staController = new TextEditingController();

  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];

  String districtSubdistrict;
  String cityRegion;
  String completeLocation;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  var prefSegment;

  File _image;
  
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

  _saveToGallery() async {
      if (_image != null && _image.path != null) {
        GallerySaver.saveImage(_image.path).then((e) {
          SweetAlert.show(
            context,
            title: "Sukses",
            subtitle: "Gambar Tersimpan Pada Gallery",
            style: SweetAlertStyle.success,
            onPress: (bool isConfirm) {
              return true;
            }
          );
        });
      }
  }
  
  Future _getImage() async {

    if (_staController.text == "") {
      SweetAlert.show(
        context,
        title: "Gagal",
        subtitle: "Silahkan masukkan STA terlebih dahulu.",
        style: SweetAlertStyle.error,
        onPress: (bool isConfirm) {
          if (isConfirm) {
            return;  
          }
          return;
        }
      );

      return;
    }

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy – kk:mm').format(now);

    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    img.Image im = img.decodeImage(image.readAsBytesSync());

    img.Image convertImage = img.copyResize(im, width: 800);

    img.Image drawName = img.drawString(img.Image.from(convertImage), img.arial_24, 0, 0, prefName);
    img.Image drawDateTime = img.drawString(img.Image.from(drawName), img.arial_24, 0, 30, formattedDate);
    img.Image drawSegment = img.drawString(img.Image.from(drawDateTime), img.arial_24, 0, 60, prefSegment);
    img.Image drawLongLat = img.drawString(img.Image.from(drawSegment), img.arial_24, 0, 90, '${_position.latitude} ${_position.longitude}');
    img.Image drawDistrictSubdistrict = img.drawString(img.Image.from(drawLongLat), img.arial_24, 0, 120,districtSubdistrict);
    img.Image drawCityRegion = img.drawString(img.Image.from(drawDistrictSubdistrict), img.arial_24, 0, 150,cityRegion);
    img.Image drawSTA = img.drawString(img.Image.from(drawCityRegion), img.arial_24, 0, 180, 'STA ${_staController.text}');
    img.Image drawAltitude = img.drawString(img.Image.from(drawSTA), img.arial_24, 0, 210, 'ALT ${_position.altitude}');

    File(image.path).writeAsBytesSync(img.encodeNamedImage(drawAltitude, image.path));
    setState(() {
      _image = image;
    });
  }
  
  @override
  void initState() {
    super.initState();
    // _getInfo().then((resInfo) {
      _getPref().then((response) {
        _getCurrentPosition();
        _addLocationStream();
      });
    // });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Free Camera'),
        backgroundColor: colorPrimary,
      ),
      body: Container(
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
            SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text("Isikan STA")
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
            SizedBox(height: 10.0),
            displaySelectedFile(_image),
            Container(
              child: Text('*Klik Pada Gambar Diatas Untuk Mengambil Foto', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.0),textAlign: TextAlign.center,),
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
                      child: Text("Simpan Ke Gallery", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
                onPressed: () {
                  _saveToGallery();
                },
                color: colorPrimary,
                // disabledColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget displaySelectedFile(File file) {
    return GestureDetector(
      onTap: this._getImage,
      child: SizedBox(
        height: 300.0,
        child: Container(
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