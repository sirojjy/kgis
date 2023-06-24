import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:art_sweetalert/art_sweetalert.dart';
import 'package:bpjt_k_gis_mobile_master/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sweetalert/sweetalert.dart';

class FreeCameraPage extends StatefulWidget {
  @override
  _FreeCameraPageState createState() => _FreeCameraPageState();
}

class _FreeCameraPageState extends State<FreeCameraPage> {
  Position? _position;
  
  TextEditingController _staController = new TextEditingController();

  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];

  String? districtSubdistrict;
  String? cityRegion;
  String? completeLocation;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  var prefSegment;

  File? _image;
  
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
      if (_image != null && _image?.path != null) {
        GallerySaver.saveImage(_image!.path).then((e) {
          ArtSweetAlert.show(
            context: context,
            artDialogArgs: ArtDialogArgs(
              type: ArtSweetAlertType.success,
              title: "Sukses",
              text: "Gambar Tersimpan Pada Gallery",
            ),
          );
        });
      }
  }
  
  Future _getImage() async {

    if (_staController.text == "") {
      ArtSweetAlert.show(
          context: context,
          artDialogArgs: ArtDialogArgs(
            type: ArtSweetAlertType.danger,
            title: "Gagal",
            text: "Silahkan masukkan STA terlebih dahulu."
          )
      );
      // SweetAlert.show(
      //   context,
      //   title: "Gagal",
      //   subtitle: "Silahkan masukkan STA terlebih dahulu.",
      //   style: SweetAlertStyle.error,
      //   onPress: (bool isConfirm) {
      //     if (isConfirm) {
      //       return;
      //     }
      //     return;
      //   }
      // );
      return;
    }

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy – kk:mm').format(now);

    var imagePicker =  ImagePicker();
    var image = await imagePicker.pickImage(source: ImageSource.camera);
    var imageBytes = await image!.readAsBytes();
    img.Image? im = img.decodeImage(imageBytes);

    img.Image convertImage = img.copyResize(im!, width: 800);

    img.Image drawName = img.drawString(img.Image.from(convertImage), font: img.arial24,  prefName);
    img.Image drawDateTime = img.drawString(img.Image.from(drawName), font: img.arial24, formattedDate);
    img.Image drawSegment = img.drawString(img.Image.from(drawDateTime), font: img.arial24, prefSegment);
    img.Image drawLongLat = img.drawString(img.Image.from(drawSegment), font: img.arial24, '${_position?.latitude} ${_position?.longitude}');
    img.Image drawDistrictSubdistrict = img.drawString(img.Image.from(drawLongLat), font: img.arial24,districtSubdistrict!);
    img.Image drawCityRegion = img.drawString(img.Image.from(drawDistrictSubdistrict), font: img.arial24, cityRegion!);
    img.Image drawSTA = img.drawString(img.Image.from(drawCityRegion), font: img.arial24, 'STA ${_staController.text}');
    img.Image drawAltitude = img.drawString(img.Image.from(drawSTA), font: img.arial24, 'ALT ${_position?.altitude}');

    var encodedImage = img.encodeNamedImage(drawAltitude as String, image.path as img.Image);
    File(image.path).writeAsStringSync(encodedImage as String);
    setState(() {
      _image = image as File?;
    });

    // var encodedImage = img.encodeNamedImage(drawAltitude, image.path);
    // File(image.path).writeAsStringSync(encodedImage);
    // setState(() {
    //   _image = image;
    // });
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
        title: const Text('Free Camera'),
        backgroundColor: colorPrimary,
      ),
      body: Container(
        padding: const EdgeInsets.all(15.0),
        child: ListView(
          children: [
            Text(
              completeLocation ??
              "Sedang Mengkalibrasi Posisi Anda",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
                fontStyle: FontStyle.italic
              ),
            ),
            Text(
              _position == null ?
              "Sedang Mengkalibrasi Koordinat Anda" :
              "Lat : ${_position?.latitude.toString()}, Long : ${_position?.longitude.toString()}",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
                fontStyle: FontStyle.italic
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              _position == null ?
              "Harap Tunggu Sedang Mengkalibrasi Jarak Akurat Anda" :
              "Akurat Hingga "+_position!.accuracy.toStringAsFixed(0).toString()+" Meter",
              style: const TextStyle(
                color: Colors.black, 
                fontSize: 20.0, 
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.only(left: 10.0),
              child: const Text("Isikan STA")
            ),
            Container(
              child: ListTile(
                title: TextField(
                  controller: _staController,
                  decoration: const InputDecoration(
                    hintText: "STA",
                  ),
                  minLines: 1
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            displaySelectedFile(_image!),
            Container(
              child: const Text('*Klik Pada Gambar Diatas Untuk Mengambil Foto', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.0),textAlign: TextAlign.center,),
            ),
            const SizedBox(height: 10.0),
            Container(
              margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.25, left: MediaQuery.of(context).size.width * 0.25),
              // width: MediaQuery.of(context).size.width * 0.35,
              child: MaterialButton(
                padding: const EdgeInsets.all(2.0),
                onPressed: () {
                  _saveToGallery();
                },
                color: colorPrimary,
                child: const Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(3.0),
                      child: Text("Simpan Ke Gallery", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
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
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(width: 3.0, color: HexColor("D8BFD8")),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.file(File("assets/images/person_6x8.png"), fit: BoxFit.fitHeight),
            ),
          ),
        )
      )
    );
  }
}