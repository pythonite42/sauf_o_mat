/*
Maximale Zeichenanzahlen: 

Name FROM Team__c -> 20 //wäre ideal damit es beim Diagramm ganz angezeigt wird
Name FROM Team__c -> 30 //darf nicht länger sein weil es sonst an wichtigen Stellen wirklich blöd aussieht

ChasingTeam__r.Name FROM CatchUp__c -> 30 //darf nicht länger sein weil es sonst an wichtigen Stellen wirklich blöd aussieht
WantedTeam__r.Name FROM CatchUp__c -> 30 //darf nicht länger sein weil es sonst an wichtigen Stellen wirklich blöd aussieht

Name__c FROM BackgroundImage__c -> 18

Commentator__c FROM SocialMediaComment__c -> 18
CommentatorHandle__c FROM SocialMediaComment__c -> 18
Comment1__c FROM SocialMediaComment__c -> 95
Comment2__c FROM SocialMediaComment__c -> 95
Comment3__c FROM SocialMediaComment__c -> 95

Subject__c FROM Advertisement__c -> 14
Description__c FROM Advertisement__c -> 117

Überschreitung ergibt keinen Fehler weil text abgeschnitten wird falls er zu lang ist
*/

class TestBackendData {
  Future<List<Map>> getPageDiagram() async {
    return List.filled(3, {
      "group": getXLetters(20), //irrelevant weil ellipsis
      "longdrink": 99999,
      "beer": 99999,
      "shot": 99999,
      "lutz": 99999,
      "status": "aufgestiegen",
    });
  }

  Future<Map> getPageDiagramPopUp() async {
    return {
      "showPopup": true,
      "popupDataId": "",
      "imageUrl": "https://ucarecdn.com/d56cc060-e516-46ed-b4e6-c743621e14a4/",
      "chaserGroupName": getXLetters(30),
      "leaderGroupName": getXLetters(30),
      "leaderPoints": 999999999,
    };
  }

  Future<List<Map>> getPageTop3() async {
    return List.filled(3, {
      "longdrink": 9999,
      "beer": 9999,
      "shot": 9999,
      "lutz": 9999,
      "punktzahl": 9999 * 4,
      "groupLogo": "https://ucarecdn.com/d56cc060-e516-46ed-b4e6-c743621e14a4/",
    });
  }

  Future<List<Map>> getPageTop3BackgroundImages() async {
    return List.filled(3, {
      "name": getXLetters(18), // 18 lassen auch wenns zu viel ist
      "imageUrl": "https://ucarecdn.com/d56cc060-e516-46ed-b4e6-c743621e14a4/",
    });
  }

  Future<Map> getPagePrize() async {
    return {
      "logo": "https://ucarecdn.com/d56cc060-e516-46ed-b4e6-c743621e14a4/",
      "name": getXLetters(30),
      "points": 9999,
    };
  }

  Future<Map> getPageQuote() async {
    return {
      "recordId": "",
      "name": getXLetters(18),
      "handle": getXLetters(18),
      "quotes": [
        getXLetters(95),
        getXLetters(95),
        getXLetters(95),
      ],
      "image": "https://ucarecdn.com/d56cc060-e516-46ed-b4e6-c743621e14a4/",
    };
  }

  Future<Map> getPageAdvertising() async {
    return {
      "id": "",
      "headline": getXLetters(14),
      "text": getXLetters(117),
      "image": "https://ucarecdn.com/d56cc060-e516-46ed-b4e6-c743621e14a4/",
    };
  }

  String getXLetters(int amount) => List.filled(amount, "w").join();
}
