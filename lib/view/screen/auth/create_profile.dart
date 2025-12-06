import 'package:dr_ai/core/utils/helper/scaffold_snakbar.dart';
import 'package:dr_ai/controller/auth/sign_up/sign_up_cubit.dart';
import 'package:dr_ai/controller/validation/formvalidation_cubit.dart';
import 'package:dr_ai/view/widget/button_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:dr_ai/core/utils/helper/extention.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../core/utils/helper/custom_dialog.dart';
import '../../widget/black_button.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_drop_down_field.dart';
import '../../widget/custom_text_field.dart';
import '../../widget/custom_text_span.dart';
import '../../widget/my_stepper_form.dart';

class CreateProfile extends StatefulWidget {
  const CreateProfile({super.key, required this.userCredential});

  final List<String?> userCredential;

  @override
  State<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  late GlobalKey<FormState> formKey;

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
  }

  bool _isLoading = false;
  String? _name;
  String? _phoneNumber;
  String? _dob;
  String? _gender;
  String? _bloodType;
  String? _height;
  String? _weight;
  String? _chronicDiseases;
  String? _familyHistoryOfChronicDiseases;
  List<Item> genderList = const [
    Item("Masculino", Icons.male),
    Item("Femenino", Icons.female),
  ];
  List<Item> bloodTypesList = const [
    Item('A+'),
    Item('A-'),
    Item('B+'),
    Item('B-'),
    Item('AB+'),
    Item('AB-'),
    Item('O+'),
    Item('O-'),
    Item('Desconocido'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            children: [
              Gap(context.height * 0.03),
              const Backbutton(),
              Gap(context.height * 0.032),
              CustomTextSpan(
                  textOne: "Crear ", textTwo: "Perfil", fontSize: 24.spMin),
              Gap(8.h),
              Text(
                "Por favor ingresa tus datos, podrás cambiarlos después desde la configuración",
                textAlign: TextAlign.center,
                style:
                    context.textTheme.bodySmall?.copyWith(fontSize: 16.spMin),
              ),
              Gap(26.h),
              const SignInStepperForm(stepReachedNumber: 2),
              _buildCreateProfileFields(),
              Gap(18.h),
              BlocConsumer<SignUpCubit, SignUpState>(
                listener: (context, state) {
                  if (state is SignUpLoading) {
                    _isLoading = true;
                  }
                  if (state is CreateProfileSuccess) {
                    FocusScope.of(context).unfocus();
                  }
                  if (state is VerifyEmailSuccess) {
                    FocusScope.of(context).unfocus();
                    _isLoading = false;
                    customDialogWithAnimation(context,
                        dismiss: false, screen: const LoginDialog());
                  }
                  if (state is CreateProfileFailure) {
                    customSnackBar(context, state.errorMessage);
                    _isLoading = false;
                  }
                  if (state is VerifyEmailFailure) {
                    customSnackBar(context, state.errorMessage);
                    _isLoading = false;
                  }
                  if (state is CreateProfileFailure) {
                    customSnackBar(context, state.errorMessage);
                    _isLoading = false;
                  }
                },
                builder: (context, state) {
                  final cubit = context.bloc<SignUpCubit>();
                  return CustomButton(
                    isDisabled: _isLoading,
                    widget: _isLoading == true
                        ? const ButtonLoadingIndicator()
                        : null,
                    title: "Enviar",
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        await cubit.createEmailAndPassword(
                          email: widget.userCredential[0]!,
                          password: widget.userCredential[1]!,
                        );
                        await cubit.createProfile(
                          name: _name!,
                          phoneNumber: _phoneNumber!,
                          dob: _dob!,
                          gender: _gender!,
                          bloodType: _bloodType!,
                          height: _height!,
                          weight: _weight!,
                          chronicDiseases: _chronicDiseases!,
                          familyHistoryOfChronicDiseases:
                              _familyHistoryOfChronicDiseases!,
                        );
                        await cubit.verifyEmail();
                      }
                    },
                  );
                },
              ),
              Gap(18.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateProfileFields() {
    final cubit = context.bloc<ValidationCubit>();
    return Form(
      key: formKey,
      child: Column(
        children: [
          CustomTextFormField(
            keyboardType: TextInputType.name,
            title: "Nombre",
            hintText: "Ingresa tu Nombre",
            onSaved: (data) {
              _name = data;
            },
            validator: cubit.nameValidator,
          ),
          CustomTextFormField(
            keyboardType: TextInputType.phone,
            title: "Número de Teléfono",
            hintText: "Ingresa tu número de teléfono",
            onSaved: (data) {
              _phoneNumber = data!;
            },
            validator: cubit.phoneNumberValidator,
          ),
          CustomTextFormField(
            initialValue: "dd/mm/yyyy",
            keyboardType: TextInputType.datetime,
            title: "Fecha de Nacimiento",
            hintText: "Ingresa tu fecha de nacimiento",
            onSaved: (data) {
              _dob = data;
            },
            validator: cubit.validateDateOfBirth,
          ),
          CustomDropDownField(
            hintText: "Selecciona tu Género",
            title: "Género",
            items: genderList,
            onSaved: (data) {
              _gender = data!.name.toString();
            },
          ),
          CustomDropDownField(
              hintText: "Selecciona tu Tipo de Sangre",
              title: "Tipo de Sangre",
              items: bloodTypesList,
              onSaved: (data) {
                _bloodType = data!.name.toString();
              }),
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  keyboardType: TextInputType.number,
                  title: "Altura (CM)",
                  hintText: "Ingresa tu altura",
                  onSaved: (data) {
                    _height = data!;
                  },
                  validator: cubit.heightValidator,
                ),
              ),
              Gap(18),
              Expanded(
                child: CustomTextFormField(
                  keyboardType: TextInputType.number,
                  title: "Peso (KG)",
                  hintText: "Ingresa tu peso",
                  onSaved: (data) {
                    _weight = data!;
                  },
                  validator: cubit.weightValidator,
                ),
              ),
            ],
          ),
          CustomTextFormField(
            keyboardType: TextInputType.multiline,
            maxLines: 4,
            closeWhenTapOutside: true,
            title: "Enfermedades crónicas",
            hintText: "Ingresa tus enfermedades crónicas",
            onSaved: (data) {
              _chronicDiseases = data;
            },
          ),
          CustomTextFormField(
            keyboardType: TextInputType.multiline,
            maxLines: 4,
            closeWhenTapOutside: true,
            title: "Historial familiar de enfermedades",
            hintText: "Ingresa tu historial familiar",
            onSaved: (data) {
              _familyHistoryOfChronicDiseases = data;
            },
          ),
        ],
      ),
    );
  }
}
