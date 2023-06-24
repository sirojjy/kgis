import 'dart:convert';

import 'package:bpjt_k_gis_mobile_master/utils/colors.dart';
import 'package:bpjt_k_gis_mobile_master/view/summary/summary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SummarySearchPage extends StatefulWidget {
  @override
  SummarySearchPageState createState() => SummarySearchPageState();
}

class SummarySearchPageState extends State<SummarySearchPage> {
  late String _dateFrom;
  late String _dateTo;
  List prefSegments = [];

  var prefId;
  var prefName;
  var prefCompany;
  var prefCompanyField;
  var prefPhone;
  var prefEmail;
  var prefRoleId;
  var prefIsApprove;
  var prefSegment;
  
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
    _getPref().then((response) {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.1,
        backgroundColor: colorPrimary,
        title: const Text("Pencarian"),
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
              child: FormBuilderDateTimePicker(
                name: 'date',
                onChanged: (val) => {
                  setState(() {
                    _dateFrom = val.toString().split(' ')[0];
                  })
                },
                inputType: InputType.date,
                decoration: const InputDecoration(
                  labelText: 'Dari Tanggal',
                ),
                validator: (val) => null,
                format: DateFormat('yyyy-MM-dd'),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
              child: FormBuilderDateTimePicker(
                name: 'date',
                onChanged: (val) => {
                  setState(() {
                    _dateTo = val.toString().split(' ')[0];
                  })
                },
                inputType: InputType.date,
                decoration: const InputDecoration(
                  labelText: 'Sampai Tanggal',
                ),
                validator: (val) => null,
                format: DateFormat('yyyy-MM-dd'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SummaryPage(
                  dateFrom: _dateFrom,
                  dateTo: _dateTo
                )));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
              ),
              child: const Text("Cari", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
    );
  }
}