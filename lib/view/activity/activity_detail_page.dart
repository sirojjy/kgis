import 'dart:async';
import 'dart:io';

import 'package:art_sweetalert/art_sweetalert.dart';
import 'package:bpjt_k_gis_mobile_master/image_detail.dart';
import 'package:bpjt_k_gis_mobile_master/pdf_viewer.dart';
import 'package:bpjt_k_gis_mobile_master/utils/utils.dart';
import 'package:bpjt_k_gis_mobile_master/view/activity/map_activity_page.dart';
import 'package:carousel_pro_nullsafety/carousel_pro_nullsafety.dart';
import 'package:flutter/material.dart';
import 'package:bpjt_k_gis_mobile_master/helper/main_helper.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityDetailPage extends StatefulWidget {
  final id;
  final userId;
  final name;
  final phone;
  final email;
  final position;
  final activity;
  final long;
  final lat;
  final segment;
  final date;
  final isActive;
  final isDelete;
  final isHidden;
  final createdAt;
  final updatedAt;
  final priority;
  final activityDetails;
  final companyField;
  final location;

  ActivityDetailPage({
    this.id,
    this.userId,
    this.name,
    this.phone,
    this.email,
    this.position,
    this.activity,
    this.long,
    this.lat,
    this.segment,
    this.date,
    this.isActive,
    this.isDelete,
    this.isHidden,
    this.createdAt,
    this.updatedAt,
    this.priority,
    this.activityDetails,
    this.companyField,
    this.location
  });

  @override
  _ActivityDetailPageState createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  var onlyImageList = [];
  var pdfList = [];
  var imagePathList = [];
  List<String> imageDevicePathList = [];

  Future onlyImage(List imageList) async {
    for(var i = 0; i < imageList.length; i++){
      if(imageList[i]["filepath"] == null || imageList[i]["filepath"] == "") {
        imageList[i]["filepath"] = "storage/app/media/activities";
      }
      if (!(imageList[i]["filename"]).contains(".pdf") && !(imageList[i]["filename"]).contains(".doc") && !(imageList[i]["filename"]).contains(".docx")) {
        onlyImageList.add(Image.network("${"http://simk.bpjt.pu.go.id/bpjt-teknik/public"+imageList[i]["filepath"]}/"+imageList[i]["filename"]));
        imagePathList.add("${"http://simk.bpjt.pu.go.id/bpjt-teknik/public"+imageList[i]["filepath"]}/"+imageList[i]["filename"]);
        pdfList.add("");
      } else {
        onlyImageList.add(Image.asset("assets/images/pdf_placeholder.png"));
        imagePathList.add("");
        pdfList.add("${"http://103.6.53.254:13480/bpjt-teknik/public"+imageList[i]["filepath"]}/"+imageList[i]["filename"]);
      }
    }
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
    onlyImage(widget.activityDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kegiatan'),
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
    
    Widget imageCarousel = Container(
      height: MediaQuery.of(context).size.height * 0.35,
      child: Carousel(
          boxFit: BoxFit.cover,
          images: onlyImageList.map((image) => Image(image: AssetImage(image))).toList(),
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
              widget.activityDetails.isEmpty ? Image.asset("images/no_image_2.png", height: 200.0) : imageCarousel,
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(date(DateTime.parse(widget.date)), style: const TextStyle(fontWeight: FontWeight.bold))
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(widget.segment, style: const TextStyle(fontWeight: FontWeight.bold))
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
                    const Text('Aktifitas Dilaporkan :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.activity)
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
                                    ArtSweetAlert.show(
                                      context: context,
                                        artDialogArgs: ArtDialogArgs(
                                        type: ArtSweetAlertType.success,
                                        title: "Sukses",
                                        text: "Koordinat Berhasil Disalin",
                                        )
                                      // title: "OK",
                                    );
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
                                        builder: (context) => MapActivityPage(
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
    return Container(
      height: 60.0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue,),
              child: const Text("Bagikan", style: TextStyle(color: Colors.white),),
              onPressed: () async {
                final RenderBox box = context.findRenderObject();
                
                if (imageDevicePathList.isEmpty) {
                  for(var i = 0; i < imagePathList.length; i++){
                      await _asyncMethod(imagePathList[i]);
                  }
                }
                // Share.shareFiles().
                if (imageDevicePathList.isNotEmpty) {
                  await Share.shareFiles(imageDevicePathList,
                      text: "${"Laporan Kegiatan Ruas "+widget.segment}\n\n"+widget.activity,
                      subject: "Laporan Kegiatan Ruas " + widget.segment,
                      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
                } else {
                  await Share.share("${"Laporan Kegiatan Ruas "+widget.segment}\n\n"+widget.activity,
                      subject: "Laporan Kegiatan Ruas "+widget.segment,
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
    var url = imageUrl;
    var imageName = url.split('/').last;
    var response = await get(url as Uri);
    var documentDirectory = await getApplicationDocumentsDirectory();
    var firstPath = "${documentDirectory.path}/Pictures";
    var filePathAndName = '${documentDirectory.path}/Pictures/$imageName';

    await Directory(firstPath).create(recursive: true);
    File file2 = new File(filePathAndName);
    file2.writeAsBytesSync(response.bodyBytes);
    setState(() {
      imageDevicePathList.add(filePathAndName);
    });
  }
}