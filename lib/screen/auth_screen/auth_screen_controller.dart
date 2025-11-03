import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bubbly/common/controller/base_controller.dart';
import 'package:bubbly/common/functions/debounce_action.dart';
import 'package:bubbly/common/manager/firebase_notification_manager.dart';
import 'package:bubbly/common/manager/logger.dart';
import 'package:bubbly/common/manager/session_manager.dart';
import 'package:bubbly/common/service/api/common_service.dart';
import 'package:bubbly/common/service/api/notification_service.dart';
import 'package:bubbly/common/service/api/user_service.dart';
import 'package:bubbly/common/service/subscription/subscription_manager.dart';
import 'package:bubbly/languages/dynamic_translations.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/general/settings_model.dart';
import 'package:bubbly/model/user_model/user_model.dart' as user;
import 'package:bubbly/screen/dashboard_screen/dashboard_screen.dart';

import '../../common/controller/firebase_firestore_controller.dart';

class AuthScreenController extends BaseController {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController forgetEmailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  // Phone country code - default to Egypt (+20)
  String selectedCountryCode = '+20';
  int mobileCountryCodeInt = 20;
  String? _verificationId;
  int? _resendToken;

  @override
  void onInit() {
    CommonService.instance.fetchGlobalSettings();
    FirebaseNotificationManager.instance;
    super.onInit();
  }

  Future<void> onLoginWithPhone() async {
    // If OTP is entered, verify; otherwise send code
    if ((otpController.text.trim()).isNotEmpty) {
      return verifyPhoneCode();
    } else {
      return sendPhoneCode();
    }
  }

