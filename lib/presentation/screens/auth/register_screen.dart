 import 'package:assureflex/presentation/screens/auth/otp_verification_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/app_snack.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import '../../widgets/auth/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptTerms = false;
  final _authRepo = AuthRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if(_formKey.currentState?.validate()==true){
      try {
        setState(() => _isLoading = true);
        await _authRepo.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );
        if (!mounted) return;
        // if your flow needs OTP after register:
        Navigator.pop(context);
        AppSnack.success(context, 'You account has been registered, login to continue..');
        // or go back to login:
        // Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        final msg = AppError.message(e);     // <-- clean text only
        print('Message: $msg');
        AppSnack.error(context, msg);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Padding(
            padding: EdgeInsets.all(responsivePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const AuthHeader(
                    title: 'Create Account',
                    subtitle: 'Sign up to get started with your account',
                    icon: Icons.person_add_alt_1_rounded,
                  ),

                  SizedBox(height: responsivePadding * 1.5),

                  // Full Name Field
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    validator: Validators.name,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.person_outline,
                  ),

                  const SizedBox(height: AppSizes.lg),

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


                  // Email Field
                  CustomTextField(
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    controller: _phoneController,
                    // validator: Validators.phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.phone_android,
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // Password Field
                  CustomTextField(
                    label: 'Password',
                    hint: 'Create a password',
                    controller: _passwordController,
                    validator: Validators.password,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.lock_outline,
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // Confirm Password Field
                  CustomTextField(
                    label: 'Confirm Password',
                    hint: 'Confirm your password',
                    controller: _confirmPasswordController,
                    validator: (value) => Validators.confirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline,
                  ),

                  // const SizedBox(height: AppSizes.md),
                  // Terms & Conditions
                  // Row(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     SizedBox(
                  //       width: 24,
                  //       height: 24,
                  //       child: Checkbox(
                  //         value: _acceptTerms,
                  //         onChanged: (value) {
                  //           setState(() => _acceptTerms = value ?? false);
                  //         },
                  //         activeColor: AppColors.primary,
                  //         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  //       ),
                  //     ),
                  //     const SizedBox(width: AppSizes.sm),
                  //     Expanded(
                  //       child: RichText(
                  //         text: const TextSpan(
                  //           style: TextStyle(
                  //             fontSize: 14,
                  //             color: AppColors.grey600,
                  //           ),
                  //           children: [
                  //             TextSpan(text: 'I agree to the '),
                  //             TextSpan(
                  //               text: 'Terms & Conditions',
                  //               style: TextStyle(
                  //                 color: AppColors.primary,
                  //                 fontWeight: FontWeight.w500,
                  //               ),
                  //             ),
                  //             TextSpan(text: ' and '),
                  //             TextSpan(
                  //               text: 'Privacy Policy',
                  //               style: TextStyle(
                  //                 color: AppColors.primary,
                  //                 fontWeight: FontWeight.w500,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  SizedBox(height: responsivePadding),

                  // Register Button
                  CustomButton(
                    text: 'Create Account',
                    onPressed: _submitRegister,
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

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.grey600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Sign In',
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