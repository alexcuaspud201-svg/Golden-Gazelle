import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dr_ai/core/utils/constant/api_url.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GenerativeAiWebService {
  static final Dio _dio = Dio();

  static Future<String?> postData({required List<Content> content}) async {
    try {
      final String model = EnvManager.generativeModelVersion;
      final String apiKey = EnvManager.generativeModelApiKey;
      log("!!! WE ARE USING DIO V1 !!! model: $model");
      final String url =
          'https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$apiKey';

      // Manually serialize Content list to JSON
      final List<Map<String, dynamic>> contentsJson = content.map((c) {
        return {
          'parts': c.parts.map((p) {
            if (p is TextPart) {
              return {'text': p.text};
            }
             // Fallback for other part types if any (though TextPart is primary)
             return {'text': ''};
          }).toList(),
          'role': c.role,
        };
      }).toList();

      final data = {'contents': contentsJson};

      log("Sending request to: $url");
      log("Payload: ${jsonEncode(data)}");

      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      log("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        
        // Check for safety blocks
        if (responseData['promptFeedback'] != null && 
            responseData['promptFeedback']['blockReason'] != null) {
          return "Lo siento, no puedo responder a eso por razones de seguridad (${responseData['promptFeedback']['blockReason']}).";
        }

        if (responseData['candidates'] != null && 
            (responseData['candidates'] as List).isNotEmpty) {
          final candidate = responseData['candidates'][0];
          
          if (candidate['finishReason'] == 'SAFETY') {
             return "Respuesta bloqueada por filtros de seguridad.";
          }

          if (candidate['content'] != null && 
              candidate['content']['parts'] != null && 
              (candidate['content']['parts'] as List).isNotEmpty) {
            final String text = candidate['content']['parts'][0]['text'];
            final cleanResponse = text.trim();
            log('response: $cleanResponse');
            return cleanResponse;
          }
        }
        return "Lo siento, no pude generar una respuesta (Respuesta vacía).";
      } else {
        log("API Error: ${response.statusCode} - ${response.statusMessage}");
        throw Exception("API Error: ${response.statusCode}");
      }

    } catch (err) {
      log("Error in postData: $err");
      if (err is DioException) {
         log("Dio Error: ${err.response?.data}");
         throw Exception(err.response?.data?['error']?['message'] ?? err.message);
      }
      throw Exception(err.toString());
    }
  }

  // Stream data is kept as placeholder or can be converted similarly if needed.
  // For now, consistent with previous behavior only postData was critical.
  static Future<void> streamData({required String text}) async {
    // Stream implementation skipped for REST migration priority
    log("Stream data not implemented in REST mode");
  }
}
