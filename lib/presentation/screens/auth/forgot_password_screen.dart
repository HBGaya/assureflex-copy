import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  final _authRepo = AuthRepository();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      await _authRepo.forgotPassword(email);
      if (!mounted) return;

      // success UI (choose one)
      AppSnack.success(context, 'OTP sent to your email');

      // move to OTP screen, pass email forward
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: email),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = AppError.message(e);
      AppSnack.error(context, msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resendEmail() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset email sent successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
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
          child: Padding(
            padding: EdgeInsets.all(responsivePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: responsivePadding),

                // Header
                AuthHeader(
                  title: _emailSent ? 'Check Your Email' : 'Forgot Password',
                  subtitle: _emailSent
                      ? 'We\'ve sent a password reset link to ${_emailController.text}'
                      : 'Enter your email address and we\'ll send you a link to reset your password',
                  icon: _emailSent ? Icons.mail_outline : Icons.lock_reset,
                ),

                SizedBox(height: responsivePadding * 1.5),

                if (!_emailSent) ...[
                  // Email Input Form
                  Form(
                    key: _formKey,
                    child: CustomTextField(
                      label: 'Email Address',
                      hint: 'Enter your email',
                      controller: _emailController,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.email_outlined,
                    ),
                  ),

                  SizedBox(height: responsivePadding),

                  // Reset Button
                  CustomButton(
                    text: 'Send Reset Link',
                    onPressed: _handleForgotPassword,
                    isLoading: _isLoading,
                    size: ButtonSize.large,
                  ),
                ] else ...[
                  // Email Sent Success State
                  Container(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppSizes.md),
                        const Text(
                          'Email Sent Successfully!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'Please check your inbox and follow the instructions to reset your password.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsivePadding),

                  // Resend Button
                  CustomButton(
                    text: 'Resend Email',
                    onPressed: _resendEmail,
                    isLoading: _isLoading,
                    type: ButtonType.outline,
                    size: ButtonSize.large,
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // Back to Login
                  CustomButton(
                    text: 'Back to Sign In',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    type: ButtonType.text,
                    size: ButtonSize.medium,
                  ),
                ],

                SizedBox(height: responsivePadding),

                // Help Text
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.grey600,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          _emailSent
                              ? 'Didn\'t receive the email? Check your spam folder or try resending.'
                              : 'Make sure to enter the email address associated with your account.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}