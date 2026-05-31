import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Trading palette — pure black/white, green/red only for candles
const kBg        = Color(0xFF000000);
const kSurface   = Color(0xFF0F0F0F);
const kCard      = Color(0xFF141414);
const kBorder    = Color(0xFF222222);
const kWhite     = Color(0xFFFFFFFF);
const kGray1     = Color(0xFFAAAAAA);
const kGray2     = Color(0xFF555555);
const kGreen     = Color(0xFF26A69A); // candle up / profit
const kRed       = Color(0xFFEF5350); // candle down / loss

final alphaEdgeTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: kBg,
  primaryColor: kWhite,
  colorScheme: const ColorScheme.dark(
    primary: kWhite,
    secondary: kWhite,
    surface: kSurface,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kBg,
    foregroundColor: kWhite,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.spaceMono(
      color: kWhite,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
    iconTheme: const IconThemeData(color: kWhite),
  ),
  textTheme: GoogleFonts.spaceMonoTextTheme(
    ThemeData.dark().textTheme,
  ).apply(bodyColor: kWhite, displayColor: kWhite),
  cardTheme: const CardThemeData(
    color: kCard,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      side: BorderSide(color: kBorder),
    ),
  ),
  dividerColor: kBorder,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kWhite,
      foregroundColor: kBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      textStyle: GoogleFonts.spaceMono(fontWeight: FontWeight.w700),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: kWhite),
    ),
    labelStyle: const TextStyle(color: kGray1),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kBg,
    selectedItemColor: kWhite,
    unselectedItemColor: kGray2,
    selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
    unselectedLabelStyle: TextStyle(fontSize: 10),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: kSurface,
    selectedColor: kWhite,
    labelStyle: const TextStyle(color: kGray1, fontSize: 11),
    secondaryLabelStyle: const TextStyle(color: kBg, fontSize: 11),
    side: const BorderSide(color: kBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
);
