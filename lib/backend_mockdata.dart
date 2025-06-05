import 'dart:async';
import 'dart:math';

/*
================================================================================================================
     Page 0 - Bar Chart 
================================================================================================================
*/

class MockDataPage0 {
  Future<Map> getChartSettings() async {
    await Future.delayed(Duration(seconds: 2));
    return {"totalBarsVisible": 5, "gridInterval": 10, "groupNameSpaceFactor": 0.15, "emptyCountRightOfFirst": 10};
  }

  Future<List<Map>> getRandomChartData() async {
    await Future.delayed(Duration(seconds: 2));
    List<Map> result = [];
    int groupCount = 9; // Random().nextInt(15) + 2;
    for (var i = 0; i < groupCount; i++) {
      var longdrink = Random().nextInt(30) * 2;
      var beer = Random().nextInt(80);
      var shot = Random().nextInt(60);
      var lutz = Random().nextInt(60);
      result.add({"group": "Gruppe ${i + 1}", "longdrink": longdrink, "beer": beer, "shot": shot, "lutz": lutz});
    }
    return result;
  }
}

/* 
class ChartData {
  ChartData({
    this.group,
    this.longdrink,
    this.beer,
    this.shot,
    this.lutz,
  });

  final String? group;
  final int? longdrink;
  final int? beer;
  final int? shot;
  final int? lutz;

  int get total => (longdrink ?? 0) + (shot ?? 0) + (beer ?? 0) + (lutz ?? 0);
} 

List<ChartData> chartData = [
  ChartData(group: 'Gruppe1', longdrink: 30 * 2, beer: 18, shot: 6, lutz: 12),
  ChartData(group: 'Gruppe2', longdrink: 8 * 2, beer: 19, shot: 8, lutz: 15),
  ChartData(group: 'Gruppe3', longdrink: 10 * 2, beer: 22, shot: 11, lutz: 20),
  ChartData(group: 'Gruppe4', longdrink: 15 * 2, beer: 25, shot: 16, lutz: 40),
  ChartData(group: 'Gruppe5', longdrink: 2 * 2, beer: 30, shot: 21, lutz: 13),
  ChartData(group: 'Gruppe6', longdrink: 18 * 2, beer: 35, shot: 25, lutz: 11),
  ChartData(group: 'Gruppe7', longdrink: 5 * 2, beer: 35, shot: 25, lutz: 11),
  ChartData(group: 'Gruppe8', longdrink: 12 * 2, beer: 25, shot: 15, lutz: 16),
];
*/
