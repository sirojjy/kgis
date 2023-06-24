import 'package:bpjt_k_gis_mobile_master/about.dart';
import 'package:bpjt_k_gis_mobile_master/change_avatar.dart';
import 'package:bpjt_k_gis_mobile_master/free_camera.dart';
import 'package:bpjt_k_gis_mobile_master/help.dart';
import 'package:bpjt_k_gis_mobile_master/utils/utils.dart';
import 'package:bpjt_k_gis_mobile_master/view/activity/activity_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/attendance/attendance_list_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/attendance/attendance_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/auth/login.dart';
import 'package:bpjt_k_gis_mobile_master/view/recap/recap_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/summary/summary_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/tracking/problem_list_page.dart';
import 'package:bpjt_k_gis_mobile_master/view/user/user_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'change_password.dart';
import 'helper/db.dart';

class DrawerBuild {
  Drawer drw(BuildContext context, String companyField) {
    return Drawer(
      child: Container(
        color: colorPrimary,
        child: ListView(
          children: [
            Container(
              height: 150.0,
              color: Colors.white,
              child: Align(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120.0,
                ),
              ),
            ),
            InkWell(
              onTap: (){},
              child: ListTile(
                title: Text('Home', style: TextStyle(color: Colors.white)),
                leading: Icon(Icons.home_outlined, color: Colors.white),
              ),
            ),

            companyField != null && (companyField == 'PMI' || companyField == 'PMO' || companyField == 'Tim Konsultan SIMK') ?
            // companyField != null ?
              Column(
                children: [
                  InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AttendancePage()));
                    },
                    child: ListTile(
                      title: Text('Absen', style: TextStyle(color: Colors.white)),
                      leading: Icon(Icons.check, color: Colors.white),
                    ),
                  )
                ],
              )
            : Container(),

            (companyField != null && companyField != 'Tim Konsultan SIMK') ?
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProblemListPage()));
              },
              child: ListTile(
                title: Text('Laporan Permasalahan', style: TextStyle(color: Colors.white)),
                leading: Icon(Icons.map_outlined, color: Colors.white),
              ),
            )
            : Container(),

            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityPage()));
              },
              child: ListTile(
                title: Text('Laporan Kegiatan', style: TextStyle(color: Colors.white)),
                leading: Icon(Icons.computer_outlined, color: Colors.white),
              ),
            ),

            (companyField != null && companyField == 'BPJT' || companyField == 'PMI' || companyField == 'PMO') ?
            Column(
              children: [
                companyField == 'BPJT' ?
                InkWell(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SummaryPage()));
                  },
                  child: ListTile(
                    title: Text('Ringkasan Data', style: TextStyle(color: Colors.white)),
                    leading: Icon(Icons.sticky_note_2_outlined, color: Colors.white),
                  ),
                )
                :
                Container(),

                companyField == 'BPJT' ?
                InkWell(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => UserPage()));
                  },
                  child: ListTile(
                    title: Text('Pengguna', style: TextStyle(color: Colors.white)),
                    leading: Icon(Icons.person_outline, color: Colors.white),
                  ),
                )
                :
                Container(),

                companyField == 'BPJT' || companyField == 'PMI' || companyField == 'PMO' ?
                InkWell(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceListPage()));
                  },
                  child: ListTile(
                    title: Text('Data Absensi', style: TextStyle(color: Colors.white)),
                    leading: Icon(Icons.photo_camera_outlined, color: Colors.white),
                  ),
                )
                :
                Container(),

                companyField == 'BPJT' ?
                InkWell(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RecapPage()));
                  },
                  child: ListTile(
                    title: Text('Rekap', style: TextStyle(color: Colors.white)),
                    leading: Icon(Icons.bar_chart_outlined, color: Colors.white),
                  ),
                )
                :
                Container()
              ],
            )
            : Container(),

            Divider(
              color: Colors.white,
            ),
            // InkWell(
            //   onTap: (){
            //     Navigator.push(context, MaterialPageRoute(builder: (context) => TestMapPage()));
            //   },
            //   child: ListTile(
            //     title: Text('Test Map', style: TextStyle(color: Colors.white)),
            //     leading: Icon(Icons.info_outline, color: Colors.white),
            //   ),
            // ),
            // InkWell(
            //   onTap: (){
            //     Navigator.push(context, MaterialPageRoute(builder: (context) => NoPositionPage()));
            //   },
            //   child: ListTile(
            //     title: Text('Test Posisi', style: TextStyle(color: Colors.white)),
            //     leading: Icon(Icons.info_outline, color: Colors.white),
            //   ),
            // ),
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => FreeCameraPage()));
              },
              child: ListTile(
                title: Text('Camera', style: TextStyle(color: Colors.white)),
                leading: Icon(Icons.camera_sharp, color: Colors.white),
              ),
            ),
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeAvatarPage()));
              },
              child: ListTile(
                title: Text('Ubah Foto Profil', style: TextStyle(color: Colors.white)),
                leading: Icon(Icons.image, color: Colors.white),
              ),
            ),
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordPage()));
              },
              child: ListTile(
                title: Text('Ubah Password', style: TextStyle(color: Colors.white)),
                leading: Icon(Icons.lock_outline, color: Colors.white),
              ),
            ),
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => HelpPage(url: "http://103.6.53.254:13480/bpjt-teknik/public/uploads/help_k_gis.pdf")));
              },
              child: ListTile(
                title: Text('Help', style: TextStyle(color: Colors.white)),
                leading: Icon(Icons.help_outline, color: Colors.white),
              ),
            ),
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => AboutPage()));
              },
              child: ListTile(
                title: Text('About', style: TextStyle(color: Colors.white)),
                leading: Icon(Icons.info_outline, color: Colors.white),
              ),
            ),
            InkWell(
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.clear();
                Db().deleteDb();
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginPage()), (Route<dynamic> route) => false);
              },
              child: ListTile(
                title: Text('Logout', style: TextStyle(color: Colors.white)),
                leading: Icon(Icons.power_settings_new_outlined, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}