  Future<void> sendPhoneCode() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      return showSnackBar("من فضلك أدخل رقم الموبايل");
    }
    final fullPhone = '$selectedCountryCode$phone';
    showLoader();
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification on some devices
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            stopLoader();
            await _completePhoneLogin();
          } catch (e) {
            stopLoader();
            Loggers.error(e);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          stopLoader();
          Loggers.error(e.message);
          showSnackBar(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          stopLoader();
          showSnackBar('OTP has been sent via SMS');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      stopLoader();
      Loggers.error(e);
    }
  }

  Future<void> verifyPhoneCode() async {
    if (_verificationId == null) {
      return showSnackBar('Please request an OTP first');
    }
    final code = otpController.text.trim();
    if (code.length < 4) {
      return showSnackBar('Please enter a valid OTP');
    }
    showLoader();
    try {
      final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: code);
      await FirebaseAuth.instance.signInWithCredential(credential);
      stopLoader();
      await _completePhoneLogin();
    } on FirebaseAuthException catch (e) {
      stopLoader();
      showSnackBar(e.message ?? 'Invalid code');
    } catch (e) {
      stopLoader();
      Loggers.error(e);
    }
  }

  Future<void> _completePhoneLogin() async {
    final phone = phoneController.text.trim();
    Loggers.info('[LOGIN-PHONE-OTP] Phone: $phone, DialCode: $selectedCountryCode, CountryCodeInt: $mobileCountryCodeInt');
    user.User? data = await _registration(
      identity: phone,
      loginMethod: LoginMethod.email,
      fullname: phone,
      phoneNumber: phone,
      mobileCountryCode: mobileCountryCodeInt,
    );
    if (data != null) {
      _navigateScreen(data);
    }
  }

  Future<void> onLogin() async {
    if (emailController.text.trim().isEmpty) {
      return showSnackBar(LKey.enterEmail.tr);
    }
    if (passwordController.text.trim().isEmpty) {
      return showSnackBar(LKey.enterAPassword.tr);
    }
    showLoader();
    String? fullname;
    if (GetUtils.isEmail(emailController.text.trim())) {
      UserCredential? credential = await signInWithEmailAndPassword();
      if (credential != null) {
        if (credential.user?.emailVerified == false) {
          stopLoader();
          return showSnackBar(LKey.verifyEmailFirst.tr);
        }
        fullname = credential.user?.displayName;
      } else {
        return showSnackBar('user not found');
      }
    }

    Loggers.info('[LOGIN] Phone: ${phoneController.text.trim()}, DialCode: $selectedCountryCode, CountryCodeInt: $mobileCountryCodeInt');
    user.User? data = await _registration(
        identity: emailController.text.trim(),
        loginMethod: LoginMethod.email,
        fullname: fullname ?? emailController.text.split('@')[0],
        phoneNumber: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
        mobileCountryCode: mobileCountryCodeInt);
    stopLoader();
    if (data != null) {
      _navigateScreen(data);
    }
  }

  Future<void> onCreateAccount() async {
    if (fullNameController.text.trim().isEmpty) {
      return showSnackBar(LKey.fullNameEmpty.tr);
    }
    if (emailController.text.trim().isEmpty) {
      return showSnackBar(LKey.enterEmail.tr);
    }
    if (passwordController.text.trim().isEmpty) {
      return showSnackBar(LKey.enterAPassword.tr);
    }
    if (confirmPassController.text.trim().isEmpty) {
      return showSnackBar(LKey.confirmPasswordEmpty.tr);
    }
    if (!GetUtils.isEmail(emailController.text.trim())) {
      return showSnackBar(LKey.invalidEmail.tr);
    }
    if (passwordController.text.trim() != confirmPassController.text.trim()) {
      return showSnackBar(LKey.passwordMismatch.tr);
    }
    if (phoneController.text.trim().isEmpty) {
      return showSnackBar("من فضلك أدخل رقم الموبايل");
    }
    showLoader();
    UserCredential? credential = await createUserWithEmailAndPassword();
    if (credential != null) {
      Loggers.info('[REGISTER] Phone: ${phoneController.text.trim()}, DialCode: $selectedCountryCode, CountryCodeInt: $mobileCountryCodeInt');
      await _registration(
          identity: emailController.text.trim(),
          loginMethod: LoginMethod.email,
          fullname: fullNameController.text.trim(),
          phoneNumber: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
          mobileCountryCode: mobileCountryCodeInt);
      credential.user?.updateDisplayName(fullNameController.text.trim());
      credential.user?.sendEmailVerification();
      Get.back();
      Get.back();
      showSnackBar(LKey.verificationLinkSent.tr);
    }
  }

  void onGoogleTap() async {
    showLoader();
    UserCredential? credential;
    try {
      credential = await signInWithGoogle();
    } catch (e) {
      Loggers.error(e);
      Get.back();
    }

    if (credential?.user == null) return;
    user.User? data = await _registration(
        identity: credential?.user?.email ?? '',
        loginMethod: LoginMethod.google,
        fullname: credential?.user?.displayName ??
            credential?.user?.email?.split('@')[0]);
    Get.back();
    if (data != null) {
      _navigateScreen(data);
    }
  }

  void onAppleTap() async {
    showLoader();
    UserCredential? credential;
    try {
      credential = await signInWithApple();
    } catch (e) {
      Loggers.error(e);
      Get.back();
      return;
    }

    if (credential?.user == null) {
      Get.back();
      return;
    }

    // Better handling of Apple Sign-In data
    String identity = credential?.user?.email ?? credential?.user?.uid ?? '';
    String fullname = credential?.user?.displayName ??
        (credential?.user?.email?.split('@')[0]) ??
        "Apple User";

    user.User? data = await _registration(
        identity: identity, loginMethod: LoginMethod.apple, fullname: fullname);

    Get.back();
    if (data != null) {
      _navigateScreen(data);
    }
  }

  Future<user.User?> _registration(
      {required String identity,
        required LoginMethod loginMethod,
        String? fullname,
        String? phoneNumber,
        int? mobileCountryCode}) async {
    String? deviceToken =
    await FirebaseNotificationManager.instance.getNotificationToken();
    if (deviceToken == null) return null;

    user.User? userData = await UserService.instance.logInUser(
        identity: identity,
        loginMethod: loginMethod,
        deviceToken: deviceToken,
        fullName: fullname,
        phoneNumber: phoneNumber,
        mobileCountryCode: mobileCountryCode);

    // Persist the newly returned user and token immediately to ensure subsequent calls use correct auth
    if (userData != null) {
      SessionManager.instance.setUser(userData);
      SessionManager.instance.setAuthToken(userData.token);
      // Also reflect the new user in Firestore immediately
      try {
        FirebaseFirestoreController.instance.updateUser(userData);
      } catch (e) {
        Loggers.warning('Failed to sync user to Firestore: $e');
      }

      // Add a small delay to ensure token is properly set before making subsequent API calls
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Ensure phone details are persisted to the profile if backend didn't set them on login
    if ((phoneNumber != null && phoneNumber.isNotEmpty) ||
        (mobileCountryCode != null)) {
      try {
        // Verify we have the correct token before making the update call
        String? currentToken = SessionManager.instance.getAuthToken();
        Loggers.info('Using token for updateUserDetails: ${currentToken?.substring(0, 50)}...');

        await UserService.instance.updateUserDetails(
          phoneNumber: phoneNumber,
          mobileCountryCode: mobileCountryCode,
        );
      } catch (e) {
        Loggers.warning('Failed to persist phone details: $e');
      }
    }


    //1023581657
    //aquauptight@powerscrews.com
    Setting? setting = SessionManager.instance.getSettings();
    if (userData?.newRegister == true &&
        setting?.registrationBonusStatus == 1) {
      final translations = Get.find<DynamicTranslations>();
      final languageData = translations.keys[userData?.appLanguage] ?? {};
      NotificationService.instance.pushNotification(
          title: languageData[LKey.registrationBonusTitle] ??
              LKey.registrationBonusTitle.tr,
          body: languageData[LKey.registrationBonusDescription] ??
              LKey.registrationBonusDescription.tr,
          type: NotificationType.other,
          deviceType: userData?.device,
          token: userData?.deviceToken,
          authorizationToken: userData?.token?.authToken);
    }
    //SubscriptionManager.shared.login('${userData?.id}');
    if (userData != null) {
      // Subscribe My Following Ids For Live streaming notification

      for (int id in (userData.followingIds ?? [])) {
        // Delay slightly to avoid overloading FCM
        await Future.delayed(const Duration(milliseconds: 10));
        await FirebaseNotificationManager.instance
            .subscribeToTopic(topic: '$id');
      }
      return userData;
    }
    return null;
  }

  Future<UserCredential?> createUserWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());
      SessionManager.instance.setPassword(passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      stopLoader();
      Loggers.error(e.message);
      if (e.code == 'weak-password') {
        showSnackBar(LKey.weakPassword.tr);
      } else if (e.code == 'email-already-in-use') {
        showSnackBar(LKey.accountExists.tr);
      } else {
        showSnackBar(e.message);
      }
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      stopLoader();
      if (e.code == 'user-not-found') {
        showSnackBar(LKey.noUserFound.tr);
        Loggers.info(LKey.noUserFound.tr);
      } else if (e.code == 'wrong-password') {
        showSnackBar(LKey.incorrectPassword.tr);
        Loggers.info(LKey.incorrectPassword.tr);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    // Get the GoogleSignIn instance and initialize if needed
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
    await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.idToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    return await FirebaseAuth.instance.signInWithProvider(appleProvider);
  }

  void forgetPassword() async {
    final email = forgetEmailController.text.trim();
    if (email.isEmpty) {
      showSnackBar(LKey.enterEmail.tr);
      return;
    }
    showLoader();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      stopLoader();
      Get.back(); // Close the BottomSheet
      showSnackBar(LKey.resetPasswordLinkSent.tr);
    } on FirebaseAuthException catch (e) {
      stopLoader();
      showSnackBar(e.message ?? "An error occurred. Please try again.");
    }
  }

  void _navigateScreen(user.User? user) {
    DebounceAction.shared.call(() {
      SessionManager.instance.setLogin(true);
      SessionManager.instance.setUser(user);
      Get.offAll(() => DashboardScreen(myUser: user));
    }, milliseconds: 250);
  }
}
