import 'dart:convert';

import 'package:bpjt_k_gis_mobile_master/conn/API.dart';
import 'package:bpjt_k_gis_mobile_master/utils/colors.dart';
import 'package:bpjt_k_gis_mobile_master/utils/responsive_screen.dart';
import 'package:bpjt_k_gis_mobile_master/view/dashboard/dashboard_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/user/user_detail_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/user/user_search_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'package:package_info/package_info.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPage extends StatefulWidget {
  final segment;
  final region;
  final position;
  final dateFrom;
  final dateTo;
  final name;
  final companyField;

  UserPage({
    this.segment,
    this.region,
    this.position,
    this.dateFrom,
    this.dateTo,
    this.name,
    this.companyField
  });

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  bool _loading = true;

  int? totalData;
  int? currentPage;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  var prefSegment;
  List prefSegments = [];
  
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  var _users = [];
  
  String? appName;
  String? packageName;
  String? version;
  String? buildNumber;

  _getInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }
  
  Future<void> _getUser(bool isRefresh) async {
    if (isRefresh) {
      setState(() {
        currentPage = 1;
      });
    } else if (_users.length >= totalData!) {
      return;
    }

    await API.getUsersAll(currentPage!, widget.segment, widget.position, widget.dateFrom, widget.dateTo, widget.name, widget.region, widget.companyField, version!).then((response) {
      if (!mounted) return;
      setState(() {
        if (response != null) {
          if (response["data"].length > 0) {
            totalData = response['nav']['totalData'];
            _users.addAll(response["data"]);
            currentPage = currentPage! + 1;
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
    String? segmentsString = prefs.getString('segments');
    prefSegments = segmentsString != null ? jsonDecode(segmentsString) : [];
  }
  
  @override
  void initState() {
    super.initState();
    _getInfo().then((resInfo) {
      _getPref().then((response) {
        _getUser(true).then((resUser) {
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
        title: const Text('Daftar Pengguna'),
        backgroundColor: colorPrimary,
        actions: [
          GestureDetector(
              onTap: () async {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => DashboardPage()));
              },
              child: const Icon(Icons.home, color: Colors.white,),
          ),
          const SizedBox(width: 10.0,),
          Container(
            margin: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) => new UserSearchPage(

                )));
              },
              child: const Icon(Icons.search, color: Colors.white,),
            ),
          )
        ],
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        child: _users.length < 1 ? noData() :
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
                  body = const Text("Load Failed! Click retry!");
                } else if (mode == LoadStatus.canLoading) {
                    body = const Text("release to load more");
                } else {
                  body = const Text("No more Data");
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
              itemCount: _users.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => {
                    if (!_users[index].isEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserDetailPage(
                            id: _users[index]['id'],
                            name: _users[index]['name'],
                            company: _users[index]['company'],
                            phone: _users[index]['phone'],
                            email: _users[index]['email'],
                            roleId: _users[index]['role_id'],
                            isApprove: _users[index]['is_approve'],
                            createdAt: _users[index]['created_at'],
                            updatedAt: _users[index]['updated_at'],
                            position: _users[index]['position'],
                            userSegment: _users[index]['user_segment'],
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
                            margin: const EdgeInsets.all(5.0),
                            height: 120.0,
                            constraints: const BoxConstraints(maxWidth: 100.0, minWidth: 100.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image:
                                  _users[index]["filepath"] != null && _users[index]["filename"] != null ?
                                  NetworkImage (
                                    "${"http://103.6.53.254:13480/bpjt-teknik/public" +
                                        _users[index]["filepath"]}/" +
                                        _users[index]["filename"],
                                  )
                                  :
                                  const AssetImage('assets/images/person_6x8.png') as ImageProvider<Object>,
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
                                      child: Text(_users[index]["name"] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(_users[index]["phone"] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 14.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(_users[index]["email"] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 14.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(_users[index]["position"] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 14.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(_users[index]["company_field"] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 14.0)),
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
      )
    );
  }

  void _onRefresh() async {
    _users.clear();
    // monitor network fetch
    await _getUser(true);
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    await _getUser(false);
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
}