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

late final dynamic customDurations;

class CustomDurationsProduction {
  // ##### frontend ######################

  //general
  final int indexNavigationChange = 120;
  final int navigationTransition = 1200;
  final int changeToPrizePageBeforePrizeTime = 5 * 60; //seconds before prize time the display changes to prize page
  final int stayOnPrizePageAfterPrizeTime = 60; //seconds after prize time the display changes back to normal navigation

  //page diagram
  final int reloadDataDiagram = 7;
  final int chartAutoScroll = 8; //every x seconds the chart scrolls one bar down
  final int speedChartScroll = 500;
  final int showPopup = 25;
  final int popUpCooldown = 20; //after a popup was shown, wait x seconds until another popup can be shown
  final int popUpMillisecondsBetweenShotsMinimum = 200;
  final int popUpMillisecondsBetweenShotsMaximum = 800; //real maximum is minimum + maximum (e.g. 200 + 800 = 1000)
  final int popUpShotAnimation = 100;

  //page top3
  final int reloadDataTop3 = 7;

  //page prize
  final int flashSpeed = 400;
  final int reloadDataPrize = 10;
  final int reloadDataPrizeUnder20sec = 1;
  final int delayPrizePopUp = 2;

  //page quote
  final int switchQuote = 6;
  final int carouselTransistion = 800;

  // ##### salesforce ######################

  final int catchUpValidUntil = 60; //how long is a catchUp eligible for visualisation
  final int diagramStatusAufgestiegenAbgestiegen = 20; //seconds a group is marked as "aufgestiegen" or "abgestiegen"
}

class CustomDurationsTest {
  // ##### frontend ######################

  //general
  final int indexNavigationChange = 10;
  final int navigationTransition = 800;
  final int changeToPrizePageBeforePrizeTime = 5 * 60; //seconds before prize time the display changes to prize page
  final int stayOnPrizePageAfterPrizeTime = 60; //seconds after prize time the display changes back to normal navigation

  //page diagram
  final int reloadDataDiagram = 7;
  final int chartAutoScroll = 8; //every x seconds the chart scrolls one bar down
  final int speedChartScroll = 500;
  final int showPopup = 10;
  final int popUpCooldown = 20; //after a popup was shown, wait x seconds until another popup can be shown
  final int popUpMillisecondsBetweenShotsMinimum = 200;
  final int popUpMillisecondsBetweenShotsMaximum = 400; //real maximum is minimum + maximum (e.g. 200 + 400 = 600)
  final int popUpShotAnimation = 100;

  //page top3
  final int reloadDataTop3 = 7;

  //page prize
  final int flashSpeed = 400;
  final int reloadDataPrize = 10;
  final int reloadDataPrizeUnder20sec = 1;
  final int delayPrizePopUp = 2;

  //page quote
  final int switchQuote = 4;
  final int carouselTransistion = 800;

  // ##### salesforce ######################

  final int catchUpValidUntil = 60; //how long is a catchUp eligible for visualisation
  final int diagramStatusAufgestiegenAbgestiegen = 20; //seconds a group is marked as "aufgestiegen" or "abgestiegen"
}

class GlobalSettings {
  static const double fullscreenIconSize = 20;
  static DateTime lastPerformance = DateTime(2025, 11, 29, 23, 45);

  // page diagram
  static const int totalBarsVisible = 5;
  static const int totalGridLinesVisible = 5;
  static const double groupNameSpaceFactor = 0.37; //Anteilig an ganzer Breite
  static const int popUpMaxShotCounts = 7;
  // page prize
  static const int flashThreshold = 60;
  static const int redThreshold = 300;
  static List<String> prizeNames = [
    "Cowboyhut und 0,0003 Meilen Shots",
    "Cowboyhut und 39 Zoll Shots",
    "Cowboyhut und eine Säule",
  ];
  static List<DateTime> prizeTimes = [
    DateTime(2025, 11, 29, 22, 45),
    DateTime(2025, 11, 29, 23, 30),
    DateTime(2025, 11, 30, 00, 45),
  ];

  static const newspaperTitle = "The Guggeball Times"; //"Zieefägge Allgemeine"

  // ##### salesforce ######################
  static const int catchUpShownAtPointsDelta = 10; //minimum points difference to show a catchUp
}
