import 'package:art_sweetalert/art_sweetalert.dart';
import 'package:bpjt_k_gis_mobile_master/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
// import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
// import 'package:sweetalert/sweetalert.dart';

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    super.initState();
  }

  @override
  void dispose() {
    //SystemChrome.restoreSystemUIOverlays();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perbesar Gambar'),
        backgroundColor: colorPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              child: Center(
                child: Hero(
                  tag: 'imageHero',
                  child: PinchZoom(
                    // zoomedBackgroundColor: Color.fromRGBO(240, 240, 240, 1.0),
                    // hideStatusBarWhileZooming: false,
                    onZoomStart: () {print('Zoom started');},
                    onZoomEnd: () {print('Zoom finished');},
                    child: Image.network(widget.imageWidget),
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
          Container(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal,),
              child: const Text("Unduh Gambar", style: TextStyle(color: Colors.white),),
              onPressed: () async {
                GallerySaver.saveImage(widget.imageUrl).then((bool? success) async{
                  await ArtSweetAlert.show(
                      context: context,
                      artDialogArgs: ArtDialogArgs(
                        type: ArtSweetAlertType.success,
                        title: "Sukses",
                        text: "Berhasil Di unduh",
                      )
                      // title: "Sukses",
                      // subtitle: "Berhasil Di unduh",
                      // style: SweetAlertStyle.success,
                      // onPress: (bool isConfirm) {
                      //   return true;
                      // },
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