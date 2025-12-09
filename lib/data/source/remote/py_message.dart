import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../../../core/utils/constant/api_url.dart';

//! POST
class MessageWebService {
  // static Dio dio = Dio(); // Removed

  static Future postData({required Map<String, dynamic> data}) async {
    try {
      final urlString = EnvManager.pyDrAi;
      if (urlString.isEmpty) return "Error: Configuración de API faltante (PY_DR_AI)";
      final url = Uri.parse(urlString);
      final response = await http.post(
        url,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

      log('[${response.statusCode}] Data posted successfully!');
      log("DATA: ${response.body}");
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
         final decodedData = jsonDecode(response.body);
         return decodedData['message'];
      } else {
         throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (err) {
      log(err.toString());
      return Future.error(
          "pyDrAi error: $err", StackTrace.fromString("this is the trace"));
    }
  }
}
