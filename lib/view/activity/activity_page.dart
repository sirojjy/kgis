import 'package:bpjtteknik/conn/API.dart';
import 'package:bpjtteknik/helper/db.dart';
import 'package:bpjtteknik/helper/main_helper.dart';
import 'package:bpjtteknik/utils/utils.dart';
import 'package:bpjtteknik/view/activity/activity_detail_page.dart';
import 'package:bpjtteknik/view/activity/activity_search_page.dart';
import 'package:bpjtteknik/view/activity/add_activity_page.dart';
import 'package:bpjtteknik/view/activity/map_activity_page.dart';
import 'package:bpjtteknik/view/dashboard/dashboard_page.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:package_info/package_info.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityPage extends StatefulWidget {
  final segment;
  final position;
  final dateFrom;
  final dateTo;
  final name;
  final role;
  final region;

  ActivityPage({
    this.segment,
    this.position,
    this.dateFrom,
    this.dateTo,
    this.name,
    this.role,
    this.region,
  });

  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  Screen size;

  bool _loading = true;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;

  int totalData;
  int currentPage;

  RefreshController _refreshController = RefreshController(initialRefresh: false);
  var _activities = [];

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
  
  Future<void> _getActivities(bool isRefresh) async {
    String userId;
    // if (prefCompanyField == "PMI" || prefCompanyField == "Tim Konsultan SIMK" || prefCompanyField == "PMO") {
      userId = prefId;
    // }

    if (isRefresh) {
      setState(() {
        currentPage = 1;
      });
    } else if (_activities.length >= totalData) {
      return;
    }

      await API.getActivities(currentPage, widget.dateFrom, widget.dateTo, widget.segment, userId, widget.position, widget.name, widget.role, widget.region, version).then((response) {
      if (!mounted) return;
      showUpdateAppsModal(context, response);
      setState(() {
        if (response != null) {
          if (response["data"].length > 0) {
            totalData = response['nav']['totalData'];
            _activities.addAll(response["data"]);
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
  }
  
  @override
  void initState() {
    super.initState();
    Db.syncToServer();
    _getInfo().then((resInfo) {
      _getPref().then((response) {
        _getActivities(true).then((resProblems) {
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
        title: Text('Laporan Kegiatan'),
        backgroundColor: colorPrimary,
        actions: [
          GestureDetector(
              onTap: () async {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => DashboardPage()));
              },
              child: Icon(Icons.home, color: Colors.white,),
          ),
          SizedBox(width: 10.0,),
          GestureDetector(
              onTap: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) => new ActivitySearchPage(

                )));
              },
              child: Icon(Icons.search, color: Colors.white,),
          ),
          SizedBox(width: 10.0,),
        ],
      ),
      body: ModalProgressHUD(
        child: _activities.length < 1 ? noData() : 
          SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            header: WaterDropHeader(),
            footer: CustomFooter(
              builder: (BuildContext context,LoadStatus mode){
                Widget body ;
                if (mode==LoadStatus.idle) {
                  body =  Text("pull up load");
                } else if (mode==LoadStatus.loading) {
                  body =  CupertinoActivityIndicator();
                } else if (mode == LoadStatus.failed) {
                  body = Text("Load Failed!Click retry!");
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
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ActivityDetailPage(
                        id: _activities[index]["id"],
                        userId: _activities[index]["user_id"],
                        name: _activities[index]["name"],
                        phone: _activities[index]["phone"],
                        email: _activities[index]["email"],
                        position: _activities[index]["position"],
                        activity: _activities[index]["activity"],
                        long: _activities[index]["long"],
                        lat: _activities[index]["lat"],
                        segment: _activities[index]["segment"],
                        date: _activities[index]["date"],
                        isActive: _activities[index]["is_active"],
                        isDelete: _activities[index]["is_delete"],
                        isHidden: _activities[index]["is_hidden"],
                        createdAt: _activities[index]["created_at"],
                        updatedAt: _activities[index]["updated_at"],
                        priority: _activities[index]["priority"],
                        activityDetails: _activities[index]["activity_details"],
                        companyField: prefCompanyField,
                        location: _activities[index]["location"],
                      )
                    )
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
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
                                (_activities[index].isEmpty ? null : 
                                  (_activities[index]['activity_details'].isEmpty ? null : 
                                    _activities[index]['activity_details'][0]['filepath']
                                  )
                                ), 
                                (_activities[index].isEmpty ? null : 
                                  (_activities[index]['activity_details'].isEmpty ? null : 
                                    _activities[index]['activity_details'][0]['filename'])
                                )
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
                                      child: Text('${_activities[index]["segment"]}', style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Nama : ${_activities[index]["name"]}', style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(3.0, 3.0, 3.0, 0.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text((_activities[index]["date"] != null ? date(DateTime.parse(_activities[index]["date"])) : '-'), style: TextStyle(color: Colors.white, fontSize: 13.0), textAlign: TextAlign.justify),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(3.0, 3.0, 3.0, 10.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text((
                                        _activities[index]["activity"].length > 50 ?
                                        _activities[index]["activity"].substring(0, 50)+"..." :
                                        _activities[index]["activity"]) , style: TextStyle(color: Colors.white, fontSize: 13.0), textAlign: TextAlign.justify),
                                    ),
                                  ),
                                  // ExpandablePanel(
                                  //   theme: const ExpandableThemeData(
                                  //     headerAlignment: ExpandablePanelHeaderAlignment.center,
                                  //     tapBodyToCollapse: true,
                                  //   ),
                                  //   header: Padding(
                                  //       padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0.0),
                                  //       child: Text(
                                  //         "Klik Untuk Melihat Isi Kegiatan",
                                  //         style: TextStyle(color: Colors.white),
                                  //       )
                                  //     ),
                                  //   expanded: Column(
                                  //     crossAxisAlignment: CrossAxisAlignment.start,
                                  //     children: <Widget>[
                                  //       Text(
                                  //         _activities[index]["activity"],
                                  //         style: TextStyle(color: Colors.white),
                                  //       ),
                                  //       // Divider(thickness: 1.2,)
                                  //     ],
                                  //   ),
                                  //   builder: (_, collapsed, expanded) {
                                  //     return Padding(
                                  //       padding: EdgeInsets.only(left: 10, right: 10, bottom: 10.0),
                                  //       child: Expandable(
                                  //         collapsed: collapsed,
                                  //         expanded: expanded,
                                  //         theme: const ExpandableThemeData(crossFadePoint: 0),
                                  //       ),
                                  //     );
                                  //   },
                                  // ),
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
      ),
      floatingActionButton: _getFAB()
    );
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
          // Image.network(
          //   "http://5.189.164.87/api_constructions/storage/app/media/activities/" + url,
          //   fit: BoxFit.fitHeight,
          //   width: 120.0,
          // )
          Container(
            child: FadeInImage.assetNetwork(
                placeholder: 'assets/images/no_image_2.png',
                image: "http://103.6.53.254:13480/bpjt-teknik/public"+path+"/" + url,
                height: 115.0,
            )
          )
          // Container()
        ),
    );
  }

  Widget _getFAB() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22),
      backgroundColor: Colors.white,
      visible: true,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(Icons.add),
          backgroundColor: Colors.white,
          onTap: () { 
            Navigator.push(context, MaterialPageRoute(builder: (context) => AddActivityPage()));  
          },
          label: 'Lapor Kegiatan',
          labelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontSize: 16.0),
          labelBackgroundColor: colorPrimary
        ),
        SpeedDialChild(
          child: Icon(Icons.map),
          backgroundColor: Colors.white,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MapActivityPage()));
          },
          label: 'Map Kegiatan',
          labelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontSize: 16.0),
          labelBackgroundColor: colorPrimary
        )
      ],
    );
  }

  void _onRefresh() async {
    _activities.clear();
    // monitor network fetch
    await _getActivities(true);
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    await _getActivities(false);
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    if(mounted)
    setState(() {

    });
    _refreshController.loadComplete();
  }

  Widget noData() {
    size = Screen(MediaQuery.of(context).size);
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