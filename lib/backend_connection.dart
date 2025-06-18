import 'package:http/http.dart' as http;
import 'dart:convert';

const accessToken = 'YOUR_ACCESS_TOKEN';
const instanceUrl = 'https://your-instance.salesforce.com';

Future<dynamic> fetchSalesforceData(String endpoint) async {
  final url = Uri.parse('$instanceUrl/services/data/v59.0/sobjects/$endpoint');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Salesforce response from endpoint $endpoint: $data');
    return data;
  } else {
    print('Failed endpoint $endpoint: ${response.statusCode} - ${response.body}');
    return null;
  }
}

Future<int?> fetchSalesforceDataNavigationIndex() async {
  final data = await fetchSalesforceData('navigationIndex');
  return data;
}

Future<List<Map>> fetchSalesforceDataPageDiagram() async {
  final data = await fetchSalesforceData('teams_cc');
  return data is List ? List<Map>.from(data) : [];
}
