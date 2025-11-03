import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/widget/custom_back_button.dart';
import 'package:bubbly/common/widget/gradient_text.dart';
import 'package:bubbly/common/widget/privacy_policy_text.dart';
import 'package:bubbly/common/widget/text_button_custom.dart';
import 'package:bubbly/common/widget/text_field_custom.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/screen/auth_screen/auth_screen_controller.dart';
import 'package:bubbly/utilities/style_res.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';
import 'package:country_code_picker/country_code_picker.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Controllers for the new fields
  final userIdController = TextEditingController();
  final birthDateController = TextEditingController();

  // Validation states
  bool isUserIdValid = true;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthScreenController>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const CustomBackButton(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5)),
            const SizedBox(height: 10),
            Expanded(
                child: SingleChildScrollView(
                  dragStartBehavior: DragStartBehavior.down,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 20.0, right: 20, top: 40, bottom: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(LKey.signUp.tr.toUpperCase(),
                                style: TextStyleCustom.unboundedBlack900(
                                  fontSize: 25,
                                  color: textDarkGrey(context),
                                ).copyWith(letterSpacing: -.2)),
                            GradientText(LKey.startJourney.tr.toUpperCase(),
                                gradient: StyleRes.themeGradient,
                                style: TextStyleCustom.unboundedBlack900(
                                  fontSize: 25,
                                  color: textDarkGrey(context),
                                ).copyWith(letterSpacing: -.2)),
                          ],
                        ),
                      ),
                      TextFieldCustom(
                        controller: controller.fullNameController,
                        title: LKey.fullName.tr,
                      ),
                      TextFieldCustom(
                        controller: controller.emailController,
                        title: LKey.email.tr,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      // Phone number with country picker
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                        child: Row(
                          children: [
                            CountryCodePicker(
                              onChanged: (code) {
                                controller.selectedCountryCode = code.dialCode ?? '+20';
                                controller.mobileCountryCodeInt = int.tryParse((code.dialCode ?? '+20').replaceAll('+', '')) ?? 20;
                              },
                              onInit: (code) {
                                controller.selectedCountryCode = code?.dialCode ?? controller.selectedCountryCode;
                                controller.mobileCountryCodeInt = int.tryParse((code?.dialCode ?? controller.selectedCountryCode).replaceAll('+', '')) ?? controller.mobileCountryCodeInt;
                              },
                              initialSelection: 'EG',
                              favorite: const ['+20','EG','+971','AE'],
                              showCountryOnly: false,
                              showOnlyCountryWhenClosed: false,
                              alignLeft: false,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFieldCustom(
                                controller: controller.phoneController,
                                title: 'رقم الموبايل',
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(15),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // User ID field - minimum 4 characters
                      TextFieldCustom(
                        controller: userIdController,
                        title: "معرف المستخدم", // User ID in Arabic
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]')), // Only letters and numbers
                        ],
                        hintText: "أقل حاجة 4 أحرف أو أرقام", // Hint text in Arabic
                        isError: !isUserIdValid, // Show error if validation fails
                        onChanged: (value) {
                          setState(() {
                            isUserIdValid = value.length >= 4;
                          });
                        },
                      ),
                      // Birth date field
                      TextFieldCustom(
                        controller: birthDateController,
                        title: "تاريخ الميلاد", // Birth date in Arabic
                        keyboardType: TextInputType.datetime,
                        hintText: "يوم/شهر/سنة", // Date format hint in Arabic
                        readOnly: true, // Make it read-only to show date picker
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(const Duration(
                                days: 365 * 18)), // Default to 18 years ago
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            // locale: const Locale('ar'), // Arabic locale for date picker
                          );
                          if (picked != null) {
                            birthDateController.text =
                            "${picked.day}/${picked.month}/${picked.year}";
                          }
                        },
                      ),
                      TextFieldCustom(
                        controller: controller.passwordController,
                        title: LKey.password.tr,
                        isPasswordField: true,
                      ),
                      TextFieldCustom(
                        controller: controller.confirmPassController,
                        title: LKey.reTypePassword.tr,
                        isPasswordField: true,
                      ),
                    ],
                  ),
                )),
            TextButtonCustom(
                onTap: () {
                  // Check if user ID is valid before proceeding
                  if (userIdController.text.length >= 4) {
                    controller.onCreateAccount();
                  } else {
                    // Show error message or handle validation
                    setState(() {
                      isUserIdValid = false;
                    });
                    Get.snackbar(
                      "خطأ",
                      "معرف المستخدم يجب أن يكون 4 أحرف على الأقل",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                title: LKey.createAccount.tr,
                backgroundColor: textDarkGrey(context),
                horizontalMargin: 20,
                titleColor: whitePure(context)),
            SizedBox(height: AppBar().preferredSize.height / 1.2),
            const SafeArea(
                top: false,
                maintainBottomViewPadding: true,
                child: PrivacyPolicyText()),
          ],
        ),
      ),
    );
  }
}
