import 'package:bpjt_k_gis_mobile_master/image_detail.dart';
import 'package:bpjt_k_gis_mobile_master/pdf_viewer.dart';
import 'package:bpjt_k_gis_mobile_master/utils/utils.dart';
import 'package:carousel_pro_nullsafety/carousel_pro_nullsafety.dart';
// import 'package:carousel_pro/carousel_pro.dart';
import 'package:flutter/material.dart';
import 'package:bpjt_k_gis_mobile_master/helper/main_helper.dart';

class AttendanceDetailPage extends StatefulWidget {
  final id;
  final userId;
  final name;
  final companyField;
  final phone;
  final email;
  final position;
  final time;
  final filename;
  final filepath;
  final long;
  final lat;
  final status;
  final note;
  final identifier;
  final createdAt;
  final updatedAt;
  final userSegment;

  AttendanceDetailPage({
    this.id,
    this.userId,
    this.name,
    this.companyField,
    this.phone,
    this.email,
    this.position,
    this.time,
    this.filename,
    this.filepath,
    this.long,
    this.lat,
    this.status,
    this.note,
    this.identifier,
    this.createdAt,
    this.updatedAt,
    this.userSegment
  });

  @override
  _AttendanceDetailPageState createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends State<AttendanceDetailPage> {
  var onlyImageList = [];
  var pdfList = [];
  var imagePathList = [];

  Future onlyImage(String filepath, String filename) async {
    // for(var i = 0; i < imageList.length; i++){
      if(filepath == null || filepath == "") {
        filepath = "storage/app/media/activities";
      }
      if (!(filename).contains(".pdf") && !(filename).contains(".doc") && !(filename).contains(".docx")) {
        onlyImageList.add(Image.network("http://103.6.53.254:13480/bpjt-teknik/public$filepath/$filename"));
        imagePathList.add("http://103.6.53.254:13480/bpjt-teknik/public$filepath/$filename");
        pdfList.add("");
      } else {
        onlyImageList.add(Image.asset("assets/images/pdf_placeholder.png"));
        imagePathList.add("");
        pdfList.add("http://103.6.53.254:13480/bpjt-teknik/public$filepath/$filename");
      }
    // }
  }


  @override
  void initState() {
    super.initState();
    onlyImage(widget.filepath, widget.filename);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Absensi'),
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
        images: onlyImageList,
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
                    Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(date(DateTime.parse(widget.time)), style: const TextStyle(fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ruas :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.userSegment == null || widget.userSegment == "" ? '-' : widget.userSegment)
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jabatan :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.position ?? '-')
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}