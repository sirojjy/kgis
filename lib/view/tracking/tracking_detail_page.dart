import 'dart:io';

import 'package:bpjt_k_gis_mobile_master/conn/API.dart';
import 'package:bpjt_k_gis_mobile_master/image_detail.dart';
import 'package:bpjt_k_gis_mobile_master/pdf_viewer.dart';
import 'package:bpjt_k_gis_mobile_master/utils/utils.dart';
import 'package:bpjt_k_gis_mobile_master/view/dashboard/dashboard_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/tracking/map_tracking_page.dart';
import 'package:carousel_pro_nullsafety/carousel_pro_nullsafety.dart';
import 'package:flutter/material.dart';
import 'package:bpjt_k_gis_mobile_master/helper/main_helper.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:carousel_pro/carousel_pro.dart';
// import 'package:package_info/package_info.dart';
// import 'package:sweetalert/sweetalert.dart';

class TrackingDetailPage extends StatefulWidget {
  final id;
  final userId;
  final name;
  final phone;
  final email;
  final position;
  final problem;
  final long;
  final lat;
  final filename;
  final filepath;
  final segment;
  final date;
  final priority;
  final createdAt;
  final updatedAt;
  final isActive;
  final isDelete;
  final isHidden;
  final location;
  final note;
  final note2;
  final companyField;
  final noteAnswer;

  TrackingDetailPage({
    this.id,
    this.userId,
    this.name,
    this.phone,
    this.email,
    this.position,
    this.problem,
    this.long,
    this.lat,
    this.filename,
    this.filepath,
    this.segment,
    this.date,
    this.priority,
    this.createdAt,
    this.updatedAt,
    this.isActive,
    this.isDelete,
    this.isHidden,
    this.location,
    this.note,
    this.note2,
    this.companyField,
    this.noteAnswer,
  });

  @override
  _TrackingDetailPageState createState() => _TrackingDetailPageState();
}

class _TrackingDetailPageState extends State<TrackingDetailPage> {
  var onlyImageList = [];
  var pdfList = [];
  List<String> imagePathList = [];
  List<String> imageDevicePathList = [];

  TextEditingController _noteController = TextEditingController();

  late String appName;
  late String packageName;
  late String version;
  late String buildNumber;

