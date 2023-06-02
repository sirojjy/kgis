import 'dart:convert';

import 'package:bpjtteknik/conn/API.dart';
import 'package:bpjtteknik/helper/db.dart';
import 'package:bpjtteknik/helper/main_helper.dart';
import 'package:bpjtteknik/utils/colors.dart';
import 'package:bpjtteknik/utils/responsive_screen.dart';
import 'package:bpjtteknik/view/dashboard/dashboard_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:package_info/package_info.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'attendance_detail_page.dart';
import 'attendance_search_page.dart';

class AttendanceListPage extends StatefulWidget {
  final segment;
  final region;
  final position;
  final dateFrom;
  final dateTo;
  final name;

  AttendanceListPage({
    this.segment,
    this.region,
    this.position,
    this.dateFrom,
    this.dateTo,
    this.name
  });

  @override
  AttendanceListPageState createState() => AttendanceListPageState();
}

class AttendanceListPageState extends State<AttendanceListPage> {
  bool _loading = true;

  int totalData;
  int currentPage;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  var prefSegment;
  List prefSegments = List();
  
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  var _attendances = [];
  
  String appName;
  String packageName;
  String version;
  String buildNumber;

  _getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }
  
  Future<void> _getAttendance(bool isRefresh) async {
    String userId;
    if (prefCompanyField == "PMI" || prefCompanyField == "PMO") {
      userId = prefId;
    }

    if (isRefresh) {
      setState(() {
        currentPage = 1;
      });
    } else if (_attendances.length >= totalData) {
      return;
    }

    await API.getAttendances("", userId, widget.segment, widget.position, widget.dateFrom, widget.dateTo, currentPage, widget.name, widget.region, version).then((response) {
      if (!mounted) return;
      setState(() {
        if (response != null) {
          if (response["data"].length > 0) {
            totalData = response['nav']['totalData'];
            _attendances.addAll(response["data"]);
            currentPage = currentPage + 1;
          }
        }
      });
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
    prefSegment = prefs.getString('segment');
    prefSegments = jsonDecode(prefs.getString('segments'));
  }
  
  @override
  void initState() {
    super.initState();
    Db.syncToServer();
    _getInfo().then((resInfo) {
      _getPref().then((response) {
        _getAttendance(true).then((resAttendance) {
          if (!mounted) return;
          setState(() {
            _loading = false;
          });
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Absensi'),
        backgroundColor: colorPrimary,
        actions: [
          GestureDetector(
              onTap: () async {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => DashboardPage()));
              },
              child: Icon(Icons.home, color: Colors.white,),
          ),
          SizedBox(width: 10.0,),
          Container(
            margin: EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) => new AttendanceSearchPage(

                )));
              },
              child: Icon(Icons.search, color: Colors.white,),
            ),
          )
        ],
      ),
      body: ModalProgressHUD(
        child: _attendances.length < 1 ? noData() : 
          SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            header: WaterDropHeader(),
            footer: CustomFooter(
              builder: (BuildContext context,LoadStatus mode){
                Widget body ;
                if (mode == LoadStatus.idle) {
                  body =  Text("pull up load");
                } else if (mode == LoadStatus.loading) {
                  body =  CupertinoActivityIndicator();
                } else if (mode == LoadStatus.failed) {
                  body = Text("Load Failed! Click retry!");
                } else if (mode == LoadStatus.canLoading) {
                    body = Text("release to load more");
                } else {
                  body = Text("No more Data");
                }
                return Container(
                  height: 55.0,
                  child: Center(child:body),
                );
              },
            ),
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _attendances.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => {
                    if (!_attendances[index].isEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AttendanceDetailPage(
                            id: _attendances[index]['id'],
                            userId: _attendances[index]['user_id'],
                            name: _attendances[index]['name'],
                            phone: _attendances[index]['phone'],
                            email: _attendances[index]['email'],
                            position: _attendances[index]['position'],
                            time: _attendances[index]['time'],
                            filename: _attendances[index]['filename'],
                            filepath: _attendances[index]['filepath'],
                            long: _attendances[index]['long'],
                            lat: _attendances[index]['lat'],
                            status: _attendances[index]['status'],
                            note: _attendances[index]['note'],
                            identifier: _attendances[index]['identifier'],
                            createdAt: _attendances[index]['created_at'],
                            updatedAt: _attendances[index]['updated_at'],
                            userSegment: _attendances[index]['user_segment'],
                            companyField: prefCompanyField
                          )
                        )
                      )
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      color: colorSecondary,
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: Row(
                        children: <Widget>[
                          Container(
                            constraints: BoxConstraints(maxWidth: 125.0),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: displaySelectedFile(
                                _attendances[index]['filepath'], 
                                _attendances[index]['filename']
                              ),
                            )
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(left: 5.0),
                              decoration: BoxDecoration(
                                color: colorSecondary,
                              ),
                              child: Column(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(_attendances[index]["name"], style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(_attendances[index]["position"] ?? '-', style: TextStyle(color: Colors.white, fontSize: 14.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(_attendances[index]["user_segment"] ?? '-', style: TextStyle(color: Colors.white, fontSize: 14.0)),
                                    ),
                                  ),
                                  Divider(height: 7.0, color: Colors.white,),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text("Waktu Absen :", style: TextStyle(color: Colors.white, fontSize: 14.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(date(DateTime.parse(_attendances[index]["time"]).toLocal()), style: TextStyle(color: Colors.white, fontSize: 14.0)),
                                    ),
                                  ),
                                ],
                              ),
                            ) 
                          ),  
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        inAsyncCall: _loading,
      )
    );
  }

  void _onRefresh() async {
    _attendances.clear();
    // monitor network fetch
    await _getAttendance(true);
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    await _getAttendance(false);
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    if(mounted)
    setState(() {

    });
    _refreshController.loadComplete();
  }

  Widget displaySelectedFile(String path, String url) {
    if (path == null || path == "") {
      path = "storage/app/media/activities";
    }
    return SizedBox(
      height: 120.0,
      child: url == "/" || url == null
        ? Image.asset("assets/images/no_image_2.png")
        : (url.contains(".pdf") ? Column(children: <Widget>[Image.asset("assets/images/pdf_placeholder.png", width: 120.0,)]) : 
          Container(
            child: FadeInImage.assetNetwork(
                placeholder: 'assets/images/no_image_2.png',
                image: "http://103.6.53.254:13480/bpjt-teknik/public"+path+"/" + url,
                height: 115.0,
            )
          )
        ),
    );
  }

  Widget noData() {
    var size = Screen(MediaQuery.of(context).size);
    return Center(
      child: Container(
        width: size.getWidthPx(300),
        height: size.getWidthPx(300),
        child: Column(
          children: <Widget>[
            Container(
              foregroundDecoration: BoxDecoration(
                color: colorTertiary,
                backgroundBlendMode: BlendMode.saturation,
              ),
              child: Image.asset("assets/images/problem.png", height: size.getWidthPx(250)),
            ),
            Image.asset("assets/images/nodata.png", height: size.getWidthPx(50))
          ],
        )
      )
    );
  }
}