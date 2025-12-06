import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextDirection;
import 'package:intl/intl.dart ' hide TextDirection;

part 'formvalidation_state.dart';

class ValidationCubit extends Cubit<FormvalidationState> {
  ValidationCubit() : super(FormvalidationInitial());
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  TextDirection? getTextDirection(String text) {
    bool isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  String? convertDuration(String duration) {
    RegExp regExp = RegExp(r'(\d+)\s*hours?\s*(\d+)\s*mins?');
    Match? match = regExp.firstMatch(duration);

    if (match != null) {
      String hours = match.group(1)!;
      String minutes = match.group(2)!;
      return '$hours h $minutes m';
    }
    return duration;
  }

  TextDirection getFieldDirection(String text) {
    if (text.isEmpty) {
      return TextDirection.ltr;
    }
    final firstChar = text.characters.first;
    final isRtl = RegExp(r'[\u0600-\u06FF]').hasMatch(firstChar);
    return isRtl ? TextDirection.rtl : TextDirection.ltr;
  }

  void copyText(String? text) {
    Clipboard.setData(ClipboardData(text: text!));
  }

  String? validatePassword(String? value, [String? firebaseException]) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una contraseña';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!_hasUpperCase(value)) {
      return 'La contraseña debe tener al menos una letra mayúscula';
    }
    if (!_hasLowerCase(value)) {
      return 'La contraseña debe tener al menos una letra minúscula';
    }
    if (!_hasDigit(value)) {
      return 'La contraseña debe tener al menos un número';
    }
    // if (firebaseException != null ||
    //     firebaseException != '' ||
    //     firebaseException?.isNotEmpty == true) {
    //   return validateFirebaseException(firebaseException);
    // }
    _password = value;

