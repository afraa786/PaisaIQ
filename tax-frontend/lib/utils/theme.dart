import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final alphaEdgeTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: const Color(0xFF0D1117),
  primaryColor: const Color(0xFF00C896),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF00C896),
    secondary: Color(0xFF00C896),
    background: Color(0xFF0D1117),
    surface: Color(0xFF161B22),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF0D1117),
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: GoogleFonts.inter(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.dark().textTheme,
  ).apply(bodyColor: Colors.white, displayColor: Colors.white),
  cardTheme: const CardThemeData(
    color: Color(0xFF161B22),
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  dividerColor: Colors.white12,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF161B22),
    selectedItemColor: Color(0xFF00C896),
    unselectedItemColor: Colors.white54,
  ),
);