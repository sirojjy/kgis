import 'dart:convert';

import 'package:bpjt_k_gis_mobile_master/conn/API.dart';
import 'package:bpjt_k_gis_mobile_master/helper/db.dart';
import 'package:bpjt_k_gis_mobile_master/utils/colors.dart';
import 'package:bpjt_k_gis_mobile_master/view/activity/activity_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/attendance/attendance_list_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/dashboard/dashboard_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/summary/summary_search_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/tracking/problem_list_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/user/user_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'package:package_info/package_info.dart';
import 'package:search_choices/search_choices.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SummaryPage extends StatefulWidget {
  final dateFrom;
  final dateTo;

  SummaryPage({
    this.dateFrom,
    this.dateTo
  });

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool isReset = false;
  bool _loading = true;
  bool isSearch = false;

  final Color barBackgroundColor = const Color(0xff72d8bf);
  final Duration animDuration = const Duration(milliseconds: 250);
  final ScrollController _scrollCtrl = ScrollController();

  int touchedIndex = -1;

  bool isPlaying = false;

  String? _selectedStatus;
  String? _selectedSubStatus;
  String? _selectedRegion;
  String? _selectedSegment;

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
  List _segmentRegion = [];
  List _segment = [];

  var _dataSummary;
  var _totalUserPerCategory;
  var colorTotalUserPerCategory = [
    "#FD297B",
    "#000000",
    "#F26600",
    "#25d366"
  ];
  var _activityChart;
  var _problemChart;
  var _attendanceChart;
  var _totalUserPerSegmentChart;

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

  ///Perlu dicek apakah _selectedRegion _selectedSegment nullable/tidak
  _getData({bool isOnlySummary = false}) async {
    await API.getSummaryData(widget.dateFrom, widget.dateTo, _selectedRegion!, _selectedSegment!, version).then((response) {
      setState(() {
        _dataSummary = response;
      });
    });

    await API.getTotalUserPerCategory(widget.dateFrom, widget.dateTo, _selectedRegion!, _selectedSegment!, version).then((response) {
      setState(() {
        _totalUserPerCategory = response;
      });
    });

    if (!isOnlySummary) {
      await API.getActivityChart(widget.dateFrom, widget.dateTo, version).then((response) {
        setState(() {
          _activityChart = response;
        });
      });

      await API.getProblemChart(widget.dateFrom, widget.dateTo, version).then((response) {
        setState(() {
          _problemChart = response;
        });
      });

      await API.getAttendanceChart(widget.dateFrom, widget.dateTo, version).then((response) {
        setState(() {
          _attendanceChart = response;
        });
      });

      await API.getUserTotalPerSegmentChart("PMI", widget.dateFrom, widget.dateTo, version).then((response) {
        setState(() {
          _totalUserPerSegmentChart = response;
        });
      }); 
    }
  }
  
  _listSegment(String status, String subStatus, String region) async {
    await API.getSegment(status, subStatus, region, "true", version).then((response) {
      setState(() {
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
  _listSegmentRegion() async {
    await API.getSegmentRegion("", "", version).then((response) {
      setState(() {
        _segmentRegion = response;
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
    prefSegments = jsonDecode(prefs.getString('segments')!);
  }
  
  @override
  void initState() {
    super.initState();
    Db.syncToServer();
    _getInfo().then((resInfo) {
      _listSegmentRegion();
      _getPref().then((response) {
        _getData().then((resData) {
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
        title: const Text('Ringkasan Data'),
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
              setState(() {
                if (isSearch) {
                  isSearch = false;
                } else {
                  isSearch = true;
                }
                isReset = true;
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
          Container(
            margin: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SummarySearchPage(

                )));
              },
              child: const Icon(Icons.search, color: Colors.white,),
            ),
          )
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
      ModalProgressHUD(
        inAsyncCall: _loading,
        child: Column(
            children: [
              SizedBox(
                height: isSearch ? 200.0 : 0.0,
                child: Visibility(
                  visible: isSearch,
                  child: Scrollbar(
                    thumbVisibility: true,
                    thickness: 8.0,
                    controller: _scrollCtrl,
                    child: ListView(
                      controller: _scrollCtrl,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: const Text("Filter hanya untuk Summary Data", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),)
                        ),

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
                                _selectedRegion = newVal;
                                _selectedSegment = null;
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
                              return Container(
                                transform: Matrix4.translationValues(-10,0,0),
                                alignment: Alignment.centerLeft,
                                child: Text(item, style: const TextStyle(fontSize: 12.0, color: Colors.black),)
                              );
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
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0.8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.all(12),
                            backgroundColor: colorPrimary,
                          ),
                          onPressed: () {
                            // _submit();
                            setState(() {
                              isSearch = false;
                              _loading = true;

                              _dataSummary['user_registered'] = 0;
                              _dataSummary['problem_reported'] = 0;
                              _dataSummary['activity_reported'] = 0;
                              _dataSummary['attendance_total'] = 0;

                              for (var i = 0; i < _totalUserPerCategory.length; i++) {
                                _totalUserPerCategory[i]["total"] = 0;
                              }

                              _getData(isOnlySummary: true);
                              _loading = false;
                            });
                          },
                          child: const Text('SUBMIT', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text("Summary Data", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
                      ),
                      widget.dateFrom != null && widget.dateFrom != "" ?
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text("${DateFormat("dd-MM-yyyy").format(DateTime.parse(widget.dateFrom))} s/d ${DateFormat("dd-MM-yyyy").format(DateTime.parse(widget.dateTo))}", style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),),
                      )
                      : Container(),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        child: Text((_selectedSegment ?? ""), style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
                      //child: Text((_selectedSegment == null ?? "" : _selectedSegment), style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => UserPage(
                            segment: _selectedSegment,
                            region: _selectedRegion,
                            dateFrom: widget.dateFrom,
                            dateTo: widget.dateTo
                          )));
                        },
                        child: Card(
                          margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 5.0),
                          child: Container(
                            // height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: HexColor('#F26600'),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
                                  child: Text("${_dataSummary['user_registered']}", style: const TextStyle(fontSize: 35.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                ),
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                                  child: Text('Total User Terdaftar', style: TextStyle(color: Colors.white),),
                                ),
                              ],
                            )
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ProblemListPage(
                            segment: _selectedSegment,
                            region: _selectedRegion,
                            dateFrom: widget.dateFrom,
                            dateTo: widget.dateTo
                          )));
                        },
                        child: Card(
                          margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 5.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: HexColor('#25d366'),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
                                  child: Text("${_dataSummary['problem_reported']}", style: const TextStyle(fontSize: 35.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                ),
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                                  child: Text('Total Laporan Permasalahan', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            )
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityPage(
                            segment: _selectedSegment,
                            region: _selectedRegion,
                            dateFrom: widget.dateFrom,
                            dateTo: widget.dateTo
                          )));
                        },
                        child: Card(
                          margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 5.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: HexColor('#FFD200'),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
                                  child: Text("${_dataSummary['activity_reported']}", style: const TextStyle(fontSize: 35.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                ),
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                                  child: Text('Total Laporan Aktifitas', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            )
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceListPage(
                            segment: _selectedSegment,
                            region: _selectedRegion,
                            dateFrom: widget.dateFrom,
                            dateTo: widget.dateTo
                          )));
                        },
                        child: Card(
                          margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 5.0),
                          child: Container(
                            // height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: HexColor('#E84C3D'),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
                                  child: Text("${_dataSummary['attendance_total']}", style: const TextStyle(fontSize: 35.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                ),
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                                  child: Text('Total Absensi', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            )
                          ),
                        )
                      ),

                      const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text("Summary Jumlah User Per Kategori User", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                      ),

                      for (var i = 0; i < _totalUserPerCategory.length; i++)
                        _selectedSegment != "" && _totalUserPerCategory[i]['total'] > 0 ?
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => UserPage(
                              segment: _selectedSegment,
                              region: _selectedRegion,
                              dateFrom: widget.dateFrom,
                              dateTo: widget.dateTo,
                              companyField: _totalUserPerCategory[i]['company_field'],
                            )));
                          },
                          child: Card(
                            margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 5.0),
                            child: Container(
                              // height: 300,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                color: HexColor(colorTotalUserPerCategory[i]),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
                                    child: Text("${_totalUserPerCategory[i]['total']}", style: const TextStyle(fontSize: 35.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                                    child: Text("${_totalUserPerCategory[i]['company_field']}", style: const TextStyle(color: Colors.white)),
                                  ),
                                ],
                              )
                            ),
                          ),
                        )
                        :
                        Container(),
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text("Grafik Aktifitas", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                        ),
                        barChart("activity"),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10.0, left: 10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Legend: ", style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold)),
                                Text("y : Total Aktifitas yang dilaporkan", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                                Text("x : Nama ruas", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text("Grafik Permasalahan", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                        ),
                        barChart("problem"),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10.0, left: 10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Legend: ", style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold)),
                                Text("y : Total Permasalahan yang dilaporkan", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                                Text("x : Nama ruas", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text("Grafik Absensi", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                        ),
                        barChart("attendance"),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10.0, left: 10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Legend: ", style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold)),
                                Text("y : Total Absensi yang dilakukan", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                                Text("x : Nama ruas", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text("Grafik Jumlah User PMI Per Segment", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                        ),
                        barChart("total_user_per_segment"),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10.0, left: 10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Legend: ", style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold)),
                                Text("y : Total User yang terdaftar", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                                Text("x : Nama ruas", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ),
                    ],
                  ),
                )
              )
            ],
          ),
      )
    );
  }

  Widget barChart(type) {
    var data;
    double interval;

    if (type == 'activity') {
      data = _activityChart;
    }
    if (type == 'problem') {
      data = _problemChart;
    }
    if (type == 'attendance') {
      data = _attendanceChart;
    }
    if (type == 'total_user_per_segment') {
      data = _totalUserPerSegmentChart;
    }
    
    interval = 1;
    if (data.length > 0) {
      if (data[0]['total'] > 300) {
        interval = 50;
      } else if (data[0]['total'] < 300 && data[0]['total'] > 150) {
        interval = 30;
      } else if (data[0]['total'] < 150 && data[0]['total'] > 50) {
        interval = 10;
      } else if (data[0]['total'] < 50 && data[0]['total'] > 20) {
        interval = 5;
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 5.0, bottom: 10.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      color: const Color(0xff2c4260),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: data.length > 0 ? (data[0]['total'] > 150 ? data[0]['total'] + 50.0 : data[0]['total'] + 2.0) : 1,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.lightBlueAccent.withOpacity(0.5),
                tooltipPadding: const EdgeInsets.all(0),
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItem: (
                  BarChartGroupData group,
                  int groupIndex,
                  BarChartRodData rod,
                  int rodIndex,
                ) {
                  return BarTooltipItem(
                    // rod.y.round().toString(),
                    data[groupIndex]["segment"]+"\n${data[groupIndex]["total"]}",
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)
              ),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) => Text(
                        value.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      interval: interval
                  ),

              )
            ),
            borderData: FlBorderData(
              show: false,
            ),
            barGroups: [
              for (var i = 0; i < data.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      fromY: data[i]['total'].toDouble(),
                      toY: 0,
                      color: Colors.lightBlueAccent,
                      width: 15
                    )
                  ],
                  showingTooltipIndicators: [1],
                ),
            ],
          ),
        ),
      )
    );
  }
}