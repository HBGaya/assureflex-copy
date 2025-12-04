import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/app_snack.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/common/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  final _authRepo = AuthRepository();
  // final _userRepo = UserRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  initState(){
    super.initState();
    _loadRememberedEmail();
  }
  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remember_email');

    if (!mounted) return;
    if(savedEmail!=null) {
      _emailController.text = savedEmail;
    }
    setState(() {
      _rememberMe = true;
    });
  }

  Future<void> _submitLogin() async {
    if(_formKey.currentState?.validate()==true){
      try {
        setState(() => _isLoading = true); // if you have a loading bool; else remove
        await _authRepo.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        final prefs = await SharedPreferences.getInstance();


        // await _userRepo.me(); // optional sanity check
        if (_rememberMe) {
          await prefs.setString('remember_email', _emailController.text.trim());
        } else {
          await prefs.remove('remember_email');
        }

        if (!mounted) return;
        AppSnack.success(context, 'Logged in successfully');
        Navigator.of(context).pushReplacementNamed('/form');
      } catch (e) {
        if (!mounted) return;
        final msg = AppError.message(e);     // <-- clean text only
        AppSnack.error(context, msg);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style for light background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
    );

    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white, // Ensures proper background color in notch area
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Padding(
            padding: EdgeInsets.all(responsivePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.xl), // Fixed spacing instead of responsive

                  // Header
                  const AuthHeader(
                    title: 'Welcome Back',
                    subtitle: 'Sign in to continue to your account',
                  ),

                  SizedBox(height: responsivePadding * 1.5),

                  // Email Field
                  CustomTextField(
                    label: 'Email Address',
                    hint: 'Enter your email',
                    controller: _emailController,
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.email_outlined,
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // Password Field
                  CustomTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    validator: Validators.password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline,
                  ),

                  const SizedBox(height: AppSizes.md),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() => _rememberMe = value ?? false);
                              },
                              activeColor: AppColors.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/forgot-password');
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: responsivePadding),

                  // Login Button
                  CustomButton(
                    text: 'Sign In',
                    onPressed: _submitLogin,
                    isLoading: _isLoading,
                    size: ButtonSize.large,
                  ),

                  SizedBox(height: responsivePadding),

                  // // Social Login
                  // SocialLoginButtons(
                  //   onGooglePressed: () {
                  //     // Handle Google login
                  //   },
                  //   onApplePressed: () {
                  //     // Handle Apple login
                  //   },
                  // ),
                  //
                  // SizedBox(height: responsivePadding),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.grey600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/register');
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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