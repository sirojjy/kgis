import 'package:bpjt_k_gis_mobile_master/conn/API.dart';
import 'package:bpjt_k_gis_mobile_master/helper/db.dart';
import 'package:bpjt_k_gis_mobile_master/helper/main_helper.dart';
import 'package:bpjt_k_gis_mobile_master/utils/utils.dart';
import 'package:bpjt_k_gis_mobile_master/view/dashboard/dashboard_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/tracking/add_tracking_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/tracking/map_tracking_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/tracking/tracking_detail_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/tracking/tracking_search_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'package:package_info/package_info.dart';

class ProblemListPage extends StatefulWidget {
  final segment;
  final position;
  final dateFrom;
  final dateTo;
  final name;
  final role;
  final region;

  ProblemListPage({
    this.segment,
    this.position,
    this.dateFrom,
    this.dateTo,
    this.name,
    this.role,
    this.region
  });

  @override
  _ProblemListPageState createState() => _ProblemListPageState();
}

class _ProblemListPageState extends State<ProblemListPage> {
  late Screen size;

  bool _loading = true;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;

  late int totalData;
  late int currentPage;

  RefreshController _refreshController = RefreshController(initialRefresh: false);
  var _trackingProblems = [];

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
  
  Future<void> _getTrackingProblems(bool isRefresh) async {
    String userId;
    // if (prefCompanyField == "PMI" || prefCompanyField == "PMO") {
      userId = prefId;
    // }

    if (isRefresh) {
      setState(() {
        currentPage = 1;
      });
    } else if (_trackingProblems.length >= totalData) {
      return;
    }

    await API.getTrackingProblems(currentPage, widget.dateFrom, widget.dateTo, widget.segment, userId, widget.position, widget.name, widget.role, widget.region, version).then((response) {
      if (!mounted) return;
      showUpdateAppsModal(context, response);
      setState(() {
        if (response != null) {
          if (response["data"].length > 0) {
            totalData = response['nav']['totalData'];
            _trackingProblems.addAll(response["data"]);
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
    Db.syncToServer();
    super.initState();
    _getInfo().then((resInfo) {
      _getPref().then((response) {
        _getTrackingProblems(true).then((resProblems) {
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

  Widget displaySelectedFile(String path, String url) {
    if (path == null || path == "") {
      path = "storage/app/media/problems";
    }
    
    return SizedBox(
      height: 120.0,
      child: url == "/" || url == null
          ? Image.asset("assets/images/no_image_2.png")
          : (url.contains(".pdf") ? Column(children: <Widget>[Image.asset("assets/images/pdf_placeholder.png", width: 120.0,)]) : 
            // Image.network(
            //   "http://5.189.164.87/api_constructions/storage/app/media/problems/" + url,
            //   fit: BoxFit.fitHeight,
            //   width: 120.0,
            // )
            Container(
              child: FadeInImage.assetNetwork(
                  placeholder: 'assets/images/no_image_2.png',
                  image: "http://103.6.53.254:13480/bpjt-teknik/public$path/$url",
                  height: 115.0,
              )
            )
            // Container()
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tracking Permasalahan'),
        backgroundColor: colorPrimary,
        actions: [
          GestureDetector(
              onTap: () async {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => DashboardPage()));
              },
              child: const Icon(Icons.home, color: Colors.white,),
          ),
          const SizedBox(width: 10.0,),
          GestureDetector(
              onTap: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TrackingSearchPage()));
              },
              child: const Icon(Icons.search, color: Colors.white,),
          ),
          const SizedBox(width: 10.0,),
        ],
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        child: _trackingProblems.isEmpty ? noData() :
          SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            header: const WaterDropHeader(),
            footer: CustomFooter(
              builder: (BuildContext context,LoadStatus? mode){
                Widget body ;
                if (mode == LoadStatus.idle) {
                  body =  const Text("pull up load");
                } else if (mode == LoadStatus.loading) {
                  body =  const CupertinoActivityIndicator();
                } else if (mode == LoadStatus.failed) {
                  body = const Text("Load Failed!Click retry!");
                } else if (mode == LoadStatus.canLoading) {
                    body = const Text("release to load more");
                } else {
                  body = const Text("No more Data");
                }
                return SizedBox(
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
              itemCount: _trackingProblems.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => {
                    if (!_trackingProblems[index].isEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TrackingDetailPage(
                            id: _trackingProblems[index]["id"],
                            userId: _trackingProblems[index]["user_id"],
                            name: _trackingProblems[index]["name"],
                            phone: _trackingProblems[index]["phone"],
                            email: _trackingProblems[index]["email"],
                            position: _trackingProblems[index]["position"],
                            problem: _trackingProblems[index]["problem"],
                            long: _trackingProblems[index]["long"],
                            lat: _trackingProblems[index]["lat"],
                            filename: _trackingProblems[index]["filename"],
                            filepath: _trackingProblems[index]["filepath"],
                            segment: _trackingProblems[index]["segment"],
                            date: _trackingProblems[index]["date"],
                            priority: _trackingProblems[index]["priority"],
                            createdAt: _trackingProblems[index]["created_at"],
                            updatedAt: _trackingProblems[index]["updated_at"],
                            isActive: _trackingProblems[index]["is_active"],
                            isDelete: _trackingProblems[index]["is_delete"],
                            isHidden: _trackingProblems[index]["is_hidden"],
                            location: _trackingProblems[index]["location"],
                            note: _trackingProblems[index]["note"],
                            note2: _trackingProblems[index]["note2"],
                            companyField: prefCompanyField,
                            noteAnswer: _trackingProblems[index]["note_answer"],
                          )
                        )
                      )
                    }
                    // _showDialog(context, "${_trackingProblems[index]["no_berkas"]}", _trackingProblems[index]["ketentuan_rekomendasi"], _trackingProblems[index]["alasan"])
                  },
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
                            constraints: const BoxConstraints(maxWidth: 125.0),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: displaySelectedFile((_trackingProblems[index].isEmpty ? null : _trackingProblems[index]['filepath']), (_trackingProblems[index].isEmpty ? null : _trackingProblems[index]['filename'])),
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
                                      child: Text('${_trackingProblems[index]["segment"]}', style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Nama : ${_trackingProblems[index]["name"]}', style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(3.0, 3.0, 3.0, 0.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text((_trackingProblems[index]["date"] != null ? date(DateTime.parse(_trackingProblems[index]["date"])) : '-'), style: const TextStyle(color: Colors.white, fontSize: 13.0), textAlign: TextAlign.justify),
                                    ),
                                  ),
                                  Visibility(
                                    visible: (prefCompanyField == 'PMI' || prefCompanyField == 'PMO' || prefCompanyField == 'BPJT') && _trackingProblems[index]["note"] != null && _trackingProblems[index]["note"] != "" ? true : false,
                                    child: const Padding(
                                      padding: EdgeInsets.fromLTRB(0.0, 5.0, 3.0, 0.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning, color: Colors.orange),
                                            Text(' PMO Memberi Note', style: TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold), textAlign: TextAlign.justify),
                                          ],
                                        )
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: (prefCompanyField == 'PMI' || prefCompanyField == 'PMO' || prefCompanyField == 'BPJT') && _trackingProblems[index]["note2"] != null && _trackingProblems[index]["note2"] != "" ? true : false,
                                    child: const Padding(
                                      padding: EdgeInsets.fromLTRB(0.0, 3.0, 3.0, 0.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning, color: Colors.orange),
                                            Text(' BPJT Memberi Note', style: TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold), textAlign: TextAlign.justify),
                                          ],
                                        )
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: (prefCompanyField == 'PMI' || prefCompanyField == 'PMO' || prefCompanyField == 'BPJT') && _trackingProblems[index]["note_answer"] != null && _trackingProblems[index]["note_answer"] != "" ? true : false,
                                    child: const Padding(
                                      padding: EdgeInsets.fromLTRB(0.0, 3.0, 3.0, 0.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning, color: Colors.orange),
                                            Text(' PMI Memberi Tanggapan', style: TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold), textAlign: TextAlign.justify),
                                          ],
                                        )
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(3.0, 3.0, 3.0, 10.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text((
                                        _trackingProblems[index]["problem"].length > 50 ?
                                        _trackingProblems[index]["problem"].substring(0, 50)+"..." :
                                        _trackingProblems[index]["problem"]) , style: const TextStyle(color: Colors.white, fontSize: 13.0), textAlign: TextAlign.justify),
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
                                  //         "Klik Untuk Detail Laporan",
                                  //         style: TextStyle(color: Colors.white),
                                  //       )
                                  //     ),
                                  //   expanded: Column(
                                  //     crossAxisAlignment: CrossAxisAlignment.start,
                                  //     children: <Widget>[
                                  //       Text(
                                  //         _trackingProblems[index]["problem"],
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
      ),
      floatingActionButton: _getFAB()
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
          child: const Icon(Icons.add),
          backgroundColor: Colors.white,
          onTap: () { 
            Navigator.push(context, MaterialPageRoute(builder: (context) => AddTrackingPage()));  
          },
          label: 'Lapor Tracking',
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontSize: 16.0),
          labelBackgroundColor: colorPrimary
        ),
        SpeedDialChild(
          child: const Icon(Icons.map),
          backgroundColor: Colors.white,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MapTrackingPage()));
          },
          label: 'Map Tracking',
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontSize: 16.0),
          labelBackgroundColor: colorPrimary
        )
      ],
    );
  }
  
  void _onRefresh() async {
    _trackingProblems.clear();
    // monitor network fetch
    await _getTrackingProblems(true);
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    await _getTrackingProblems(false);
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    if(mounted) {
      setState(() {}
      );
    }
    _refreshController.loadComplete();
  }

  Widget noData() {
    size = Screen(MediaQuery.of(context).size);
    return Center(
      child: SizedBox(
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