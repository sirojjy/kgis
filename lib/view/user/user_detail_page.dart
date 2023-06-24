import 'package:bpjt_k_gis_mobile_master/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bpjt_k_gis_mobile_master/helper/main_helper.dart';

class UserDetailPage extends StatefulWidget {
  final id;
  final name;
  final company;
  final phone;
  final email;
  final roleId;
  final isApprove;
  final createdAt;
  final updatedAt;
  final position;
  final userSegment;
  final companyField;

  UserDetailPage({
    this.id,
    this.name,
    this.company,
    this.phone,
    this.email,
    this.roleId,
    this.isApprove,
    this.createdAt,
    this.updatedAt,
    this.position,
    this.userSegment,
    this.companyField
  });

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pengguna'),
        backgroundColor: colorPrimary,
      ),
      body: bodyDetail(context)
    );
  }

  Widget bodyDetail(context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 5.0),
              ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(widget.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0))
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dibuat Tanggal :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(date(DateTime.parse(widget.createdAt)))
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HP :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.phone == null || widget.phone == "" ? '-' : widget.phone)
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.email == null || widget.email == "" ? '-' : widget.email)
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jabatan :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.position == null || widget.position == "" ? '-' : widget.position)
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Field :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.companyField == null || widget.companyField == "" ? '-' : widget.companyField)
                  ],
                ),
              ), 
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Segment :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.userSegment == null || widget.userSegment == "" ? '-' : widget.userSegment)
                  ],
                ),
              ),
            ],
          ),
        ),
        // Container(
        //   child: ,
        // )
      ],
    );
  }
}