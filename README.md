# Golden Gazelle 🦌

**Golden Gazelle** Es una aplicación móvil desarrollada en Flutter diseñada para asistir en el cuidado médico personal y la gestión de pacientes mediante Inteligencia Artificial.

## 🚀 Características Principales

*   **Asistente IA Offline**: Chat médico inteligente capaz de funcionar sin conexión a internet, manteniendo el contexto de la conversación localmente.
*   **Gestión de Perfil Médico**: Registro completo de datos de salud (peso, altura, tipo de sangre, enfermedades crónicas) sincronizado en la nube.
*   **Autenticación Segura**: Sistema de registro e inicio de sesión robusto utilizando **Firebase Authentication**.
*   **Simulador NFC**: Herramienta integrada para simular y probar interacciones con tarjetas o dispositivos médicos NFC.
*   **Interfaz Moderna**: Diseño UI/UX limpio y adaptable ("Clean Logo"), con soporte para temas claros y oscuros.
*   **Mapas y Geolocalización**: Funcionalidades de ubicación configurables remotamente.

## 🛠️ Configuración del Proyecto

### Requisitos
*   Flutter SDK (Versión 3.x o superior).
*   Dart SDK.
*   Cuenta de Firebase configurada.

### Instalación
1.  Clonar el repositorio.
2.  Instalar dependencias:
    ```bash
    flutter pub get
    ```
3.  Asegurar que el archivo `google-services.json` esté en `android/app/`.
4.  Ejecutar la aplicación:
    ```bash
    flutter run
    ```

### Base de Datos (Firebase)
El proyecto utiliza **Cloud Firestore** con las siguientes colecciones principales:
*   `users`: Perfiles de usuario.
*   `chat_history`: Respaldo de conversaciones.
*   `enable_map`: Configuración remota de funcionalidades.

## 📱 Compilación (Android)
Para generar el APK de producción:

```bash
flutter build apk --release
```

El archivo generado estará en: `build/app/outputs/flutter-apk/app-release.apk`.

## 📧 Contacto
Para soporte, dudas o contribuciones al proyecto, por favor contactar a:

**Correo**: thomascuasapaz25@gmail.com

---
Desarrollado con ❤️ usando Flutter.
