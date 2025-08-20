import 'package:flutter/material.dart';

class MySize {
  double h = 0.0; //height
  double w = 0.0; //width
  BuildContext context;

  MySize(this.context) {
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height - fullscreenIconSize;
  }
}

double fullscreenIconSize = 20;

class CustomDurations {
  // ##### frontend ######################

  //general
  int indexNavigationChange = 10;
  int checkIfNavigationIndexChanged =
      1; //this is an internal duration and should not be changed. It does not affect the backend or my server communication
  int navigationTransition = 800;

  //page diagram
  int reloadDataDiagram = 7;
  int chartAutoScroll = 8; //every x seconds the chart scrolls one bar down
  int speedChartScroll = 500;

  //page top3
  int reloadDataTop3 = 7;

  //page prize
  int flashSpeed = 400;
  int reloadDataPrize = 10;
  int reloadDataPrizeUnder20sec = 1;

  //page quote
  int reloadDataQuote = 10;
  int switchQuote = 4;
  int fadeTransistion = 800;

  //page advertising
  int reloadDataAdvertising = 10;

  // ##### salesforce ######################

  int catchUpValidUntil = 60; //how long is a catchUp eligible for visualisation
}

class GlobalSettings {
  // page prize
  int flashThreshold = 60;
  int redThreshold = 300;
  DateTime timeFirstPrize = DateTime(2025, 08, 20, 10, 07);
}
