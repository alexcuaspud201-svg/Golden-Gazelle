import 'package:flutter_test/flutter_test.dart';
import 'package:dr_ai/simulator/nfc_session_controller.dart';

void main() {
  group('NfcSessionController Tests', () {
    late NfcSessionController controller;

    setUp(() {
      controller = NfcSessionController();
      controller.clearSession();
    });

    test('Initial state should be empty', () {
      expect(controller.currentUser, isNull);
      expect(controller.isPremium, isFalse);
    });

    test('Scan tag should create mock user', () {
      controller.scanTag("test-tag-id");
      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser!.name, contains("Simulado"));
      expect(controller.currentUser!.userCode, startsWith("MED-"));
    });

    test('Identical tag scan should not change user', () {
      controller.scanTag("tag-1");
      final user1 = controller.currentUser;
      controller.scanTag("tag-1");
      final user2 = controller.currentUser;
      
      // Being the same object reference or same content
      expect(user1!.id, equals(user2!.id));
    });

    test('Different tag scan should update user', () {
      controller.scanTag("tag-1");
      final id1 = controller.currentUser!.id;
      
      controller.scanTag("tag-2");
      final id2 = controller.currentUser!.id;
      
      expect(id1, isNot(equals(id2)));
    });

    test('Upgrade to premium should set flag', () {
      controller.upgradeToPremium();
      expect(controller.isPremium, isTrue);
    });

    test('Clear session should reset everything', () {
      controller.scanTag("tag-1");
      controller.upgradeToPremium();
      
      controller.clearSession();
      
      expect(controller.currentUser, isNull);
      expect(controller.isPremium, isFalse);
    });
  });
}
