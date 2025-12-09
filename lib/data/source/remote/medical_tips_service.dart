import 'dart:convert';
import 'dart:io';

import '../../../core/utils/constant/api_url.dart';
import '../../model/medical_tips_model.dart';

class MedicalTipsService {
  Future<MedicalTip> getDailyTip() async {
    try {
      final httpClient = HttpClient();
      final urlString = EnvManager.medicalTips;
      if (urlString.isEmpty) {
        throw Exception("Error: MEDICAL_TIPS_URL is empty");
      }
      final request = await httpClient.getUrl(Uri.parse(urlString));
      final response = await request.close();

      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        final json = jsonDecode(stringData);
        return MedicalTip.fromJson(json);
      } else {
        throw Exception('Failed to load medical tip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching medical tip: $e');
    }
  }
}
