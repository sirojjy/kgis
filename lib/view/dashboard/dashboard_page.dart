import 'dart:async';
import 'dart:convert';

import 'package:bpjt_k_gis_mobile_master/conn/API.dart';
import 'package:bpjt_k_gis_mobile_master/drawer.dart';
import 'package:bpjt_k_gis_mobile_master/helper/main_helper.dart';
import 'package:bpjt_k_gis_mobile_master/library/new_version.dart';
import 'package:bpjt_k_gis_mobile_master/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
// import 'package:latlong/latlong.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:package_info/package_info.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:search_choices/search_choices.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sweetalert/sweetalert.dart';

class DashboardPage extends StatefulWidget {
  static const String route = 'custom_crs';

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey _mapKey = GlobalKey();
  
  late MapController mapController;

  late StateSetter _setStateInsideFilter;

  late int width;
  late int height;
  
  bool mapReady = false;
  bool isRuler = false;

  late Position _position;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  var prefMapType;
  var prefPosition;
  bool prefIsTrack = false;

  List prefSegments = [];

  List _segmentRegion = [];
  List _segment = [];
  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];
  late List<String> basemapLayers;

  late String basemap;
  late String appName;
  late String packageName;
  late String version;
  late String buildNumber;

  String? _selectedStatus;
  String? _selectedSubStatus;
  String? _selectedRegion;
  String? _selectedSegment;

  String _currentLayer = "";

  List<Marker> distanceMarker = [];
  List<Polyline> distanceLine = [];
  List<LatLng> distancePoint = [];

  double distanceInMeter = 0.00;

  _calculateDistance() async {
    if (distanceMarker.length > 1) {
      distanceLine.add(
        Polyline(
          points: distancePoint,
          strokeWidth: 4,
          color: Colors.amber,
        ),
      );

      LatLng originPoint = distancePoint[distancePoint.length - 2];
      LatLng destPoint = distancePoint[distancePoint.length - 1];

      await API.measureDistance(originPoint.latitude.toString(), originPoint.longitude.toString(), destPoint.latitude.toString(), destPoint.longitude.toString()).then((response) {
        if (!mounted) return;
        
        if (response != null) {
          if (response['status'] == 'success') {
            setState(() {
              distanceInMeter = (distanceInMeter + response['data']['meters']);
            });
          }
        }
      });
    }
  }

  _getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }
   _getBaseMap(String map) async {
     if (!mounted) return;
      setState(() {
        basemap = baseMap(map);
      });
  }

  _getBaseMapLayers(String map) async {
    if (!mounted) return;
    setState(() {
      basemapLayers = baseMapLayers(map);
    });
  }

  proj4.Point point = proj4.Point(x: -7.39139558847656, y: 111.07967376708984);

   _getCurrentPosition() async {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _position = position;
        point = proj4.Point(x: position.latitude, y: position.longitude);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (position.latitude != null && position.longitude != null) {
            mapController.move(LatLng(position.latitude, position.longitude), mapController.zoom);
          }
        });
      });
  }

  @override
  void initState() {
    print("HALOO");
    // // Instantiate NewVersion manager object (Using GCP Console app as example)
    // final newVersion = NewVersion(
    //   iOSId: 'id.go.pu.bpjt.kgis',
    //   androidId: 'id.go.pu.bpjt.kgis',
    //   iOSAppStoreCountry: 'ID',
    // );
    // // You can let the plugin handle fetching the status and showing a dialog,
    // // or you can fetch the status and display your own dialog, or no dialog.
    // const simpleBehavior = false;

    // if (simpleBehavior) {
    //   // basicStatusCheck(newVersion);
    // } else {
    //   advancedStatusCheck(newVersion);
    // }
    
    mapController = MapController();
    
    _getCurrentPosition();
    _addLocationStream();

    _getInfo().then((resInfo) {
      _getPref().then((res) {
        _getBaseMap("wmsAltOne");
        if (prefMapType == null) {
          _getBaseMapLayers("osm");
        } else {
          _getBaseMapLayers(prefMapType);
        }
      });

      _listSegmentRegion();
    });

    super.initState();
  }

  advancedStatusCheck(NewVersion newVersion) async {
    final status = await newVersion.getVersionStatus();
    print(status.localVersion);
    print(status.storeVersion);
    if (status != null) {
      if (status.localVersion != status.storeVersion) {
        debugPrint(status.releaseNotes);
        debugPrint(status.appStoreLink);
        debugPrint(status.localVersion);
        debugPrint(status.storeVersion);
        debugPrint(status.canUpdate.toString());
        newVersion.showUpdateDialog(
          context: context,
          versionStatus: status,
          dialogTitle: 'Versi Baru Tersedia',
          dialogText: 'Update Changelog : \n${status.releaseNotes.replaceAll("<br>", "\n")}',
          allowDismissal: false, dismissAction: () { return; }
        );
      }
    }
  }

  _listSegmentRegion() async {
    await API.getSegmentRegion("", "", version).then((response) {
      if (!mounted) return;
      showUpdateAppsModal(context, response);
      setState(() {
        _segmentRegion = response;
      });
    });
  }

  _listSegment(String status, String subStatus, String region) async {
    await API.getSegment(status, subStatus, region, "true", version).then((response) {
      if (!mounted) return;      
      _setStateInsideFilter(() {
        if (prefCompanyField == "PMI") {
          _segment.clear();
          for(var i = 0; i < response.length; i++){
              if (prefSegments.contains(response[i])) {
                _segment.add(response[i]);
              }
          }
        } else {
          _segment = response;
        }
      });
    });
  }

  _addLocationStream() {
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.high, distanceFilter: 10)
        .listen((Position position) {
      if (!mounted) return;
      setState(() {
        _position = position;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (position.latitude != null && position.longitude != null && prefIsTrack) {
            mapController.move(LatLng(position.latitude, position.longitude), mapController.zoom);
          }
        });
        // if (position.latitude != null && position.longitude != null && mapController.ready && prefIsTrack) {
        //   mapController.move(LatLng(position.latitude, position.longitude), mapController.zoom);
        // }
      });
    });
    _streamSubscriptions.add(positionStream);
  }
  
  void _submit() async {
    await API.getMapService("", "", _selectedRegion!, _selectedSegment!, version).then((response) {
      if (!mounted) return;
        if (response.length > 0) {
          _currentLayer = response[0]["nama_layer"];

          mapController.move(LatLng(double.parse(response[0]["center_latitude"]), double.parse(response[0]["center_longitude"])), 10.0);
        }
        setState(() {});
    });
  }

  _filterSegment(context) async {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25)
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            _setStateInsideFilter = setState;

            return
            SizedBox(
              height: height * 0.42,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ListView(
                  children: [
                    const SizedBox(height: 30.0),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: const Text("Silahkan Filter Untuk Menampilkan Peta", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),)
                    ),
                    const SizedBox(height: 30.0),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: const Text("Region")
                    ),
                    ListTile(
                      title: DropdownButton(
                        isExpanded: true,
                        hint: const Row(
                          children: <Widget>[
                            Text('Pilih Region'),
                          ],
                        ),
                        items: _segmentRegion.map((item) {
                          return DropdownMenuItem(
                            value: item.toString(),
                            child: FittedBox(
                                fit: BoxFit.contain,
                                child: Text(item, style: const TextStyle(fontSize: 13.0, color: Colors.black),)
                            )
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          _listSegment(_selectedStatus!, _selectedSubStatus!, newVal!);

                          setState(() {
                            _selectedSegment = null;
                            _selectedRegion = newVal;
                          });
                        },
                        value: _selectedRegion,
                        underline: Container(color:Colors.black, height:0.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: const Text("Ruas")
                    ),
                    ListTile(
                      title: SearchChoices.single(
                        items: _segment.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: FittedBox(
                                fit: BoxFit.contain,
                                child: Text(item, style: const TextStyle(fontSize: 12.0, color: Colors.black),)
                            )
                          );
                        }).toList(),
                        selectedValueWidgetFn: (item) {
                          if (_selectedSegment == null) {
                            return Container(
                              transform: Matrix4.translationValues(-10,0,0),
                              alignment: Alignment.centerLeft,
                              child: const Text("", style: TextStyle(fontSize: 12.0, color: Colors.black),)
                            );
                          } else {
                            return Container(
                              transform: Matrix4.translationValues(-10,0,0),
                              alignment: Alignment.centerLeft,
                              child: Text(item, style: const TextStyle(fontSize: 12.0, color: Colors.black),)
                            );
                          }
                        },
                        hint: Container(
                          transform: Matrix4.translationValues(-10,0,0),
                          child: const Text("Pilih Ruas", style: TextStyle(color: Colors.black),)
                        ),
                        searchHint: "Pilih Ruas",
                        onChanged: (newVal) {
                          setState(() {
                            _selectedSegment = newVal;
                          });
                        },
                        value: _selectedSegment,
                        isExpanded: true,
                        displayClearIcon: false,
                        underline: Container(color:Colors.black, height:0.5),
                        icon: Container(
                          transform: Matrix4.translationValues(10,0,0),
                          child: const Icon(Icons.arrow_drop_down)
                        ),
                      ),
                    ),
                    Container(
                      // width: MediaQuery.of(context).size.width * 0.8,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0.8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.all(12),
                          backgroundColor: colorPrimary,
                        ),
                        onPressed: () {
                          _submit();
                          Navigator.pop(context);
                        },
                        child: const Text('SUBMIT', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              )
            );
          },
        );
      }
    );
  }

  Future<Widget> _getFeatureInfo(context, proj4.Point coord) async {
    var north = mapController.bounds?.north;
    var east  = mapController.bounds?.east;
    var south = mapController.bounds?.south;
    var west = mapController.bounds?.west;
    var mapWidth = _mapKey.currentContext?.size?.width.toInt();
    var mapHeight = _mapKey.currentContext?.size?.height.toInt();

    print("West : $west");
    print("South : $south");
    print("East : $east");
    print("North : $north");
    print("Width : $mapWidth");
    print("Height : $mapHeight");
    print("Coord X : ${coord.y}");
    print("Coord Y : ${coord.x}");
    print("http://simk.bpjt.pu.go.id/kgis/index.php/wms/info/${_currentLayer}/$west~$south~$east~$north/$mapWidth/$mapHeight/${coord.y}/${coord.x}");
    
    await API.getFeatureInfo("http://simk.bpjt.pu.go.id/kgis/index.php/wms/info/${_currentLayer}/$west~$south~$east~$north/$mapWidth/$mapHeight/${coord.y}/${coord.x}").then((response) {
      if (!mounted) return Container();
      print("Response From Server :");
      print(response['data']);
      print("======================");
      if (response['data'] != null) {
        Alert(
            context: context,
            type: AlertType.info,
            title: (response['data']["nama"] == null ? "-" : response['data']["nama"]),
            desc: (response['data']["sta_km"] == null ? "-" : response['data']["sta_km"]),
            buttons: [
              DialogButton(
                child: const Text("OK"),
                onPressed: () {
                  return;
                },
              )
            ]
        );
        ///>>>
      }
    });
    return Container();
  }
  // SweetAlert.show(context,
  //   title: (response['data']["nama"] == null ? "-" : response['data']["nama"]),
  //   subtitle: (response['data']["sta_km"] == null ? "-" : response['data']["sta_km"])
  // );

  // return InfoMarkerPopup(info: response['data']);
  // showModalBottomSheet<void>(
  //   context: context,
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadius.only(
  //       topLeft: Radius.circular(25),
  //       topRight: Radius.circular(25)
  //     ),
  //   ),
  //   builder: (BuildContext context) {
  //     return Container(
  //       height: height * 0.40,
  //       child: Padding(
  //         padding: EdgeInsets.all(10.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             SizedBox(height: 25.0),
  //             Center(
  //               child: Text("Ruas : ${response['data']['ruas']}", style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
  //             ),
  //             // Center(
  //             //   child: Text("STA : ${response['data']['sta'] ?? '-'}", style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
  //             // ),
  //             response['data']['jenis'] != null ?
  //               Center(
  //                 child: Text("Jenis : ${response['data']['jenis']}", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
  //               )
  //             :
  //               Container(),
  //             SizedBox(height: 25.0),
  //             Text("Nama : ${response['data']['nama']}", style: TextStyle(fontSize: 15.0)),
  //             Text("STA : ${response['data']['sta']}", style: TextStyle(fontSize: 15.0)),
  //             Text("Region : ${response['data']['region']}", style: TextStyle(fontSize: 15.0)),
  //             Text("BUJT : ${response['data']['bujt']}", style: TextStyle(fontSize: 15.0)),
  //             Text("Kode : ${response['data']['kodefikasi']}", style: TextStyle(fontSize: 15.0)),
  //             Text("Status : ${response['data']['status']}", style: TextStyle(fontSize: 15.0)),
  //             Text("Sub Status : ${response['data']['sub_status']}", style: TextStyle(fontSize: 15.0)),
  //           ],
  //         )
  //       )
  //     );
  //   }
  // );

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
    prefSegments = prefs.getString('segments') != null ? jsonDecode(prefs.getString('segments')!) : null;
    prefMapType = prefs.getString('map_type');
    prefPosition = prefs.getString('position');
    prefIsTrack = prefs.getBool('is_track') ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width.toInt();
    height = MediaQuery.of(context).size.height.toInt();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mapReady) {
        setState(() {
          mapReady = true;
          mapController.move(LatLng(_position.latitude, _position.longitude), mapController.zoom);
        });
      } else {
        print("MAP READY");
      }
    });
    
    // mapController.onReady.then((value) {
    //   if (!mapReady) {
    //     setState(() {
    //       mapReady = true;
    //       mapController.move(LatLng(_position.latitude, _position.longitude), mapController.zoom);
    //     });
    //   } else {
    //     print("MAP READY");
    //   }
    // });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        backgroundColor: colorPrimary,
        actions: [
          Visibility(
            visible: isRuler,
            child: GestureDetector(
              onTap: () async {
                setState(() {
                  distanceMarker.clear();
                  distancePoint.clear();
                  distanceInMeter = 0.00;
                });
              },
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 10.0),
                    child: const Icon(Icons.delete)
                  ),
                ],
              )
            ),
          ),
          GestureDetector(
            onTap: () async {
              setState(() {
                isRuler = !isRuler;
                distanceMarker.clear();
                distancePoint.clear();
                distanceInMeter = 0.00;
              });
            },
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 10.0),
                  child: const Icon(Icons.architecture),
                ),
              ],
            )
          ),
          Visibility(
            visible: prefCompanyField == 'PMI' || prefCompanyField == 'PMO' || prefCompanyField == 'BPJT' ? true : false,
            child: GestureDetector(
              onTap: () async {
                _filterSegment(context);
                setState(() {
                  // if (isSearch) {
                  //   isSearch = false;
                  // } else {
                  //   isSearch = true;
                  // }
                  // isReset = true;
                });
              },
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 10.0),
                    child: const Icon(Icons.layers),
                  ),
                ],
              )
            ),
          ),
        ],
      ),
      drawer: DrawerBuild().drw(context, prefCompanyField),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _position == null ?
        Center(
          child: Container(
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 5.0),
                Text('Memuat Peta, Harap Menunggu...', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11.0))
              ],
            )
          ),
        )
        :
        Column(
          children: [
            Flexible(
              child: FlutterMap(
                key: _mapKey,
                mapController: mapController,
                options: MapOptions(
                  crs: const Epsg4326(),
                  center: LatLng(point.x, point.y),
                  zoom: 12,
                  onTap: (tapPosition, latLng) => setState(() {
                    point = proj4.Point(x: latLng.latitude, y: latLng.longitude);
                    if (isRuler) {
                      distancePoint.add(LatLng(latLng.latitude, latLng.longitude));
                      distanceMarker.add(Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(latLng.latitude, latLng.longitude),
                        builder: (ctx) =>
                        const Icon(Icons.location_on_outlined, color: Colors.red,),
                      ));
                      _calculateDistance();
                    } else {
                      _getFeatureInfo(context, point);
                    }
                  }),
                ),
                children: [
                  TileLayer(
                    wmsOptions: WMSTileLayerOptions(
                      crs: const Epsg4326(),
                      baseUrl: basemap,
                      layers: basemapLayers
                      // 'https://tiles.maps.eox.at/?'
                      // ['osm'],
                      // s2cloudless-2020
                    ),
                  ),
                  TileLayer(
                    backgroundColor: Colors.transparent,
                    wmsOptions: WMSTileLayerOptions(
                      crs: const Epsg4326(),
                      transparent: true,
                      format: 'image/png',
                      baseUrl: 'http://simk.bpjt.pu.go.id/geoserver/bpjt/wms?',
                      layers: [_currentLayer],
                    ),
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(_position.latitude, _position.longitude),
                        builder: (ctx) =>
                        Container(
                          child: const Icon(MdiIcons.checkboxBlankCircle, color: Colors.lightBlue, size: 15.0),
                        ),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: distanceMarker,
                  ),
                  PolylineLayer(
                    polylines: distanceLine
                  )
                ],
              )
            ),
            Visibility(
              visible: isRuler,
              child: Container(
                child: Text('Jarak : ${distanceInMeter.ceil().toString()} m', style: const TextStyle(fontSize: 21.0),),
              )
            )
          ],
        ),
      ),
      floatingActionButton: _getFAB(),
      // floatingActionButton: FloatingActionButton(
      //   heroTag: "btn2",
      //   child: Icon(
      //     Icons.gps_fixed,
      //     color: Colors.white,
      //   ),
      //   onPressed: () {
      //     setState(() {
      //       mapController.move(LatLng(_position.latitude, _position.longitude), mapController.zoom);
      //     });
      //   },
      //   backgroundColor: HexColor("#374774"),
      // ),
    );
  }

    Widget _getFAB() {
      return SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22),
        backgroundColor: Colors.white,
        visible: true,
        curve: Curves.bounceIn,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.my_location),
            backgroundColor: Colors.white,
            onTap: () async { 
              mapController.move(LatLng(_position.latitude, _position.longitude), mapController.zoom);
            },
            label: 'Posisi Saya',
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: colorPrimary
          ),
          SpeedDialChild(
            child: const Icon(Icons.map_outlined),
            backgroundColor: Colors.white,
            onTap: () async { 
              SharedPreferences preferences = await SharedPreferences.getInstance();
              preferences.setString('map_type', "google");
              Phoenix.rebirth(context);
            },
            label: 'Google Basemap',
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: colorPrimary
          ),
          SpeedDialChild(
            child: const Icon(Icons.map_outlined),
            backgroundColor: Colors.white,
            onTap: () async { 
              SharedPreferences preferences = await SharedPreferences.getInstance();
              preferences.setString('map_type', "osm");
              Phoenix.rebirth(context);
            },
            label: 'OSM Basemap',
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: colorPrimary
          ),
          SpeedDialChild(
            child: Icon(prefIsTrack ? Icons.toggle_off : Icons.toggle_on),
            backgroundColor: Colors.white,
            onTap: () async { 
              SharedPreferences preferences = await SharedPreferences.getInstance();
              if (prefIsTrack) {
                preferences.setBool('is_track', false);
              } else {
                preferences.setBool('is_track', true);
              }

              Phoenix.rebirth(context);
            },
            label: prefIsTrack ? 'Off Tracking' : 'On Tracking',
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: colorPrimary
          ),
        ],
      );
    }
}

class InfoMarkerPopup extends StatelessWidget {
  const InfoMarkerPopup({required Key key, this.info}) : super(key: key);
  // final Info info;
  final dynamic info;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Colors.white.withOpacity(0.8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(info['nama']),
              Text(info['sta_km']),
            ],
          ),
        )
      ),
    );
  }
}