import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://3094-202-53-15-70.ngrok-free.app';

  Future<List<dynamic>> getMissedCalls(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/getMissedCalls?userId=$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }
}
