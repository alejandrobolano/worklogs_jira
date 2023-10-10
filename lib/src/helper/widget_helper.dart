import 'dart:math';

import 'package:flutter/material.dart';

class WidgetHelper {
  static void showMessageSnackBar(BuildContext context, String text) {
    final snackBar = SnackBar(
      showCloseIcon: true,
      closeIconColor: Theme.of(context).secondaryHeaderColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      content: Text(text),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static Color getRandomColor() {
    const colores = Colors.primaries;
    final random = Random();
    final index = random.nextInt(colores.length);
    return colores[index];
  }
}
