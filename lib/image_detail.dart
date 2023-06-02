import 'package:bpjtteknik/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:sweetalert/sweetalert.dart';

class ImageDetail extends StatefulWidget {
  final imageWidget;
  final imageUrl;

  ImageDetail({
    this.imageWidget,
    this.imageUrl,
  });

  @override
  _ImageDetailState createState() => _ImageDetailState();
}

class _ImageDetailState extends State<ImageDetail> {
  @override
  initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
  }

  @override
  void dispose() {
    //SystemChrome.restoreSystemUIOverlays();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perbesar Gambar'),
        backgroundColor: colorPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              child: Center(
                child: Hero(
                  tag: 'imageHero',
                  child: PinchZoomImage(
                    image: widget.imageWidget,
                    zoomedBackgroundColor: Color.fromRGBO(240, 240, 240, 1.0),
                    hideStatusBarWhileZooming: false,
                    onZoomStart: () {
                      print('Zoom started');
                    },
                    onZoomEnd: () {
                      print('Zoom finished');
                    },
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
          Container(
            child: FlatButton(
              color: Colors.teal,
              child: new Text("Unduh Gambar", style: TextStyle(color: Colors.white),),
              onPressed: () async {
                GallerySaver.saveImage(widget.imageUrl).then((bool success) {
                  SweetAlert.show(context,
                    title: "Sukses",
                    subtitle: "Berhasil Di unduh",
                    style: SweetAlertStyle.success,
                    onPress: (bool isConfirm) {
                      return true;
                    }
                  );
                });
              },
            ),
          ),
        ],
      )
    );
  }
}