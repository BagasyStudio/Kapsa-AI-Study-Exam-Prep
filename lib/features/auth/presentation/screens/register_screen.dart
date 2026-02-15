import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service and Privacy Policy'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );
      // Auth state change will trigger router redirect to /home
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_parseError(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String error) {
    if (error.contains('already registered')) {
      return 'This email is already registered';
    }
    if (error.contains('weak password') || error.contains('at least')) {
      return 'Password must be at least 6 characters';
    }
    if (error.contains('network')) {
      return 'No internet connection';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: StaggeredColumn(
                  children: [
                    const SizedBox(height: AppSpacing.xl),

                    // App icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryToIndigo,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Title
                    GradientText(
                      'Create Account',
                      style: AppTypography.h1.copyWith(fontSize: 28),
                      gradient: AppGradients.textDark,
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      'Begin your journey to academic excellence',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Full Name field
                    AuthTextField(
                      controller: _nameController,
                      hintText: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Email field
                    AuthTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Password field
                    AuthTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Confirm Password field
                    AuthTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignUp(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Terms & Privacy checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (v) =>
                                setState(() => _acceptedTerms = v ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            children: [
                              Text(
                                'I agree to the ',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TapScale(
                                onTap: () => context.push(Routes.terms),
                                child: Text(
                                  'Terms of Service',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                ' and ',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TapScale(
                                onTap: () => context.push(Routes.privacy),
                                child: Text(
                                  'Privacy Policy',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Create Account button
                    _isLoading
                        ? const SizedBox(
                            height: 56,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : PrimaryButton(
                            label: 'Create Account',
                            onPressed: _handleSignUp,
                          ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TapScale(
                          onTap: () => context.go(Routes.login),
                          child: Text(
                            'Sign In',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
