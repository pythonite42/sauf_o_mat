import 'dart:convert';
import 'dart:io';
import 'package:jose/jose.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

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
    try {
      final data = await getRequest(
          'SELECT Anzahl_Bargetr_nke__c , Anzahl_Bier_Wein_Schorle__c , Anzahl_Kaffee_Lutz__c , AnzahlShots__c , NAME, StatusDisplay__c FROM Team__c');
      var records = data["records"];
      List<Map> returnData = [];
      for (var record in records) {
        returnData.add({
          "group": record["Name"],
          "longdrink": (record["Anzahl_Bargetr_nke__c"]).toInt(),
          "beer": (record["Anzahl_Bier_Wein_Schorle__c"]).toInt(),
          "shot": (record["AnzahlShots__c"]).toInt(),
          "lutz": (record["Anzahl_Kaffee_Lutz__c"]).toInt(),
          "status": record["StatusDisplay__c"],
        });
      }
      return returnData;
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<Map> getPageDiagramPopUp() async {
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
      print('Salesforce Error getPageDiagramPopUp: $e');
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
    try {
      String formattedDate = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(visualisedAt.toUtc());
      patchRequest(id, "CatchUp__c", {"VisualizedAt__c": formattedDate});
      return true;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<List<Map>> getPageTop3() async {
    try {
      final data = await getRequest(
          'SELECT Anzahl_Bargetr_nke__c , Anzahl_Bier_Wein_Schorle__c , Anzahl_Kaffee_Lutz__c , AnzahlShots__c , NAME, Logo__c FROM Team__c WHERE Rang__c < 4');
      var records = data["records"];
      List<Map> returnData = [];
      for (var record in records) {
        returnData.add({
          "groupName": record["Name"],
          "longdrink": (record["Anzahl_Bargetr_nke__c"]).toInt(),
          "beer": (record["Anzahl_Bier_Wein_Schorle__c"]).toInt(),
          "shot": (record["AnzahlShots__c"]).toInt(),
          "lutz": (record["Anzahl_Kaffee_Lutz__c"]).toInt(),
          "groupLogo": record["Logo__c"] ?? "",
        });
      }
      return returnData;
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<bool> setPageQueryUsed(String id, bool wasUsed) async {
    try {
      patchRequest(id, "SocialMediaComment__c", {"WasUsed__c": wasUsed});
      return true;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<String> getPagePrize() async {
    try {
      final data = await getRequest('SELECT Logo__c FROM Team__c WHERE Rang__c = 1');
      return data["records"][0]["Logo__c"] ?? "";
    } catch (e) {
      print('Error: $e');
      return "";
    }
  }
}
