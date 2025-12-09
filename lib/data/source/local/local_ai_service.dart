import 'dart:async';
import 'dart:developer';
import 'package:flutter_tts/flutter_tts.dart';

class LocalAiService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _capturedTtsInit = false;

  static Future<void> _initTts() async {
    if (_capturedTtsInit) return;
    try {
      await _flutterTts.setLanguage("es-ES");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      _capturedTtsInit = true;
    } catch (e) {
      log("TTS Init Error: $e");
    }
  }

  static Future<String> generateResponse({
    required List<String> history,
    required String newMessage,
  }) async {
    await _initTts();
    
    // 1. Normalize input
    final input = newMessage.toLowerCase();

    // 2. Medical Filter (Simulated TFLite Model)
    // In a real app, this would use tflite_flutter to run a text classification model.
    // Here we use keyword matching as a robust offline fallback.
    if (_isMedicalQuery(input)) {
        final response = _generateMedicalAdvice(input);
        _speak(response);
        return response;
    } else {
        const response = "Soy un asistente médico. Por favor, hazme una pregunta relacionada con la salud, hospitales o medicamentos.";
        _speak(response);
        return response;
    }
  }

  static bool _isMedicalQuery(String input) {
    const medicalKeywords = [
      'dolor', 'fiebre', 'gripe', 'tos', 'medico', 'médico', 'hospital', 
      'pastilla', 'receta', 'sintoma', 'síntoma', 'cabeza', 'estomago', 
      'estómago', 'brazo', 'pierna', 'sangre', 'corazon', 'corazón',
      'diabetes', 'presion', 'presión', 'cancer', 'cáncer', 'ayuda',
      'ambulancia', 'emergencia', 'doctor', 'cita', 'salud', 'enfermedad'
    ];
    
    // Also allow greetings to be polite
    if (['hola', 'buenos dias', 'buenas tardes', 'que tal'].any((w) => input.contains(w))) {
      return true;
    }

    return medicalKeywords.any((keyword) => input.contains(keyword));
  }

  static String _generateMedicalAdvice(String input) {
    // Knowledge Base Simulation
    if (input.contains('hola') || input.contains('buenos')) {
      return "¡Hola! Soy Dr. AI. ¿En qué puedo ayudarte hoy con tu salud?";
    }
    if (input.contains('dolor de cabeza')) {
      return "Para el dolor de cabeza leve, descansa en un lugar oscuro y mantente hidratado. Si es intenso o persiste, acude a un médico.";
    }
    if (input.contains('fiebre')) {
      return "Si tienes fiebre, controla tu temperatura. Bebe líquidos y descansa. Si supera los 39°C, busca atención médica inmediata.";
    }
    if (input.contains('gripe') || input.contains('tos')) {
      return "Para la gripe, descanso y líquidos son clave. Cubre tu boca al toser. Si tienes dificultad para respirar, ve al hospital.";
    }
    if (input.contains('hospital')) {
      return "Puedes usar el mapa de esta aplicación para encontrar el hospital más cercano a tu ubicación.";
    }
    
    // Default medical response
    return "Entiendo tu consulta sobre salud. Como IA, te recomiendo consultar a un especialista para un diagnóstico preciso. ¿Necesitas buscar un hospital cercano?";
  }

  static Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      log("TTS Error: $e");
    }
  }

  static Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}
