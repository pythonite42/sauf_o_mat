import 'dart:convert';
import 'dart:io';
import 'package:jose/jose.dart';
import 'package:http/http.dart' as http;

/// Singleton service to handle Salesforce JWT integration
class SalesforceService {
  static final SalesforceService _instance = SalesforceService._internal();
  factory SalesforceService() => _instance;
  SalesforceService._internal();

  String? _cachedToken;
  DateTime? _tokenExpiry;

  final String consumerKey = '3MVG9_kZcLde7U5reCFU7mtAX.Ub4wYzxiQnvtUTTbz.OJjc.7EHkXOXGb89_EpqsxB1ItbcM3LPhfe6ZmmRd';
  final String username = 'simon.weiske@hmmh.de';
  final String loginUrl = 'https://hmmhmultimediahausag9-dev-ed.develop.my.salesforce.com/';
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

  Future<List<Map>> fetchSalesforceDataPageDiagram() async {
    try {
      final data = await getRequest(
          'SELECT Anzahl_Bargetr_nke__c , Anzahl_Bier_Wein_Schorle__c , Anzahl_Kaffee_Lutz__c , AnzahlShots__c , NAME FROM Team__c');
      var records = data["records"];
      List<Map> returnData = [];
      for (var record in records) {
        returnData.add({
          "group": record["Name"],
          "longdrink": (record["Anzahl_Bargetr_nke__c"]).toInt(),
          "beer": (record["Anzahl_Bier_Wein_Schorle__c"]).toInt(),
          "shot": (record["AnzahlShots__c"]).toInt(),
          "lutz": (record["Anzahl_Kaffee_Lutz__c"]).toInt(),
          "status": record["Status"],
        });
      }
      return returnData;
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}
