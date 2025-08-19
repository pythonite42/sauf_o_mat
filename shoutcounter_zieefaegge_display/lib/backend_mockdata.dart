import 'dart:async';
import 'dart:math';

/*
================================================================================================================
     Navigation
================================================================================================================
*/

class MockDataNavigation {
  Future<int> getPageIndex() async {
    await Future.delayed(Duration(seconds: 2));
    return 0;
  }
}

/*
================================================================================================================
     Page 0 - Bar Chart 
================================================================================================================
*/

class MockDataPage0 {
  Future<Map> getChartSettings() async {
    await Future.delayed(Duration(seconds: 2));
    return {
      "totalBarsVisible": 5,
      "groupNameSpaceFactor": 0.3,
    };
  }

  Future<List<Map>> getRandomChartData() async {
    // Die Datensätze müssen nicht sortiert sein, aber die Anzahl der Bargetränke (longdrinks) muss bereits doppelt sein

    await Future.delayed(Duration(seconds: 2));
    List<Map> result = [];
    int groupCount = 9; // Random().nextInt(15) + 2;
    for (var i = 0; i < groupCount; i++) {
      var longdrink = Random().nextInt(30) * 2;
      var beer = Random().nextInt(80);
      var shot = Random().nextInt(60);
      var lutz = Random().nextInt(60);
      var statusInt = Random().nextInt(3);
      var status = "gleichgeblieben";
      if (statusInt == 1) {
        status = "aufgestiegen";
      } else if (statusInt == 2) {
        status = "abgestiegen";
      }

      result.add({
        "group": "Gruppe ${i + 1}",
        "longdrink": longdrink,
        "beer": beer,
        "shot": shot,
        "lutz": lutz,
        "status": status,
      });
    }
    result.add({
      "group": "Wollbacher Stachelbiester",
      "longdrink": 25 * 2,
      "beer": 56,
      "shot": 22,
      "lutz": 37,
      "status": "gleichgeblieben"
    });
    /*  result.add({"group": "Gruppe 1", "longdrink": 3 * 2, "beer": 8, "shot": 4, "lutz": 1});
    result.add({"group": "Gruppe 2", "longdrink": 3 * 2, "beer": 6, "shot": 4, "lutz": 1});
    result.add({"group": "Gruppe 3", "longdrink": 3 * 2, "beer": 2, "shot": 4, "lutz": 1}); */
    return result;
  }

  Future<Map> getPopup() async {
    await Future.delayed(Duration(seconds: 2));
    return {
      "showPopup": false, //hier müssen wir kontrollieren ob das klappt, True vs. true macht einen Unterschied
      "imageUrl": "",
      "chaserGroupName": "Gruppe 1",
      "leaderGroupName": "Gruppe 2",
      "leaderPoints": 87,
      "headline": "Die Aufholjagd beginnt",
      "motivationalText": "Fast geschafft - Trinken, trinken, trinken!"
    };
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

/*
================================================================================================================
     Page 1 - Top3
================================================================================================================
*/

class MockDataPage1 {
  Future<List<Map>> getData() async {
    // Die Datensätze müssen nicht sortiert sein und dürfen auch mehr als nur die top3 sein
    // die Anzahl der Bargetränke (longdrinks) muss bereits doppelt sein

    await Future.delayed(Duration(seconds: 2));
    List<Map> result = [];
    int groupCount = 3; // Random().nextInt(15) + 2;
    for (var i = 0; i < groupCount; i++) {
      var longdrink = Random().nextInt(30) * 2;
      var beer = Random().nextInt(80);
      var shot = Random().nextInt(60);
      var lutz = Random().nextInt(60);
      result.add({
        "groupName": "Gruppe ${i + 1}",
        "groupLogo": "https://randomuser.me/api/portraits/men/1.jpg",
        "longdrink": longdrink,
        "beer": beer,
        "shot": shot,
        "lutz": lutz,
      });
    }
    return result;
  }
}

/*
================================================================================================================
     Page 2 - Prize 
================================================================================================================
*/

class MockDataPage2 {
  Future<Map> getPrizePageData() async {
    await Future.delayed(Duration(seconds: 2));
    return {
      "groupName": "Wollbacher Stachelbieschter",
      "remainingTimeSeconds": 304,
      "headline": 'Gewinne zwei Biersäulen!',
      "subline":
          'Sauft Sauft Sauft, zwei Säulen gehen auf unsSauft Sauft Sauft, zwei Säulen gehen auf unsSauft Sauft Sauft, zwei Säulen gehen auf unsSauft Sauft Sauft, zwei Säulen gehen auf unsSauft Sauft Sauft, zwei Säulen gehen auf uns',
      "imagePrize": "https://picsum.photos/300/200",
      "groupLogo": "https://randomuser.me/api/portraits/men/1.jpg",
    };
  }
}

/*
================================================================================================================
     Page 3 - Schedule 
================================================================================================================
*/

class MockDataPage3 {
  Future<Map> getImage() async {
    await Future.delayed(Duration(seconds: 2));
    return {"imageUrl": ""};
  }
}

/*
================================================================================================================
     Page 4 - Quote 
================================================================================================================
*/

class MockDataPage4 {
  Future<Map> getData() async {
    await Future.delayed(Duration(seconds: 2));
    return {
      "image": "",
      "name": "Wollbacher Stachel",
      "quote": "Der Kopf tut weh, die Füße stinken, höchste Zeit ein Bier zu trinken!",
    };
  }
}

/*
================================================================================================================
     Page 5 - Advertising 
================================================================================================================
*/

class MockDataPage5 {
  Future<Map> getData() async {
    await Future.delayed(Duration(seconds: 2));
    return {
      "image": "",
      "text": "Kauft diesen super tollen über geilen Trichter. Mehr trichtern - mehr saufen.",
    };
  }
}
