import 'package:http/http.dart' as http;
import 'dart:convert';

const accessToken =
    'eyJ0bmsiOiJjb3JlL3Byb2QvMDBEMDYwMDAwMDFaSzVHRUFXIiwidmVyIjoiMS4wIiwia2lkIjoiQ09SRV9BVEpXVC4wMEQwNjAwMDAwMVpLNUcuMTcxMjg0NTU4MTQ5NSIsInR0eSI6InNmZGMtY29yZS10b2tlbiIsInR5cCI6IkpXVCIsImFsZyI6IlJTMjU2In0.eyJzY3AiOiJhcGkiLCJhdWQiOlsiaHR0cHM6Ly9obW1obXVsdGltZWRpYWhhdXNhZzktZGV2LWVkLmRldmVsb3AubXkuc2FsZXNmb3JjZS5jb20iXSwic3ViIjoidWlkOjAwNTA2MDAwMDBHOWd5N0FBQiIsIm5iZiI6MTc1NDM5Mjc4MywibXR5Ijoib2F1dGgiLCJzZmkiOiI2MzNlMjM1YWJkYmYyZDFlMTY4ZGVkMGY5NzEzOWU1ZGQwMzAxOTU1NWFjYWNlNTZhYWUyOWFlM2M0OGIxYzAzIiwicm9sZXMiOltdLCJpc3MiOiJodHRwczovL2htbWhtdWx0aW1lZGlhaGF1c2FnOS1kZXYtZWQuZGV2ZWxvcC5teS5zYWxlc2ZvcmNlLmNvbSIsImhzYyI6ZmFsc2UsImV4cCI6MTc1NDM5NDU5OCwiaWF0IjoxNzU0MzkyNzk4LCJjbGllbnRfaWQiOiIzTVZHOV9rWmNMZGU3VTVyZUNGVTdtdEFYLlViNHdZenhpUW52dFVUVGJ6Lk9KamMuN0VIa1hPWEdiODlfRXBxc3hCMUl0YmNNM0xQaGZlNlptbVJkIn0.KLB-8BGYBccm6bVDmWu60SP9APrVLQkSQhfmSBC2hzb2_WJjMnqwvrTVuRsDYJ0T79BtuG6QXl6UTZHUSWxuvP3NJwQsoJa58vL1sZeSp8qGwk0pEoyoiJNh3G9wVn0T_JpQ0RnKzw07S-mgP0qGAiOv3zu7QrybXySv0hScizrYLk5K6451MvzUGJHboUscaMwMAs_XanSi-1j34gGdy5E2APg6kUX5VKfgZjT6i20WBlEbyW58USjAO6yqMQvaVkxPiEnTvUWhUeYtAapldTGn-w6KsfRmHgJQIYls7zg-NTo7o24NZIJz6hs2ADbJwLlkgO_O-QpBAoF1Bclcug';
const instanceUrl = 'https://hmmhmultimediahausag9-dev-ed.develop.my.salesforce.com';

Future<dynamic> fetchSalesforceData(String soql) async {
  final url = Uri.parse('$instanceUrl/services/data/v59.0/query/?q=$soql');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Salesforce response from endpoint $soql: $data');
    return data;
  } else {
    print('Failed soql $soql: ${response.statusCode} - ${response.body}');
    return null;
  }
}

Future<int?> fetchSalesforceDataNavigationIndex() async {
  final data = await fetchSalesforceData('navigationIndex');
  return data;
}

Future<List<Map>> fetchSalesforceDataPageDiagram() async {
  var query = prepareSOQL(
      "SELECT Anzahl_Bargetr_nke__c , Anzahl_Bier_Wein_Schorle__c , Anzahl_Kaffee_Lutz__c , AnzahlShots__c , NAME FROM Team__c");
  final data = await fetchSalesforceData(query);
  print(data);
  return data is List ? List<Map>.from(data) : [];
}

String prepareSOQL(String rawSOQL) {
  return rawSOQL.replaceAll(" ", "+");
}