    emit(PasswordValidationSuccess());
    return null;
  }

  bool _hasUpperCase(String value) => value.contains(RegExp(r'[A-Z]'));
  bool _hasLowerCase(String value) => value.contains(RegExp(r'[a-z]'));
  bool _hasDigit(String value) => value.contains(RegExp(r'\d'));

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirme su contraseña';
    }
    if (value != _password) {
      return 'Las contraseñas no coinciden';
    }
    _confirmPassword = value;

    emit(ConfirmPasswordValidationSuccess());
    return null;
  }

  String? validateEmail(String? value, [String? firebaseException]) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una dirección de correo electrónico';
    }
    if (!_hasValidEmail(value)) {
      return 'Por favor ingrese una dirección de correo electrónico válida';
    }
    _email = value;
    // if (firebaseException != null ||
    //     firebaseException != '' ||
    //     firebaseException?.isNotEmpty == true) {
    //   return validateFirebaseException(firebaseException);
    // }
    emit(EmailValidationSuccess());
    return null;
  }

  bool _hasValidEmail(String email) {
    final RegExp emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  String? nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre no puede estar vacío';
    }
    if (!RegExp(r"^[a-zA-Z]+(([',. -][a-zA-Z ])?[a-zA-Z]*)*$")
        .hasMatch(value)) {
      return 'Por favor ingrese un nombre válido';
    }
    return null;
  }

  String? phoneNumberValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'El número de teléfono no puede estar vacío';
    }

    if (!RegExp(r"^\+?\d{10,12}$").hasMatch(value)) {
      return 'Por favor ingrese un número de teléfono válido';
    }
    return null;
  }

  String? heightValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'La altura no puede estar vacía';
    }
    if (!RegExp(r"^\d+(\.\d+)?$").hasMatch(value)) {
      return 'Ingrese una altura válida en CM';
    }
    return null;
  }

  String? weightValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'El peso no puede estar vacío';
    }
    if (!RegExp(r"^\d+(\.\d+)?$").hasMatch(value)) {
      return 'Ingrese un peso válido en KG';
    }
    return null;
  }

  String? validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'La fecha de nacimiento no puede estar vacía';
    }

    final dateFormat = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateFormat.hasMatch(value)) {
      return 'Ingrese la fecha de nacimiento en el formato DD/MM/AAAA';
    }

    try {
      final date = DateFormat('dd/MM/yyyy').parseStrict(value);
      final today = DateTime.now();

      if (date.isAfter(today)) {
        return 'La fecha de nacimiento no puede ser futura';
      }

      final age = today.year - date.year;
      if (date.month > today.month ||
          (date.month == today.month && date.day > today.day)) {
        if (age - 1 < 18) {
          return 'Debes tener al menos 18 años';
        }
      } else {
        if (age < 18) {
          return 'Debes tener al menos 18 años';
        }
      }
    } catch (e) {
      return 'Fecha de nacimiento inválida';
    }

    return null;
  }

  String? validateDay(String? value) {
    if (value == null || value.isEmpty) {
      return 'El día no puede estar vacío';
    }

    final dayFormat = RegExp(r'^\d{2}$');
    if (!dayFormat.hasMatch(value)) {
      return 'Ingrese un día válido (DD)';
    }

    final day = int.tryParse(value);
    if (day == null || day < 1 || day > 31) {
      return 'Día inválido';
    }

    return null;
  }

  String? validateMonth(String? value) {
    if (value == null || value.isEmpty) {
      return 'El mes no puede estar vacío';
    }

    final monthFormat = RegExp(r'^\d{2}$');
    if (!monthFormat.hasMatch(value)) {
      return 'Ingrese un mes válido (MM)';
    }

    final month = int.tryParse(value);
    if (month == null || month < 1 || month > 12) {
      return 'Mes inválido';
    }

    return null;
  }

  String? validateYear(String? value) {
    if (value == null || value.isEmpty) {
      return 'El año no puede estar vacío';
    }

    final yearFormat = RegExp(r'^\d{4}$');
    if (!yearFormat.hasMatch(value)) {
      return 'Ingrese un año válido (AAAA)';
    }

    final year = int.tryParse(value);
    if (year == null || year < 1900 || year > DateTime.now().year) {
      return 'Año inválido';
    }

    return null;
  }

  String? validateFirebaseException(String? value) {
    if (value != null) {
      switch (value) {
        case 'invalid-email':
          return 'La dirección de correo electrónico no es válida.';
        case 'user-disabled':
          return 'La cuenta de usuario ha sido inhabilitada por un administrador.';
        case 'user-not-found':
          return 'No se encontró ningún usuario para ese correo electrónico.';
        case 'wrong-password':
          return 'Contraseña incorrecta para ese usuario.';
        case 'account-exists-with-different-credential':
          return 'Ya existe una cuenta con la misma dirección de correo electrónico pero con diferentes credenciales de inicio de sesión.';
        case 'email-already-in-use':
          return 'La dirección de correo electrónico ya está en uso por otra cuenta.';
        case 'operation-not-allowed':
          return 'El inicio de sesión con correo electrónico y contraseña está deshabilitado por un administrador.';
        case 'requires-recent-login':
          return 'Esta operación es confidencial y requiere una autenticación reciente. Vuelve a iniciar sesión antes de reintentar esta solicitud.';
        case 'invalid-credential':
          return 'Correo electrónico o contraseña incorrectos. Inténtalo de nuevo.';
        case 'invalid-verification-code':
          return 'El código de verificación no es válido.';
        case 'invalid-verification-id':
          return 'El ID de verificación no es válido.';
        case 'user-mismatch':
          return 'Las credenciales proporcionadas no corresponden al usuario que inició sesión anteriormente.';
        case 'weak-password':
          return 'La contraseña debe tener 6 caracteres o más.';
        case 'network-request-failed':
          return 'Se ha producido un error de red (como tiempo de espera agotado, conexión interrumpida o host inalcanzable).';
        case 'too-many-requests':
          return 'Demasiadas solicitudes. Inténtalo de nuevo más tarde.';
        default:
          return value;
      }
    }
    return null;
  }
}
