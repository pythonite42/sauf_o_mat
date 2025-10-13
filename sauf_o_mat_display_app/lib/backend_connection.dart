import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:jose/jose.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:sauf_o_mat_display_app/backend_testing.dart';

/// Singleton service to handle Salesforce JWT integration
class SalesforceService {
  static final SalesforceService _instance = SalesforceService._internal();
  factory SalesforceService() => _instance;
  SalesforceService._internal();

  String? _cachedToken;
  DateTime? _tokenExpiry;

  final String? consumerKey = dotenv.env['SF_CONSUMER_KEY'];
  final String? username = dotenv.env['SF_USERNAME'];
  final String? loginUrl = dotenv.env['SF_LOGIN_URL'];
  final String privateKeyPath = 'assets/server.key';
  final bool isTestVersion = dotenv.env['MODE'] == 'testing';

  /// Returns a valid access token, caching it until it expires
  Future<String> getAccessToken() async {
    if (_cachedToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken!;
    }

    return await _fetchNewToken();
  }

  /// Generates a signed JWT and exchanges it for a Salesforce access token
  Future<String> _fetchNewToken() async {
    final privateKeyPem = await File(privateKeyPath).readAsString();

    final key = JsonWebKey.fromPem(privateKeyPem);
    final jwtBuilder = JsonWebSignatureBuilder()
      ..jsonContent = {
        'iss': consumerKey,
        'sub': username,
        'aud': loginUrl,
        'exp': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 180, // 3 minutes
      }
      ..setProtectedHeader('alg', 'RS256')
      ..addRecipient(key, algorithm: 'RS256');

    final signedJwt = jwtBuilder.build().toCompactSerialization();

    final response = await http.post(
      Uri.parse('$loginUrl/services/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': signedJwt,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Salesforce token: ${response.body}');
    }

    final json = jsonDecode(response.body);
    _cachedToken = json['access_token'];
    _tokenExpiry = DateTime.now().add(Duration(minutes: 10)); // Short buffer

    return _cachedToken!;
  }

  /// Generic GET request to Salesforce API
  Future<Map<String, dynamic>> getRequest(String soql) async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$loginUrl/services/data/v61.0/query/?q=$soql'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      // Token may have expired early -> retry once
      _cachedToken = null;
      final retryToken = await getAccessToken();
      return await _retryGet(soql, retryToken);
    }

