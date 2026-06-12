import 'package:flutter/material.dart';

class AppColors {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(BuildContext context) {
    return isDark(context) ? const Color(0xff071A2F) : const Color(0xffEAF6FF);
  }

  static Color card(BuildContext context) {
    return isDark(context) ? const Color(0xff102A46) : Colors.white;
  }

  static Color softCard(BuildContext context) {
    return isDark(context) ? const Color(0xff183A5C) : const Color(0xffEEF7FF);
  }

  static Color iconBg(BuildContext context) {
    return isDark(context) ? const Color(0xff183A5C) : const Color(0xffDCEEFF);
  }

  static Color primary(BuildContext context) {
    return const Color(0xff185FA5);
  }

  static Color title(BuildContext context) {
    return isDark(context) ? Colors.white : const Color(0xff0C447C);
  }

  static Color subtitle(BuildContext context) {
    return isDark(context) ? const Color(0xffAFC7DD) : const Color(0xff7A9AB5);
  }

  static Color border(BuildContext context) {
    return isDark(context)
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);
  }

  static Color divider(BuildContext context) {
    return isDark(context)
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.withOpacity(0.18);
  }
}
