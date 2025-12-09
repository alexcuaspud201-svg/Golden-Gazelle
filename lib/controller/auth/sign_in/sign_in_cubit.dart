import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:dr_ai/data/source/firebase/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit() : super(SignInInitial());

  String? _validateFirebaseException(String? value) {
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

  Future<void> userSignIn(
      {required String email, required String password}) async {
    emit(SignInLoading());
    try {
      log("User init sign in with email: $email");
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      log("User finish in: ${userCredential.user!.email}");
      if (userCredential.user!.emailVerified == true) {
        emit(SignInSuccess());
        log("User signed in successfully: ${userCredential.user!.email}");
      } else if (userCredential.user!.emailVerified == false) {
        await FirebaseService.emailVerify();
        emit(EmailNotVerified(
            message:
                "Correo no verificado, revisa tu correo para el enlace de verificación"));
      }
    } on FirebaseAuthException catch (err) {
      final errMessage = _validateFirebaseException(err.code);
      log("FirebaseAuthException: ${err.code} - $errMessage");

      emit(SignInFailure(message: errMessage ?? err.code));
    } catch (err) {
      log("Unexpected error during sign in: $err");
      emit(SignInFailure(message: err.toString()));
    }
  }
}