  _getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }
  
  Future onlyImage(String filepath, String filename) async {
    // for(var i = 0; i < imageList.length; i++){
      if(filepath == null || filepath == "") {
        filepath = "storage/app/media/activities";
      }
      if (!(filename).contains(".pdf") && !(filename).contains(".doc") && !(filename).contains(".docx")) {
        onlyImageList.add(Image.network("http://simk.bpjt.pu.go.id/bpjt-teknik/public$filepath/$filename"));
        imagePathList.add("http://simk.bpjt.pu.go.id/bpjt-teknik/public$filepath/$filename");
        pdfList.add("");
      } else {
        onlyImageList.add(Image.asset("assets/images/pdf_placeholder.png"));
        imagePathList.add("");
        pdfList.add("http://1simk.bpjt.pu.go.id/bpjt-teknik/public$filepath/$filename");
      }
    // }
  }

  _openMap() async {
    String url = "https://www.google.com/maps/search/?api=1&query=${widget.lat},${widget.long}";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  
  @override
  void initState() {
    super.initState();
    onlyImage(widget.filepath, widget.filename);
    if (widget.companyField == 'BPJT') {
      _noteController = TextEditingController(text: widget.note2);
    } else if (widget.companyField == 'PMO') {
      _noteController = TextEditingController(text: widget.note);
    } else if (widget.companyField == 'PMI') {
      _noteController = TextEditingController(text: widget.noteAnswer);
    }
    _getInfo().then((resInfo) {

    });
  }

  _saveNote() async {
    Map<String, dynamic> params = <String, dynamic>{};
    params["id"] = widget.id;
    if (widget.companyField == 'BPJT') {
      params["note2"] = _noteController.text;
    } else if (widget.companyField == 'PMO') {
      params["note"] = _noteController.text;
    } else if (widget.companyField == 'PMI') {
      params["note_answer"] = _noteController.text;
    }

    await API.storeTrackingProblem(params, "", version).then((response) {
      if (response["status"] != null) {
        if (response["status"] == "success") {
          Alert(
            context: context,
            type: AlertType.success,
            title: "Sukses",
            desc: response["message"],
            buttons: [
              DialogButton(
                  child: const Text("Ok"),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => DashboardPage()), (Route<dynamic> route) => false);
                  }
              )
            ]
          ).show();
          // SweetAlert.show(context,
          //   title: "Sukses",
          //   subtitle: response["message"],
          //   style: SweetAlertStyle.success,
          //   onPress: (bool isConfirm) {
          //     if (isConfirm) {
          //       Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => DashboardPage()), (Route<dynamic> route) => false);
          //     }
          //     return true;
          //   }
          // );
        } else {
          Alert(
              context: context,
              type: AlertType.error,
              title: "Error",
              desc: response["message"],
              buttons: [
                DialogButton(
                    child: const Text("Ok"),
                    onPressed: () {
                      return;
                    }
                )
              ]
          ).show();
          // SweetAlert.show(context,
          //   title: "Error",
          //   subtitle: response["message"],
          //   style: SweetAlertStyle.error,
          //   onPress: (bool isConfirm) {
          //     return true;
          //   }
          // );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tracking Permasalahan'),
        backgroundColor: colorPrimary,
      ),
      body: bodyDetail(context)
    );
  }

  Widget bodyDetail(context) {
    _launchURL(int i) async {
      if ((pdfList[i] == "" || pdfList[i] == null) && (imagePathList[i] != "" && imagePathList[i] != null)) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImageDetail(
              imageWidget: Image.network(
                imagePathList[i],
                fit: BoxFit.fitHeight
              ),
              imageUrl: imagePathList[i],
            )
          )
        );
      } else if ((imagePathList[i] == "" || imagePathList[i] == null) && (pdfList[i] != "" && pdfList[i] != null)) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerPage(
              pdfUrl: pdfList[i],
            )
          )
        );
      } else {
        print("NOT PDF OR IMAGE");
      }
    }
    List<Widget> widgetImageList = onlyImageList.map((image) => Image.network(image)).toList();
    Widget imageCarousel = SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: Carousel(
        boxFit: BoxFit.cover,
        images: widgetImageList,
        autoplay: true,
        animationCurve: Curves.fastOutSlowIn,
        animationDuration: const Duration(milliseconds: 1000),
        dotSize: 4.0,
        indicatorBgPadding: 2.0,
        dotBgColor: Colors.transparent,
        onImageTap: (src) {
          _launchURL(src);
        }
      ),
    );
    
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 5.0),
              ),
              widget.filepath.isEmpty ? Image.asset("images/no_image_2.png", height: 200.0) : imageCarousel,
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(date(DateTime.parse(widget.date)), style: const TextStyle(fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(widget.segment, style: const TextStyle(fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lokasi :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.location == null || widget.location == "" ? '-' : widget.location)
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Masalah yang dilaporkan :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.problem == null || widget.problem == "" ? '-' : widget.problem)
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lat :', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.lat == null || widget.lat == "" ? '-' : widget.lat)
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Long :', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.long == null || widget.long == "" ? '-' : widget.long)
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 5.0),
                          child: SizedBox.fromSize(
                            size: const Size(40, 40), // button width and height
                            child: ClipOval(
                              child: Material(
                                color: Colors.blue, // button color
                                child: InkWell(
                                  splashColor: Colors.green, // splash color
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: "${widget.lat}, ${widget.long}"));
                                    Alert(
                                        context: context,
                                        type: AlertType.none,
                                        // title: "Error",
                                        desc: "Koordinat Berhasil Disalin",
                                        buttons: [
                                          DialogButton(
                                              child: const Text("Ok"),
                                              onPressed: () {
                                                return;
                                              }
                                          )
                                        ]
                                    ).show();
                                    // SweetAlert.show(
                                    //   context,
                                    //   // title: "OK",
                                    //   subtitle: "Koordinat Berhasil Disalin",
                                    //   style: SweetAlertStyle.success,
                                    //   onPress: (bool isConfirm) {
                                    //     return true;
                                    //   }
                                    // );
                                  }, // button pressed
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(Icons.copy, color: Colors.white,), // icon
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 5.0),
                          child: SizedBox.fromSize(
                            size: const Size(40, 40), // button width and height
                            child: ClipOval(
                              child: Material(
                                color: Colors.blue, // button color
                                child: InkWell(
                                  splashColor: Colors.green, // splash color
                                  onTap: () {
                                    _openMap();
                                  }, // button pressed
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(Icons.my_location_outlined, color: Colors.white,), // icon
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 5.0),
                          child: SizedBox.fromSize(
                            size: const Size(40, 40), // button width and height
                            child: ClipOval(
                              child: Material(
                                color: Colors.blue, // button color
                                child: InkWell(
                                  splashColor: Colors.green, // splash color
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MapTrackingPage(
                                          long: widget.long,
                                          lat: widget.lat
                                        )
                                      )
                                    );
                                  }, // button pressed
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(Icons.location_pin, color: Colors.white,), // icon
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        )
                      ],
                    )
                  ],
                )
              ),
              Visibility(
                visible: widget.companyField == "PMI" || widget.companyField == "PMO" || widget.companyField == "BPJT"? true : false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Catatan BPJT/PMO 1 :', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(widget.note == null || widget.note == "" ? '-' : widget.note)
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Catatan BPJT/PMO 2 :', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(widget.note2 == null || widget.note2 == "" ? '-' : widget.note2)
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tanggapan PMI :', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(widget.noteAnswer == null || widget.noteAnswer == "" ? '-' : widget.noteAnswer)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey,),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nama :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.name ?? '-'),
                    const SizedBox(height: 5.0),
                    const Text('Jabatan :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.position ?? '-'),
                    const SizedBox(height: 5.0),
                    const Text('HP :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.phone ?? '-'),
                    const SizedBox(height: 5.0),
                    const Text('Email :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.email ?? '-'),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomButton(context)
      ],
    );
  }

  Widget bottomButton(context) {
    return SizedBox(
      height: 60.0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange,),
              child: Text((widget.companyField == 'PMI' ? "Tanggapan" : "Catatan"), style: const TextStyle(color: Colors.white),),
              onPressed: (){
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text((widget.companyField == 'PMI' ? "Tanggapan " : "Catatan ")+widget.companyField),
                      content: TextFormField(
                        controller: _noteController,
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Isi',
                          labelStyle: TextStyle(decorationStyle: TextDecorationStyle.solid)
                        ),
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green,),
                          child: const Text("Simpan", style: TextStyle(color: Colors.white),),
                          onPressed: (){
                            Navigator.pop(context);
                            _saveNote();
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red,),
                          child: const Text("Tutup", style: TextStyle(color: Colors.white),),
                          onPressed: (){
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue,),
              child: const Text("Bagikan", style: TextStyle(color: Colors.white),),
              onPressed: () async {
                final RenderBox box = context.findRenderObject();
                if (imageDevicePathList.isEmpty) {
                  for(var i = 0; i < imagePathList.length; i++){
                    if (imagePathList[i] != "") {
                      await _asyncMethod(imagePathList[i]);
                    }
                  }
                }
                List<XFile> xFileList = imageDevicePathList.map((path) => XFile(path)).toList();
                if (xFileList.isNotEmpty) {
                  await Share.shareXFiles(xFileList,
                      text: "${"Laporan Permasalahan Ruas "+widget.segment+" oleh PMI "+widget.name}\nTanggal : ${DateFormat("dd-MM-yyyy").format(DateTime.parse(widget.date))}\n\n"+widget.problem,
                      subject: "Laporan Permasalahan Ruas ${widget.segment}",
                      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
                } else {
                  await Share.share("${"Laporan Permasalahan Ruas "+widget.segment+" oleh PMI "+widget.name}\nTanggal : ${DateFormat("dd-MM-yyyy").format(DateTime.parse(widget.date))}\n\n"+widget.problem,
                      subject: "Laporan Permasalahan Ruas "+widget.segment,
                      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
                }
              },
            ),
          ],
        )
      ),
    );
  }

  _asyncMethod(String imageUrl) async {
    var url = Uri.parse(imageUrl);
    var imageName = url.toString().split('/').last;
    var response = await get(url);
    var documentDirectory = await getApplicationDocumentsDirectory();
    var firstPath = "${documentDirectory.path}/Pictures";
    var filePathAndName = '${documentDirectory.path}/Pictures/$imageName';

    await Directory(firstPath).create(recursive: true);
    File file2 = File(filePathAndName);
    file2.writeAsBytesSync(response.bodyBytes);
    setState(() {
      imageDevicePathList.add(filePathAndName);
    });
  }
}