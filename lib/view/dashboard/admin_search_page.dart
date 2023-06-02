import 'package:bpjtteknik/conn/API.dart';
import 'package:bpjtteknik/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:search_choices/search_choices.dart';
// import 'package:searchable_dropdown/searchable_dropdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_admin_page.dart';
import 'dashboard_page.dart';

class AdminSearchPage extends StatefulWidget {
  @override
  _AdminSearchPageState createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends State<AdminSearchPage> {

  String _selectedSegment;
  String prefUserId;
  String prefUsername;
  String prefFullname;
  String prefGroupid;
  String prefGroupname;
  String prefLevel;
  String prefLft;
  String prefRgt;
  String prefCompanyId;
  String prefProvinceId;
  String prefCityId;
  String prefRoleName;
  String prefRestKeys;
  String _selectedCompanyField;

  int _provinceIdSelection;
  int _cityIdSelection;
  int _districtIdSelection;
  int _villageIdSelection;

  List _provinceData = List();
  List _cityData = List();
  List _districtData = List();
  List _villageData = List();
  List _segments = List();

  TextEditingController _keywordController = new TextEditingController();
  
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
  
  _listSegment() async {
    await API.getSegment("", "", "", "true", version).then((response) {
      setState(() {
        _segments = response;
      });
    });
  }

  _getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefUserId = prefs.getString('user_id');
    prefUsername = prefs.getString('username');
    prefFullname = prefs.getString('fullname');
    prefGroupid = prefs.getString('groupid');
    prefGroupname = prefs.getString('groupname');
    prefLevel = prefs.getString('level');
    prefLft = prefs.getString('lft');
    prefRgt = prefs.getString('rgt');
    prefCompanyId = prefs.getString('company_id');
    prefProvinceId = prefs.getString('province_id');
    prefCityId = prefs.getString('city_id');
    prefRoleName = prefs.getString('role_name');
    prefRestKeys = prefs.getString('rest_keys');
  }
  
  @override
  void initState() {
    super.initState();
    _getInfo().then((resInfo) {
      _getPref();
      _listSegment();
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
        elevation: 0.1,
        backgroundColor: colorTertiary,
        title: Text("Pencarian"),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text(
                      "INSTANSI",
                      style: TextStyle(fontFamily: "LatoLight",
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 15.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              child: ListTile(
                title: DropdownButton(
                  selectedItemBuilder: (BuildContext context) {
                    return <String>['BPJT', 'PMI', 'Tim Konsultan SIMK', 'PMO'].map<Widget>((String item) {
                      return Text(item, style: TextStyle(color: Colors.black),);
                    }).toList();
                  },
                  isExpanded: true,
                  hint: Row(
                    children: <Widget>[
                      Text('Pilih Instansi', style: TextStyle(color: Colors.black),),
                    ],
                  ),
                  items: <String>[
                    'BPJT', 'PMI', 'Tim Konsultan SIMK', 'PMO'
                  ].map((String item) {
                    return DropdownMenuItem(
                      value: item.toString(),
                      child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(item, style: TextStyle(fontSize: 13.0, color: Colors.black),)
                      )
                    );
                  }).toList(),
                  onChanged: (newVal) {
                    setState(() {
                      _selectedCompanyField = newVal;
                      _selectedSegment = null;
                    });
                  },
                  value: _selectedCompanyField,
                  underline: Container(color:Colors.black, height:0.5),
                ),
              ),
            ),
            Visibility(
              visible: _selectedCompanyField == "PMI" ? true : false,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Text(
                            "Ruas",
                            style: TextStyle(fontFamily: "LatoLight",
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    child: ListTile(
                      title: SearchChoices.single(
                        items: _segments.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: FittedBox(
                                fit: BoxFit.contain,
                                child: Text(item, style: TextStyle(fontSize: 12.0, color: Colors.black),)
                            )
                          );
                        }).toList(),
                        selectedValueWidgetFn: (item) {
                          return Container(
                            transform: Matrix4.translationValues(-10,0,0),
                            alignment: Alignment.centerLeft,
                            child: Text(item, style: TextStyle(fontSize: 12.0, color: Colors.black),)
                          );
                        },
                        hint: Container(
                          transform: Matrix4.translationValues(-10,0,0),
                          child: Text("Pilih Ruas", style: TextStyle(color: Colors.black),)
                        ),
                        searchHint: "Pilih Ruas",
                        onChanged: (value) {
                          setState(() {
                            if (value == null) {
                              _selectedSegment = null;
                            } else {
                              _selectedSegment = value;
                            }
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
                    )
                  ),
                ]
              ),
            ),
            TextFormField(
              controller: _keywordController,
              keyboardType: TextInputType.text,
              autocorrect: false,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: 'Keyword',
                labelStyle: TextStyle(decorationStyle: TextDecorationStyle.solid)
              ),
            ),
            FlatButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => new DashboardAdminPage(
                  keyword: _keywordController.text,
                  companyField: _selectedCompanyField,
                  segment: _selectedSegment,
                )));
              },
              color: colorTertiary,
              child: Text("Cari", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
    );
  }
}