import 'package:bpjtteknik/change_password.dart';
import 'package:bpjtteknik/conn/API.dart';
import 'package:bpjtteknik/utils/utils.dart';
import 'package:bpjtteknik/view/auth/login.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:package_info/package_info.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:ribbon/ribbon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetalert/sweetalert.dart';

import 'admin_search_page.dart';

class DashboardAdminPage extends StatefulWidget {
  final keyword;
  final companyField;
  final segment;

  DashboardAdminPage({
    this.keyword,
    this.companyField,
    this.segment
  });

  @override
  _DashboardAdminPageState createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> with SingleTickerProviderStateMixin {
  var _verified = [];
  var _unverified = [];
  int totalData;
  int totalData2;
  int currentPage;
  int currentPage2;
  
  Screen size;

  bool _loading = false;

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;

  String status;

  Color ribbonColor;
  double nearLength = 20;
  double farLength = 60;
  RibbonLocation location = RibbonLocation.topEnd;
  
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  RefreshController _refreshController2 = RefreshController(initialRefresh: false);

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
  
  Future<void> _getVerified(bool isRefresh) async {
    if (isRefresh) {
      setState(() {
        currentPage = 1;
      });
    } else if (_verified.length >= totalData) {
      return;
    }

    await API.getUsers(true, "", widget.companyField, widget.segment, currentPage, version).then((response) {
      if (!mounted) return;
      setState(() {
        if (response != null) {
          if (response.length > 0) {
            totalData = response["nav"]["totalData"];
            _verified.addAll(response["data"]);
            currentPage = currentPage + 1;
          }
        }
      });
    });
  }

  Future<void> _getUnverified(bool isRefresh) async {
    if (isRefresh) {
      setState(() {
        currentPage2 = 1;
      });
    } else if (_unverified.length >= totalData2) {
      return;
    }

    await API.getUsers(false, "", widget.companyField, widget.segment, currentPage2, version).then((response) {
      if (!mounted) return;
      setState(() {
        if (response != null) {
          if (response.length > 0) {
            totalData2 = response["nav"]["totalData"];
            _unverified.addAll(response["data"]);
            currentPage2 = currentPage2 + 1;
          }
        }
      });
    });
  }

  final List<Tab> tabs = <Tab>[
    Tab(text: "Verified"),
    Tab(text: "Unverified")
  ];

  TabController _tabController;

  _submit(ctx, id) async {
    Map<String, dynamic> params = Map<String, dynamic>();
    params["id"] = id;
    params["is_approve"] = true;
    await API.users(params, version).then((response) {
      if (response["status"] != null) {
        // SweetAlert.show(context,style: SweetAlertStyle.success,title: "Success");
        SweetAlert.show(context,
          title: "Sukses",
          subtitle: response["message"],
          style: SweetAlertStyle.success,
          onPress: (bool isConfirm) {
          if (isConfirm) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => DashboardAdminPage()));
            // return false to keep dialog
            return true;
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: tabs.length);
    _getInfo().then((resInfo) {
      _getPref().then((response) {
        _getUnverified(true);
        _getVerified(true).then((resVerif) {
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorTertiary,
      appBar: AppBar(
        title: Text('Halo Admin'),
        bottom: TabBar(
          isScrollable: true,
          unselectedLabelColor: Colors.white,
          labelColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BubbleTabIndicator(
            indicatorHeight: 25.0,
            indicatorColor: colorTertiary,
            tabBarIndicatorSize: TabBarIndicatorSize.tab,
          ),
          tabs: tabs,
          controller: _tabController,
        ),
        actions: [
          GestureDetector(
              onTap: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) => new ChangePasswordPage(

                )));
              },
              child: Icon(Icons.lock, color: Colors.white,),
          ),
          SizedBox(width: 10.0,),
          GestureDetector(
              onTap: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) => new AdminSearchPage(

                )));
              },
              child: Icon(Icons.search, color: Colors.white,),
          ),
          SizedBox(width: 10.0,),
          GestureDetector(
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.clear();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginPage()), (Route<dynamic> route) => false);
            },
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 10.0),
                  child: Icon(Icons.power_settings_new),
                ),
              ],
            )
          )
        ],
      ),
      body: ModalProgressHUD(
        child: TabBarView(
          controller: _tabController,
          children: [
            SmartRefresher(
              enablePullDown: true,
              enablePullUp: true,
              header: WaterDropHeader(),
              footer: CustomFooter(
                builder: (BuildContext context,LoadStatus mode) {
                  Widget body ;
                  if (mode == LoadStatus.idle) {
                    body =  Text("pull up load");
                  } else if (mode==LoadStatus.loading) {
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
                itemCount: _verified.length,
                itemBuilder: (context, index) {
                  return Container(
                    child: GestureDetector(
                      onTap: () => {
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => new AdvancedAdminDashboardPage(params: _verified[index])))
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 5.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          semanticContainer: true,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  decoration: BoxDecoration(
                                    color: colorPrimary,
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Nama : "+_verified[index]["name"], style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Email : "+_verified[index]["email"], style: TextStyle(color: Colors.white, fontSize: 13.0), textAlign: TextAlign.justify),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Instansi : "+(_verified[index]["company_field"] == null ? "-" : _verified[index]["company_field"]), style: TextStyle(color: Colors.white), textAlign: TextAlign.justify),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Ruas : "+(_verified[index]["user_segment"] == "" ? "-" : _verified[index]["user_segment"]), style: TextStyle(color: Colors.white, fontSize: 13.0), textAlign: TextAlign.justify),
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
                    )
                  );
                }
              ),
            ),
            SmartRefresher(
              enablePullDown: true,
              enablePullUp: true,
              header: WaterDropHeader(),
              footer: CustomFooter(
                builder: (BuildContext context,LoadStatus mode) {
                  Widget body ;
                  if (mode == LoadStatus.idle) {
                    body =  Text("pull up load");
                  } else if (mode==LoadStatus.loading) {
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
              controller: _refreshController2,
              onRefresh: _onRefresh2,
              onLoading: _onLoading2,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _unverified.length,
                itemBuilder: (context, index) {
                  return Container(
                    child: GestureDetector(
                      onTap: () => {
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => new AdvancedAdminDashboardPage(params: _unverified[index])))
                        SweetAlert.show(context,
                          title: "Apakah Anda Yakin",
                          subtitle: "Menyetujui user ini?",
                          style: SweetAlertStyle.confirm,
                          showCancelButton: true, 
                          onPress: (bool isConfirm) {
                          if (isConfirm) {
                            _submit(context, _unverified[index]["id"]);
                            // return false to keep dialog
                            return false;
                          }
                        })
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 5.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          semanticContainer: true,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  decoration: BoxDecoration(
                                    color: colorPrimary,
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Nama : "+_unverified[index]["name"], style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Email : "+_unverified[index]["email"], style: TextStyle(color: Colors.white, fontSize: 13.0), textAlign: TextAlign.justify),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Instansi : "+(_unverified[index]["company_field"] == null ? "-" : _unverified[index]["company_field"]), style: TextStyle(color: Colors.white), textAlign: TextAlign.justify),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Ruas : "+(_unverified[index]["user_segment"] == "" ? "-" : _unverified[index]["user_segment"]), style: TextStyle(color: Colors.white, fontSize: 13.0), textAlign: TextAlign.justify),
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
                    )
                  );
                }
              ),
            ),
          ],
        ),
        inAsyncCall: _loading,
      )
    );
  }

  void _onRefresh() async{
    _verified.clear();
    // monitor network fetch
    await _getVerified(true);
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  void _onLoading() async{
    // monitor network fetch
    await _getVerified(false);
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    if(mounted)
    setState(() {

    });
    _refreshController.loadComplete();
  }

  void _onRefresh2() async{
    _unverified.clear();
    // monitor network fetch
    await _getUnverified(true);
    // if failed,use refreshFailed()
    _refreshController2.refreshCompleted();
  }

  void _onLoading2() async{
    // monitor network fetch
    await _getUnverified(false);
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    if(mounted)
    setState(() {

    });
    _refreshController2.loadComplete();
  }
}