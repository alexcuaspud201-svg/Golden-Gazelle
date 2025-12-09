import 'dart:convert';
import 'package:crypto/crypto.dart';

class MockUserModel {
  final String id;
  final String name;
  final int age;
  final String bloodType;
  final List<String> allergies;
  final List<String> conditions;
  final String userCode;

  MockUserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.bloodType,
    required this.allergies,
    required this.conditions,
    required this.userCode,
  });
}

class NfcSessionController {
  static final NfcSessionController _instance = NfcSessionController._internal();

  factory NfcSessionController() {
    return _instance;
  }

  NfcSessionController._internal();

  MockUserModel? _currentUser;
  bool _isPremium = false;

  MockUserModel? get currentUser => _currentUser;
  bool get isPremium => _isPremium;

  // Simula la lectura de un tag NFC
  void scanTag(String tagId) {
    // Generar hash SHA-256 del ID para hacerlo ver "seguro"
    var bytes = utf8.encode(tagId);
    var digest = sha256.convert(bytes);
    String hashedId = digest.toString().substring(0, 16); // Usar primeros 16 chars

    // Si ya hay usuario y es el mismo, no hacemos nada (o recargamos)
    if (_currentUser != null && _currentUser!.id == hashedId) {
      return;
    }

    // Crear usuario simulado "Falso" pero creíble
    // En un caso real, esto vendría de la BD usando el hash
    _currentUser = MockUserModel(
      id: hashedId,
      name: "Juan Pérez (Simulado)",
      age: 34,
      bloodType: "O+",
      allergies: ["Penicilina", "Polen"],
      conditions: ["Hipertensión Leve"],
      userCode: "MED-${hashedId.substring(0, 6).toUpperCase()}",
    );
    
    // Resetear premium al cambiar de usuario (o mantenerlo si se desea persistencia de sesión)
    // Para el simulador, reseteamos para mostrar el flujo completo
    _isPremium = false;
  }

  void upgradeToPremium() {
    _isPremium = true;
  }

  void clearSession() {
    _currentUser = null;
    _isPremium = false;
  }
}
