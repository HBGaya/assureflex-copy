// Password Reset Screen
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/app_snack.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';

class PasswordResetScreen extends StatefulWidget {
  final String email;

  const PasswordResetScreen({
    super.key,
    required this.email,
  });

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  final _authRepo = AuthRepository();

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authRepo.resetPassword(
        email: widget.email,
        password: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (!mounted) return;

      AppSnack.success(context, 'Password updated. Please login.');

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, AppError.message(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
          onPressed: _isLoading ? null : () => Navigator.pop(context), // disable during load
        ),
      ),
      body: Stack(
        children: [
          // CONTENT
          SafeArea(
            child: AbsorbPointer( // prevents interactions while loading
              absorbing: _isLoading,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppSizes.xl),

                      // Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      SizedBox(height: AppSizes.xl),

                      // Title
                      const Center(
                        child: Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ),

                      SizedBox(height: AppSizes.md),

                      // Subtitle
                      Center(
                        child: Text(
                          'Enter your new password',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: AppSizes.xxl),

                      // New Password Field
                      CustomTextField(
                        label: 'New Password',
                        hint: 'Enter new password',
                        controller: _newPasswordController,
                        obscureText: true,
                        validator: _validatePassword,
                        prefixIcon: Icons.lock_outline,
                        keyboardType: TextInputType.visiblePassword,
                      ),

                      SizedBox(height: AppSizes.lg),

                      // Confirm Password Field
                      CustomTextField(
                        label: 'Confirm Password',
                        hint: 'Confirm new password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        validator: _validateConfirmPassword,
                        prefixIcon: Icons.lock_outline,
                        keyboardType: TextInputType.visiblePassword,
                      ),

                      SizedBox(height: AppSizes.xxl),

                      // Reset Password Button
                      CustomButton(
                        text: _isLoading ? 'Please wait...' : 'Reset Password',
                        onPressed: _isLoading ? null : _handleResetPassword,
                        type: ButtonType.primary,
                        size: ButtonSize.large,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // LOADING OVERLAY
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(
                  child: SizedBox(
                    height: 42,
                    width: 42,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
