import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/leon_button.dart';
import '../providers/auth_provider.dart';

/// Professional authentication login screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _localError = null);

    try {
      await ref
          .read(authProvider.notifier)
          .signIn(_emailController.text, _passwordController.text);

      if (!mounted) return;

      // WorkspaceApp restores the authenticated owner's separate store.
    } catch (e) {
      if (mounted) {
        setState(
          () => _localError = ref.read(authProvider).error ?? e.toString(),
        );
      }
    }
  }

  Future<void> _handleGuest() async {
    await ref.read(authProvider.notifier).signInAsGuest();
    if (!mounted) return;
    context.go(AppConstants.routeDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen(authProvider, (previous, next) {
      if (previous?.isAnonymous == true &&
          !next.isAnonymous &&
          next.status == AuthStatus.authenticated &&
          previous?.userId == next.userId &&
          mounted) {
        context.go(AppConstants.routeDashboard);
      }
    });
    final visibleError = _localError ?? authState.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Account Login'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LeonButton(
                        label: 'CONTINUE WITH GOOGLE',
                        onPressed: authState.isLoading
                            ? null
                            : () async {
                                try {
                                  await ref
                                      .read(authProvider.notifier)
                                      .signInWithGoogle();
                                } catch (_) {
                                  if (mounted) {
                                    setState(
                                      () => _localError = ref
                                          .read(authProvider)
                                          .error,
                                    );
                                  }
                                }
                              },
                      ),
                      if (authState.isAnonymous)
                        TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(authProvider.notifier)
                                        .signInWithGoogle(
                                          useExistingAccount: true,
                                        );
                                  } catch (_) {
                                    if (mounted) {
                                      setState(
                                        () => _localError = ref
                                            .read(authProvider)
                                            .error,
                                      );
                                    }
                                  }
                                },
                          child: const Text(
                            'Sign in to an existing Google account',
                          ),
                        ),
                      if (authState.message != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(authState.message!),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'WELCOME BACK',
                        style: AppTypography.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to synchronize your workouts and progress across devices.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (visibleError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.gymRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.gymRed.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            visibleError,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.danger,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: AppTypography.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.subtleBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.subtleBorder,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email address.';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        style: AppTypography.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.subtleBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.subtleBorder,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      LeonButton(
                        label: authState.isLoading
                            ? 'SIGNING IN...'
                            : 'SIGN IN',
                        onPressed: authState.isLoading ? null : _handleSignIn,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: AppColors.subtleBorder),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppColors.subtleBorder),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LeonButton(
                        label: 'CONTINUE AS GUEST',
                        isOutlined: true,
                        onPressed: authState.isLoading ? null : _handleGuest,
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => context.push(AppConstants.routeSignup),
                        child: Text(
                          "Don't have an account? Create Account",
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
