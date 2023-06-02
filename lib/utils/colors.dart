import 'dart:ui';
import 'package:flutter/material.dart';

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

Color colorPrimary = HexColor("28324E");
Color colorSecondary = HexColor("263554");
Color colorTertiary = HexColor("003C69");
Color colorCurve = Color.fromRGBO(97, 10, 165, 0.8);
Color colorCurveSecondary = Color.fromRGBO(97, 10, 155, 0.6);
Color backgroundColor = Colors.grey.shade200;
Color textPrimaryColor = Colors.black87;

//textColors
Color textPrimaryLightColor = Colors.white;
Color textPrimaryDarkColor = Colors.black;
Color textSecondaryLightColor = Colors.black87;
Color textSecondary54 = Colors.black54;
Color textSecondaryDarkColor = Colors.blue;
Color hintTextColor = Colors.white30;
Color bucketDialogueUserColor = Colors.red;
Color disabledTextColour = Colors.black54;
Color placeHolderColor = Colors.black26;
Color dividerColor = Colors.black26;
