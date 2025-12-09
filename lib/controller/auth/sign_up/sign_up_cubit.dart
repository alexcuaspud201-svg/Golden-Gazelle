import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_ai/data/source/firebase/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit() : super(SignUpInitial());
  int _ctn = 0;
  final _firestore = FirebaseFirestore.instance;
  Future<void> verifyEmail() async {
    emit(SignUpLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload(); // Ensure user state is fresh
        await user.sendEmailVerification();
        log("Verification email sent to ${user.email}");
        emit(VerifyEmailSuccess());
      } else {
        throw Exception("User not found (Null)");
      }
    } catch (err) {
      log("Email Verification Error: $err");
      emit(VerifyEmailFailure(errorMessage: "Error: $err"));
    }
  }

  Future<void> createEmailAndPassword(
      {required String email, required String password}) async {
    emit(SignUpLoading());
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      emit(CreatePasswordSuccess());
    } catch (err) {
      log("Create Email Error: $err");
      emit(CreateProfileFailure(errorMessage: err.toString()));
    }
  }

  Future<void> createProfile(
      {required String name,
      required String phoneNumber,
      required String dob,
      required String gender,
      required String bloodType,
      required String height,
      required String weight,
      required String chronicDiseases,
      required String familyHistoryOfChronicDiseases}) async {
    emit(SignUpLoading());
    try {
      await FirebaseService.storeUserData(
          name: name,
          phoneNumber: phoneNumber,
          dob: dob,
          gender: gender,
          bloodType: bloodType,
          height: height,
          weight: weight,
          chronicDiseases: chronicDiseases,
          familyHistoryOfChronicDiseases: familyHistoryOfChronicDiseases);
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name); // Ensure Auth profile has name
      emit(CreateProfileSuccess());
    } catch (err) {
      log("Create Profile Error: $err");
      emit(CreateProfileFailure(errorMessage: err.toString()));
    }
  }

  Future<void> checkIfEmailInUse(String emailAddress) async {
    emit(EmailCheckLoading());
    try {
      if (_ctn < 5) {
        final querySnapshot = await _firestore
            .collection('users')
            .where('isActive', isEqualTo: true)
            .get();
            // .timeout(const Duration(seconds: 5)); // Removed timeout to let Firestore handle connection
        final isEmailInUse = querySnapshot.docs
            .any((doc) => doc.data()['email'] == emailAddress);
        if (isEmailInUse) {
          _ctn++;
          emit(EmailNotValid());
          log("Email already in use");
        } else {
          emit(EmailValid());
          _ctn = 0;
          log("Email not in use");
        }
      } else {
        // Reset counter after a short delay internally, but tell user to wait
        Future.delayed(const Duration(seconds: 5), () {
          _ctn = 0;
        });
        emit(EmailNotValid(message: "Demasiadas solicitudes, espera unos segundos"));
      }
    } on FirebaseAuthException catch (err) {
      log(err.message.toString());
      emit(EmailNotValid());
    }
  }
}
