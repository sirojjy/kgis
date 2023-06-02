import 'dart:convert';

import 'package:bpjtteknik/conn/API.dart';
import 'package:bpjtteknik/utils/colors.dart';
import 'package:bpjtteknik/view/recap/recap_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:package_info/package_info.dart';
import 'package:search_choices/search_choices.dart';
// import 'package:searchable_dropdown/searchable_dropdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecapSearchPage extends StatefulWidget {
  @override
  RecapSearchPageState createState() => RecapSearchPageState();
}

class RecapSearchPageState extends State<RecapSearchPage> {
  String _dateFrom;
  String _dateTo;
  String _selectedSegment;
  String _selectedPosition;

  List _segments = List();
  List prefSegments = List();

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  var prefSegment;

  TextEditingController _nameController = new TextEditingController();
  
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
  
  List positions = [
    "Ahli Jalan Raya",
    "Ahli Keselamatan Kesehatan Kerja dan Lingkungan",
    "Ahli Material dan Mutu",
    "Team Leader / Ahli Jalan Raya Senior",
    "Ahli Manajemen Proyek Senior",
    "Ahli Teknologi Informasi",
    "Ahli Quality Assurance dan Quality Control Senior",
    "Ahli Struktur"
  ];
  
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
  
  _listSegment() async {
    await API.getSegment("", "", "", "true", version).then((response) {
      setState(() {
        _segments = response;
      });
    });
  }
  
  @override
  void initState() {
    super.initState();
    _getInfo().then((resInfo) {
      _getPref().then((response) {
        _listSegment().then((resSegment) {
          if (prefCompanyField == "PMI") {
            setState(() {
              _segments.clear();
              _segments = prefSegments;          
            });
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.1,
        backgroundColor: colorPrimary,
        title: Text("Pencarian"),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
              child: TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                autocorrect: false,
                maxLines: 1,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  labelStyle: TextStyle(decorationStyle: TextDecorationStyle.solid)
                ),
              ),
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
            Container(
              child: ListTile(
                title: SearchChoices.single(
                  items: positions.map((item) {
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
                    child: Text("Pilih Jabatan", style: TextStyle(color: Colors.black),)
                  ),
                  searchHint: "Pilih Jabatan",
                  onChanged: (value) {
                    setState(() {
                      if (value == null) {
                        _selectedPosition = null;
                      } else {
                        _selectedPosition = value;
                      }
                    });
                  },
                  value: _selectedPosition,
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
            Container(
              margin: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
              child: FormBuilderDateTimePicker(
                attribute: 'date',
                onChanged: (val) => {
                  setState(() {
                    _dateFrom = val.toString().split(' ')[0];
                  })
                },
                inputType: InputType.date,
                decoration: const InputDecoration(
                  labelText: 'Dibuat Dari Tanggal',
                ),
                validator: (val) => null,
                format: DateFormat('yyyy-MM-dd'),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
              child: FormBuilderDateTimePicker(
                attribute: 'date',
                onChanged: (val) => {
                  setState(() {
                    _dateTo = val.toString().split(' ')[0];
                  })
                },
                inputType: InputType.date,
                decoration: const InputDecoration(
                  labelText: 'Dibuat Sampai Tanggal',
                ),
                validator: (val) => null,
                format: DateFormat('yyyy-MM-dd'),
              ),
            ),
            FlatButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => new RecapPage(
                  segment: _selectedSegment,
                  position: _selectedPosition,
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                  name: _nameController.text,
                )));
              },
              color: colorPrimary,
              child: Text("Cari", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
    );
  }
}