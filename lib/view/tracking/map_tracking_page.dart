import 'dart:async';
import 'dart:convert';

import 'package:bpjtteknik/conn/API.dart';
import 'package:bpjtteknik/drawer.dart';
import 'package:bpjtteknik/helper/main_helper.dart';
import 'package:bpjtteknik/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';
import 'package:package_info/package_info.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart' as clstr;
import 'package:search_choices/search_choices.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapTrackingPage extends StatefulWidget {
  final long;
  final lat;

  MapTrackingPage({
    this.long,
    this.lat
  });
  
  static const String route = 'custom_crs';

  @override
  _MapTrackingPageState createState() => _MapTrackingPageState();
}

class _MapTrackingPageState extends State<MapTrackingPage> {
  final GlobalKey _mapKey = GlobalKey();
  final clstr.PopupController _popupController = clstr.PopupController();

  MapController mapController;

  StateSetter _setStateInsideFilter;

  bool mapReady = false;

  int width;
  int height;

  Position _position;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  List prefSegments = List();
  var prefMapType;
  var prefPosition;

  var _trackingProblems = [];

  List tappedPoints = [];
  List _segmentRegion = List();
  List _segment = List();
  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];

  String appName;
  String packageName;
  String version;
  String buildNumber;

  String _selectedStatus;
  String _selectedSubStatus;
  String _selectedRegion;
  String _selectedSegment;

  String _currentLayer = "";
  
  _getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }
  
  proj4.Point point = proj4.Point(x: -7.39139558847656, y: 111.07967376708984);

  Future<void> _getAllTrackingProblems() async {
    await API.getAllTrackingProblems("", _selectedSegment, "", "", "", version).then((response) {
      if (!mounted) return;
      setState(() {
        if (response != null) {
          if (response["data"].length > 0) {
            _trackingProblems.addAll(response["data"]);
          }
        }

        for(var x = 0; x < _trackingProblems.length; x++) {
          // tappedPoints.add(LatLng(double.parse(_trackingProblems[x]["lat"]), double.parse(_trackingProblems[x]["long"])));
          tappedPoints.add({"lat": double.parse(_trackingProblems[x]["lat"]), "long": double.parse(_trackingProblems[x]["long"]), "problem_details": _trackingProblems[x]["problem"], "date": _trackingProblems[x]["date"], "photo": _trackingProblems[x]["filepath"]+"/"+_trackingProblems[x]["filename"]});
        }
      });
    });
  }

   _getCurrentPosition() async {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _position = position;
        point = proj4.Point(x: position.latitude, y: position.longitude);
        if (position.latitude != null && position.longitude != null && mapController.ready) {
          mapController.move(LatLng(position.latitude, position.longitude), mapController.zoom);
        }
      });
  }

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _getCurrentPosition();
    _addLocationStream();

    _getInfo().then((resInfo) {
      _getPref().then((res) {
        _getAllTrackingProblems();
      });

      _listSegmentRegion();
    });
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
        if (position.latitude != null && position.longitude != null && mapController.ready) {
          mapController.move(LatLng(position.latitude, position.longitude), mapController.zoom);
        }
      });
    });
    _streamSubscriptions.add(positionStream);
  }
  
  void _submit() async {
    await API.getMapService("", "", _selectedRegion, _selectedSegment, version).then((response) {
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
      shape: RoundedRectangleBorder(
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
            Container(
              height: height * 0.42,
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: ListView(
                  children: [
                    SizedBox(height: 30.0),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text("Silahkan Filter Untuk Menampilkan Peta", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),)
                    ),
                    SizedBox(height: 30.0),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text("Region")
                    ),
                    Container(
                      child: ListTile(
                        title: DropdownButton(
                          isExpanded: true,
                          hint: Row(
                            children: <Widget>[
                              Text('Pilih Region'),
                            ],
                          ),
                          items: _segmentRegion.map((item) {
                            return DropdownMenuItem(
                              value: item.toString(),
                              child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Text(item, style: TextStyle(fontSize: 13.0, color: Colors.black),)
                              )
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            _listSegment(_selectedStatus, _selectedSubStatus, newVal);
                            
                            setState(() {
                              _selectedSegment = null;
                              _selectedRegion = newVal;
                            });
                          },
                          value: _selectedRegion,
                          underline: Container(color:Colors.black, height:0.5),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text("Ruas")
                    ),
                    Container(
                      child: ListTile(
                        title: SearchChoices.single(
                          items: _segment.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Text(item, style: TextStyle(fontSize: 12.0, color: Colors.black),)
                              )
                            );
                          }).toList(),
                          selectedValueWidgetFn: (item) {
                            if (_selectedSegment == null) {
                              return Container(
                                transform: Matrix4.translationValues(-10,0,0),
                                alignment: Alignment.centerLeft,
                                child: Text("", style: TextStyle(fontSize: 12.0, color: Colors.black),)
                              );
                            } else {
                              return Container(
                                transform: Matrix4.translationValues(-10,0,0),
                                alignment: Alignment.centerLeft,
                                child: Text(item, style: TextStyle(fontSize: 12.0, color: Colors.black),)
                              );
                            }
                          },
                          hint: Container(
                            transform: Matrix4.translationValues(-10,0,0),
                            child: Text("Pilih Ruas", style: TextStyle(color: Colors.black),)
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
                            child: Icon(Icons.arrow_drop_down)
                          ),
                        ),
                      ),
                    ),
                    Container(
                      // width: MediaQuery.of(context).size.width * 0.8,
                      child: RaisedButton(
                        elevation: 0.8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        onPressed: () {
                          _submit();
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.all(12),
                        color: colorPrimary,
                        child: Text('SUBMIT', style: TextStyle(color: Colors.white)),
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

  _getFeatureInfo(context, proj4.Point coord) async {
    var north = mapController.bounds.north;
    var east  = mapController.bounds.east;
    var south = mapController.bounds.south;
    var west = mapController.bounds.west;
    var mapWidth = _mapKey.currentContext.size.width.toInt();
    var mapHeight = _mapKey.currentContext.size.height.toInt();

    print("West : $west");
    print("South : $south");
    print("East : $east");
    print("North : $north");
    print("Width : $mapWidth");
    print("Height : $mapHeight");
    print("Coord X : ${coord.y}");
    print("Coord Y : ${coord.x}");
    print("http://103.6.53.254:13480/kgis/index.php/wms/info/${_currentLayer}/$west~$south~$east~$north/$mapWidth/$mapHeight/${coord.y}/${coord.x}");
    
    await API.getFeatureInfo("http://103.6.53.254:13480/kgis/index.php/wms/info/${_currentLayer}/$west~$south~$east~$north/$mapWidth/$mapHeight/${coord.y}/${coord.x}").then((response) {
      if (!mounted) return;
      print("Response From Server :");
      print(response['data']);
      print("======================");
      if (response['data'] != null) {
        showModalBottomSheet<void>(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25)
            ),
          ),
          builder: (BuildContext context) {
            return Container(
              height: height * 0.40,
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 25.0),
                    Center(
                      child: Text("Ruas : ${response['data']['ruas']}", style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                    response['data']['jenis'] != null ?
                      Center(
                        child: Text("Jenis : ${response['data']['jenis']}", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      )
                    :
                      Container(),
                    SizedBox(height: 25.0),
                    Text("Nama : ${response['data']['nama']}", style: TextStyle(fontSize: 15.0)),
                    Text("STA : ${response['data']['sta']}", style: TextStyle(fontSize: 15.0)),
                    Text("Region : ${response['data']['region']}", style: TextStyle(fontSize: 15.0)),
                    Text("BUJT : ${response['data']['bujt']}", style: TextStyle(fontSize: 15.0)),
                    Text("Kode : ${response['data']['kodefikasi']}", style: TextStyle(fontSize: 15.0)),
                    Text("Status : ${response['data']['status']}", style: TextStyle(fontSize: 15.0)),
                    Text("Sub Status : ${response['data']['sub_status']}", style: TextStyle(fontSize: 15.0)),
                  ],
                )
              )
            );
          }
        );
      }
    });
  }

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
    prefSegments = prefs.getString('segments') != null ? jsonDecode(prefs.getString('segments')) : null;
    prefMapType = prefs.getString('map_type');
    prefPosition = prefs.getString('position');
  }
  
  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width.toInt();
    height = MediaQuery.of(context).size.height.toInt();
    
    mapController.onReady.then((value) {
      if (!mapReady) {
        setState(() {
          mapReady = true;
          mapController.move(LatLng(_position.latitude, _position.longitude), mapController.zoom);
        });
      } else {
        print("MAP READY");
      }
    });
    
    var markers = tappedPoints.map((latlng) {
      return ProblemMarker(
        problem: Problem(
          name: latlng["problem_details"] == null ? '-' : latlng["problem_details"],
          imagePath:
              'http://103.6.53.254:13480/bpjt-teknik/public'+latlng["photo"],
          lat: latlng["lat"],
          long: latlng["long"],
          date: latlng["date"]
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Map Tracking'),
        backgroundColor: colorPrimary,
        actions: [
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
                    child: Icon(Icons.layers),
                  ),
                ],
              )
            ),
          )
        ],
      ),
      drawer: DrawerBuild().drw(context, prefCompanyField),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: _position == null ?
        Center(
          child: Container(
            child: Column(
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
                  crs: Epsg4326(),
                  center: LatLng(point.x, point.y),
                  zoom: 12,
                  plugins: [
                    // MyCustomPlugin(),
                    // ScaleLayerPlugin(),
                    clstr.MarkerClusterPlugin(),
                    // ZoomButtonsPlugin(),
                  ],
                  onTap: (p) => setState(() {
                    _popupController.hidePopup();
                    point = proj4.Point(x: p.latitude, y: p.longitude);
                    _getFeatureInfo(context, point);
                  }),
                ),
                layers: [
                  // TileLayerOptions(
                  //   wmsOptions: WMSTileLayerOptions(
                  //     crs: Epsg4326(),
                  //     baseUrl: 'https://tiles.maps.eox.at/?',
                  //     layers: ['s2cloudless-2019', 'overlay_base'],
                  //   ),
                  // ),
                  TileLayerOptions(
                    wmsOptions: WMSTileLayerOptions(
                      crs: Epsg4326(),
                      baseUrl: 'https://tiles.maps.eox.at/?',
                      layers: ['osm'],
                    ),
                  ),

                  TileLayerOptions(
                    backgroundColor: Colors.transparent,
                    wmsOptions: WMSTileLayerOptions(
                      crs: Epsg4326(),
                      transparent: true,
                      format: 'image/png',
                      baseUrl: 'http://103.6.53.254:13480/geoserver/bpjt/wms?',
                      layers: [_currentLayer],
                    ),
                  ),
                  MarkerLayerOptions(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(_position.latitude, _position.longitude),
                        builder: (ctx) =>
                        Container(
                          child: Icon(Icons.my_location, color: Colors.red,),
                        ),
                      ),
                    ],
                  ),

                  clstr.MarkerClusterLayerOptions(
                    maxClusterRadius: 120,
                    disableClusteringAtZoom: 9,
                    size: Size(40, 40),
                    anchor: AnchorPos.align(AnchorAlign.center),
                    fitBoundsOptions: FitBoundsOptions(
                      padding: EdgeInsets.all(50),
                    ),
                    markers: markers,
                    polygonOptions: clstr.PolygonOptions(
                      borderColor: Colors.blueAccent,
                      color: Colors.black12,
                      borderStrokeWidth: 3
                    ),
                    popupOptions: clstr.PopupOptions(
                      popupSnap: clstr.PopupSnap.top,
                      popupController: _popupController,
                      popupBuilder: (_, Marker marker) {
                        if (marker is ProblemMarker) {
                          return ProblemMarkerPopup(problem: marker.problem);
                        }
                        return Card(child: const Text('Not a monument'));
                      },
                    ),
                    builder: (context, markers) {
                      return FloatingActionButton(
                        child: Text(markers.length.toString()),
                        onPressed: null,
                      );
                    },
                  ),
                ],
              )
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn2",
        child: Icon(
          Icons.gps_fixed,
          color: Colors.white,
        ),
        onPressed: () {
          setState(() {
            mapController.move(LatLng(_position.latitude, _position.longitude), mapController.zoom);
          });
        },
        backgroundColor: HexColor("#374774"),
      ),
    );
  }
}

class Problem {
  static const double size = 30;

  Problem({this.name, this.date, this.imagePath, this.problem, this.lat, this.long});

  final String name;
  final String date;
  final String imagePath;
  final String problem;
  final double lat;
  final double long;
}

class ProblemMarker extends Marker {
  ProblemMarker({@required this.problem})
      : super(
          anchorPos: AnchorPos.align(AnchorAlign.top),
          height: Problem.size,
          width: Problem.size,
          point: LatLng(problem.lat, problem.long),
          builder: (BuildContext ctx) => Icon(Icons.location_on, color: Colors.red,),
        );

  final Problem problem;
}

class ProblemMarkerPopup extends StatelessWidget {
  const ProblemMarkerPopup({Key key, this.problem}) : super(key: key);
  final Problem problem;

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
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.network(problem.imagePath, height: 100),
              Text(problem.date),
              Text(problem.name),
              Text('${problem.lat}-${problem.long}'),
            ],
          ),
        )
      ),
    );
  }
}