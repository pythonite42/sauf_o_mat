import 'package:flutter/material.dart';

class MySize {
  double h = 0.0; //height
  double w = 0.0; //width
  BuildContext context;

  MySize(this.context) {
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height - GlobalSettings.fullscreenIconSize;
  }
}

class CustomDurations {
  // ##### frontend ######################

  //general
  static const int indexNavigationChange = 10;
  static const int checkIfNavigationIndexChanged =
      1; //this is an internal duration and should not be changed. It does not affect the backend or my server communication
  static const int navigationTransition = 800;
  static const int changeToPrizePageBeforePrizeTime =
      5 * 60; //seconds before prize time the display changes to prize page
  static const int stayOnPrizePageAfterPrizeTime =
      60; //seconds after prize time the display changes back to normal navigation

  //page diagram
  static const int reloadDataDiagram = 7;
  static const int chartAutoScroll = 8; //every x seconds the chart scrolls one bar down
  static const int speedChartScroll = 500;
  static const int showPopup = 10;
  static const int popUpCooldown = 20; //after a popup was shown, wait x seconds until another popup can be shown

  //page top3
  static const int reloadDataTop3 = 7;

  //page prize
  static const int flashSpeed = 400;
  static const int reloadDataPrize = 10;
  static const int reloadDataPrizeUnder20sec = 1;

  //page quote
  static const int reloadDataQuote = 10;
  static const int switchQuote = 4;
  static const int fadeTransistion = 800;

  // ##### salesforce ######################

  static const int catchUpValidUntil = 60; //how long is a catchUp eligible for visualisation
}

class GlobalSettings {
  static const double fullscreenIconSize = 20;

  // page diagram
  static const int totalBarsVisible = 5;
  static const int totalGridLinesVisible = 5;
  static const double groupNameSpaceFactor = 0.3; //Anteilig an ganzer Breite
  // page prize
  static const int flashThreshold = 60;
  static const int redThreshold = 300;
  static List<DateTime> prizeTimes = [
    DateTime(2025, 09, 03, 10, 52),
    DateTime(2025, 09, 03, 10, 53),
    DateTime(2025, 09, 03, 11, 01),
  ];

  static const newspaperTitle = "The Guggeball Times"; //"Zieefägge Allgemeine"
}