    if (response.statusCode != 200) {
      throw Exception('Salesforce API Error: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  /// Generic PATCH request to Salesforce API
  Future<void> patchRequest(String id, String table, Map body) async {
    final token = await getAccessToken();
    final uri = Uri.parse('$loginUrl/services/data/v61.0/sobjects/$table/$id');
    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      // Token may have expired -> retry once
      _cachedToken = null;
      final retryToken = await getAccessToken();
      final retryResponse = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $retryToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (retryResponse.statusCode < 200 || retryResponse.statusCode >= 300) {
        throw Exception('Salesforce PATCH Error: ${response.statusCode}, ${response.body}');
      }
      return;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Salesforce PATCH Error: ${response.statusCode}, ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _retryGet(String rawSoql, String token) async {
    var soql = rawSoql.replaceAll(" ", "+");
    final response = await http.get(
      Uri.parse('$loginUrl/services/data/v61.0/query/?q=$soql'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Salesforce API Error after retry: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  Future<List<Map>> getPageDiagram() async {
    if (isTestVersion) return TestBackendData().getPageDiagram();
    try {
      final data = await getRequest(
          'SELECT Punktzahl_Bargetr_nke__c , Punktzahl_Bier_Wein_Schorle__c , Punktzahl_Kaffee_Lutz__c , Punktzahl_Shots__c , NAME, StatusDisplay__c FROM Team__c');
      var records = data["records"];
      List<Map> returnData = [];
      for (var record in records) {
        returnData.add({
          "group": record["Name"],
          "longdrink": (record["Punktzahl_Bargetr_nke__c"]).toInt(),
          "beer": (record["Punktzahl_Bier_Wein_Schorle__c"]).toInt(),
          "shot": (record["Punktzahl_Shots__c"]).toInt(),
          "lutz": (record["Punktzahl_Kaffee_Lutz__c"]).toInt(),
          "status": record["StatusDisplay__c"],
        });
      }
      return returnData;
    } catch (e) {
      debugPrint('Error: $e');
      return [];
    }
  }

  Future<Map> getPageDiagramPopUp() async {
    if (isTestVersion) return TestBackendData().getPageDiagramPopUp();
    try {
      final data = await getRequest(
          //'SELECT Id, VisualizedAt__c, ChasingTeam__r.Name, WantedTeam__r.Name, WantedTeam__r.Logo__c, WantedTeam__r.Punktzahl__c FROM CatchUp__c WHERE VisualizedAt__c = null AND RankDeltaIsOne__c = true AND IsLessThan1Minute__c = true ORDER BY LastModifiedDate DESC LIMIT 1');
          'SELECT Id, VisualizedAt__c, ChasingTeam__r.Name, WantedTeam__r.Name, WantedTeam__r.Logo__c, WantedTeam__r.Punktzahl__c FROM CatchUp__c WHERE VisualizedAt__c = null AND RankDeltaIsOne__c = true ORDER BY LastModifiedDate DESC LIMIT 1');
      var record = data["records"][0];
      return {
        "showPopup": true,
        "popupDataId": record["Id"],
        "imageUrl": record["WantedTeam__r"]["Logo__c"] ?? "",
        "chaserGroupName": record["ChasingTeam__r"]["Name"],
        "leaderGroupName": record["WantedTeam__r"]["Name"],
        "leaderPoints": (record["WantedTeam__r"]["Punktzahl__c"]).toInt(),
      };
    } catch (e) {
      debugPrint('Salesforce Error getPageDiagramPopUp: $e');
      return {
        "showPopup": false,
        "popupDataId": "",
        "imageUrl": "",
        "chaserGroupName": "",
        "leaderGroupName": "",
        "leaderPoints": 0,
      };
    }
  }

  Future<bool> setPageDiagramVisualizedAt(String id, DateTime visualisedAt) async {
    if (isTestVersion) return true;
    try {
      patchRequest(id, "CatchUp__c", {"VisualizedAt__c": formatDateTime(visualisedAt)});
      return true;
    } catch (e) {
      debugPrint('Error: $e');
      return false;
    }
  }

  Future<List<Map>> getPageTop3() async {
    if (isTestVersion) return TestBackendData().getPageTop3();
    try {
      final data = await getRequest(
          'SELECT Anzahl_Bargetr_nke__c , Anzahl_Bier_Wein_Schorle__c , Anzahl_Kaffee_Lutz__c , AnzahlShots__c , Punktzahl__c, Logo__c FROM Team__c WHERE Rang__c < 4');
      var records = data["records"];
      List<Map> returnData = [];
      for (var record in records) {
        returnData.add({
          "longdrink": (record["Anzahl_Bargetr_nke__c"]).toInt(),
          "beer": (record["Anzahl_Bier_Wein_Schorle__c"]).toInt(),
          "shot": (record["AnzahlShots__c"]).toInt(),
          "lutz": (record["Anzahl_Kaffee_Lutz__c"]).toInt(),
          "punktzahl": (record["Punktzahl__c"]).toInt(),
          "groupLogo": record["Logo__c"] ?? "",
        });
      }
      return returnData;
    } catch (e) {
      debugPrint('Error: $e');
      return [];
    }
  }

  Future<List<Map>> getPageTop3BackgroundImages() async {
    if (isTestVersion) return TestBackendData().getPageTop3BackgroundImages();
    try {
      final data = await getRequest('SELECT ImageURL__c, Name__c FROM BackgroundImage__c');
      debugPrint(data["records"].toString());
      List<Map> returnData = data["records"].map<Map>((record) {
        return {
          "name": record["Name__c"] ?? "",
          "imageUrl": record["ImageURL__c"] ?? "",
        };
      }).toList();

      returnData.shuffle(Random());

      return returnData.take(3).toList();
    } catch (e) {
      debugPrint('Error: $e');
      return [];
    }
  }

  Future<Map> getPagePrize() async {
    if (isTestVersion) return TestBackendData().getPagePrize();
    try {
      final data = await getRequest('SELECT Logo__c, Punktzahl__c, NAME FROM Team__c WHERE Rang__c = 1');
      return {
        "logo": data["records"][0]["Logo__c"] ?? "",
        "name": data["records"][0]["Name"] ?? "",
        "points": (data["records"][0]["Punktzahl__c"]).toInt(),
      };
    } catch (e) {
      debugPrint('Error: $e');
      return {};
    }
  }

  Future<Map> getPageQuote() async {
    if (isTestVersion) return TestBackendData().getPageQuote();
    try {
      Map data = await getRequest(
          'SELECT Id, Comment1__c, Comment2__c, Comment3__c, Commentator__c, CommentatorHandle__c, ImageURL__c FROM SocialMediaComment__c WHERE VisualizedAt__c = null ORDER BY LastModifiedDate DESC LIMIT 1');
      debugPrint(data["records"].toString());
      if (data["records"].isEmpty) {
        data = await getRequest(
            'SELECT Id, Comment1__c, Comment2__c, Comment3__c, Commentator__c, CommentatorHandle__c, ImageURL__c FROM SocialMediaComment__c ORDER BY VisualizedAt__c ASC LIMIT 1');
      }
      debugPrint(data["records"].toString());

      var record = data["records"][0];
      List<String> quotes = [record["Comment1__c"] ?? "", record["Comment2__c"] ?? "", record["Comment3__c"] ?? ""];
      quotes.removeWhere((quote) => quote.trim().isEmpty);
      return {
        "recordId": record["Id"],
        "name": record["Commentator__c"] ?? "",
        "handle": record["CommentatorHandle__c"] ?? "",
        "quotes": quotes,
        "image": record["ImageURL__c"] ?? "",
      };
    } catch (e) {
      debugPrint('Error: $e');
      return {};
    }
  }

  Future<bool> setPageQuoteQueryUsed(String id, DateTime visualisedAt) async {
    if (isTestVersion) return true;
    try {
      patchRequest(id, "SocialMediaComment__c", {"VisualizedAt__c": formatDateTime(visualisedAt)});
      return true;
    } catch (e) {
      debugPrint('Error: $e');
      return false;
    }
  }

  Future<Map> getPageAdvertising() async {
    if (isTestVersion) return TestBackendData().getPageAdvertising();
    try {
      Map data = await getRequest(
          'SELECT Id, ImageURL__c, Subject__c, Description__c FROM Advertisement__c WHERE VisualizedAt__c = null ORDER BY LastModifiedDate DESC LIMIT 1');
      if (data["records"].isEmpty) {
        data = await getRequest(
            'SELECT Id, ImageURL__c, Subject__c, Description__c FROM Advertisement__c ORDER BY VisualizedAt__c ASC LIMIT 1');
      }
      debugPrint(data["records"].toString());
      return {
        "id": data["records"][0]["Id"],
        "headline": data["records"][0]["Subject__c"] ?? "",
        "text": data["records"][0]["Description__c"] ?? "",
        "image": data["records"][0]["ImageURL__c"] ?? "",
      };
    } catch (e) {
      debugPrint('Error: $e');
      return {};
    }
  }

  Future<bool> setPageAdvertisingVisualizedAt(String id, DateTime visualisedAt) async {
    if (isTestVersion) return true;
    try {
      patchRequest(id, "Advertisement__c", {"VisualizedAt__c": formatDateTime(visualisedAt)});
      return true;
    } catch (e) {
      debugPrint('Error: $e');
      return false;
    }
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(dateTime.toUtc());
  }
}
