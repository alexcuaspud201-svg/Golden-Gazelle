import 'package:dr_ai/core/cache/cache.dart';
import 'package:dr_ai/core/utils/helper/error_screen.dart';
import 'package:dr_ai/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'data/source/local/chat_message_model.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        home: CustomErrorScreen(
          errorMessage: details.exception.toString(),
          stackTrace: details.stack.toString(),
        ),
      );
    };

    await dotenv.load(fileName: '.env');
    
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      if (e.toString().contains("duplicate") || e.toString().contains("already exists")) {
        // Firebase is already initialized, ignore this error and continue.
        debugPrint("Firebase already initialized (duplicate-app error ignored): $e");
      } else {
        // Rethrow other Firebase errors
        rethrow;
      }
    }
    
    await CacheData.cacheDataInit();
    await Hive.initFlutter();
    Hive.registerAdapter(ChatMessageModelAdapter());
    runApp(const MyApp());
  } catch (e, stack) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Error de Inicio',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    stack.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
