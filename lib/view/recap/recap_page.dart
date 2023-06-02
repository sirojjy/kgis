import 'dart:convert';
import 'dart:io';

import 'package:bpjtteknik/conn/API.dart';
import 'package:bpjtteknik/helper/db.dart';
import 'package:bpjtteknik/pdf_viewer.dart';
import 'package:bpjtteknik/utils/colors.dart';
import 'package:bpjtteknik/utils/responsive_screen.dart';
import 'package:bpjtteknik/view/dashboard/dashboard_page.dart';
import 'package:bpjtteknik/view/recap/recap_search_page.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetalert/sweetalert.dart';

class RecapPage extends StatefulWidget {
  final segment;
  final position;
  final dateFrom;
  final dateTo;
  final name;

  RecapPage({
    this.segment,
    this.position,
    this.dateFrom,
    this.dateTo,
    this.name
  });

  @override
  _RecapPageState createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
  bool _loading = false;

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
  
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  var _recaps = [];
  
  Future<void> _getRecap(bool isRefresh) async {
    if (isRefresh) {
      setState(() {
        currentPage = 1;
      });
    } else if (_recaps.length >= totalData) {
      return;
    }

    await API.getRecaps(currentPage, widget.segment, widget.position, widget.dateFrom, widget.dateTo, widget.name, version).then((response) {
      if (!mounted) return;
      setState(() {
        if (response != null) {
          if (response["data"].length > 0) {
            totalData = response['nav']['totalData'];
            _recaps.addAll(response["data"]);
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
        _getRecap(true).then((resRecap) {
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
        title: Text('Daftar Rekap'),
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => new RecapSearchPage(

                )));
              },
              child: Icon(Icons.search, color: Colors.white,),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () async {
                SweetAlert.show(context,
                  title: "",
                  subtitle: "Download sedang berlangsung",
                  style: SweetAlertStyle.loading
                );

                createFile("http://103.6.53.254:13480/bpjt-teknik/public/index.php/api/recaps/pdf/download").then((res) async {
                  final filename = DateTime.now().millisecondsSinceEpoch.toString()+'.pdf';

                  Directory dir = await getExternalStorageDirectory();
                  String path = dir.path;

                  path = path.split('0').first;
                  await _createFolder('$path\0/Download/KGIS');

                  File file = res;

                  await file.copy('$path\0/Download/KGIS/$filename');

                  SweetAlert.show(context,
                    title: "Sukses",
                    subtitle: "Ada di folder Internal > Download > KGIS",
                    style: SweetAlertStyle.success,
                    onPress: (bool isConfirm) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => new PdfViewerPage(
                        pdfPath: res,
                      )));
                      return true;
                    }
                  );
                });
              },
              child: Icon(Icons.print, color: Colors.white,),
            ),
          )
        ],
      ),
      body: ModalProgressHUD(
        child: _recaps.length < 1 ? noData() : 
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
              itemCount: _recaps.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => {
                    if (!_recaps[index].isEmpty) {
                      
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
                            margin: const EdgeInsets.all(5.0),
                            height: 120.0,
                            constraints: BoxConstraints(maxWidth: 100.0, minWidth: 100.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: 
                                  _recaps[index]["filepath"] != null && _recaps[index]["filename"] != null ?
                                    NetworkImage(
                                      "http://103.6.53.254:13480/bpjt-teknik/public"+_recaps[index]["filepath"]+"/"+_recaps[index]["filename"],
                                  )
                                  :
                                  AssetImage('assets/images/person_6x8.png')
                              )
                            ),
                            // child: ClipOval(
                            //   child: _users[index]["filepath"] != null && _users[index]["filename"] != null ?
                            //     Image.network(
                            //       "http://103.6.53.254:13480/bpjt-teknik/public"+_users[index]["filepath"]+"/"+_users[index]["filename"],
                            //   )
                            //   :
                            //   Image.asset('assets/images/person_6x8.png')
                            // )
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
                                      child: Text(_recaps[index]["name"], style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(_recaps[index]["position"] ?? '-', style: TextStyle(color: Colors.white, fontSize: 14.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text("Kewajiban Absensi : ${_recaps[index]["total_user_days"]}x", style: TextStyle(color: Colors.white, fontSize: 14.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text("Absensi : ${_recaps[index]["total_attendance_reported"]}x", style: TextStyle(color: Colors.white, fontSize: 14.0)),
                                    ),
                                  ),
                                  ExpandablePanel(
                                    theme: const ExpandableThemeData(
                                      headerAlignment: ExpandablePanelHeaderAlignment.center,
                                      tapBodyToCollapse: true,
                                    ),
                                    header: Padding(
                                        padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0.0),
                                        child: Text(
                                          "Klik Untuk Melihat Rekap",
                                          style: TextStyle(color: Colors.white),
                                        )
                                      ),
                                    expanded: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: List.generate(_recaps[index]['user_segments'].length,(i){
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_recaps[index]['user_segments'][i]['segment'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            SizedBox(height: 5.0),
                                            Text("Lap. Aktivitas : ${_recaps[index]['user_segments'][i]['total_activity_reported']}x", style: TextStyle(color: Colors.white)),
                                            Text("Lap. Permasalahan : ${_recaps[index]['user_segments'][i]['total_problem_reported']}x", style: TextStyle(color: Colors.white)),
                                          ],
                                        );
                                      }),
                                    ),
                                    builder: (_, collapsed, expanded) {
                                      return Padding(
                                        padding: EdgeInsets.only(left: 5, right: 10, bottom: 10.0),
                                        child: Expandable(
                                          collapsed: collapsed,
                                          expanded: expanded,
                                          theme: const ExpandableThemeData(crossFadePoint: 0),
                                        ),
                                      );
                                    },
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
    _recaps.clear();
    // monitor network fetch
    await _getRecap(true);
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    await _getRecap(false);
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    if(mounted)
    setState(() {

    });
    _refreshController.loadComplete();
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

Future<File> createFile(String fileUrl) async {
    try {
      /// setting filename 
      final filename = DateTime.now().millisecondsSinceEpoch.toString()+'.pdf';

      /// getting application doc directory's path in dir variable
      String dir = (await getApplicationDocumentsDirectory()).path;

      /// if `filename` File exists in local system then return that file.
      /// This is the fastest among all.
      if (await File('$dir/$filename').exists()) return File('$dir/$filename');

      ///if file not present in local system then fetch it from server

      String url = fileUrl;

      /// requesting http to get url
      var request = await HttpClient().getUrl(Uri.parse(url));

      /// closing request and getting response
      var response = await request.close();

      /// getting response data in bytes
      var bytes = await consolidateHttpClientResponseBytes(response);

      /// generating a local system file with name as 'filename' and path as '$dir/$filename'
      File file = new File('$dir/$filename');

      /// writing bytes data of response in the file.
      await file.writeAsBytes(bytes);

      /// returning file.
      return file;
    } catch (err) {
      var errorMessage = "Error";
      print(errorMessage);
      print(err);
      return null;
    }
  }

  Future<bool> _createFolder(String dir) async {
    final path = Directory(dir);
    if ((await path.exists())) {
      print("exist");
      return true;
    } else {
      print("not exist");
      path.create();
      return false;
    }
  } 
}