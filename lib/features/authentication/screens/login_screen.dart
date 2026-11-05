import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/aeon_logo.dart';
import '../../../core/widgets/entry_widgets.dart';
import '../../../services/hive_service.dart';
import '../../../state/app_providers.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/weight_plate_art.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.createAccount = false});
  final bool createAccount;
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _confirm = TextEditingController();
  bool _emailMode = false;
  bool _obscure = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _emailMode = widget.createAccount;
  }

  @override
  void dispose() {
    for (final controller in [_email, _password, _name, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _attempt(Future<void> Function() action) async {
    setState(() => _localError = null);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => _localError =
              ref.read(authProvider).error ??
              'Could not continue. Your setup is saved. Please try again.',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _attempt(
      () => widget.createAccount
          ? ref
                .read(authProvider.notifier)
                .signUp(_email.text, _password.text, _name.text)
          : ref.read(authProvider.notifier).signIn(_email.text, _password.text),
    );
    // WorkspaceApp restores the authenticated owner's store before showing Home.
  }

  Future<void> _guest() => _attempt(() async {
    await ref.read(authProvider.notifier).signInAsGuest();
    if (mounted) context.go(AppConstants.routeDashboard);
  });

  Future<void> _linkedAccountReady() async {
    try {
      await ref
          .read(hiveServiceProvider)
          .putSettingChecked(AppConstants.settingAccountChoicePending, false);
      if (!mounted) return;
      ref.invalidate(accountChoicePendingProvider);
      context.go(AppConstants.routeDashboard);
    } catch (_) {
      if (mounted) {
        setState(
          () => _localError =
              'Your account is connected. Reopen AEON to continue.',
        );
      }
    }
  }

  void _back() {
    if (_emailMode && !widget.createAccount) {
      FocusScope.of(context).unfocus();
      setState(() {
        _emailMode = false;
        _localError = null;
      });
    } else if (Navigator.canPop(context)) {
      context.pop();
    } else {
      context.go(AppConstants.routeLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen(authProvider, (previous, next) {
      if (previous?.isAnonymous == true &&
          !next.isAnonymous &&
          next.status == AuthStatus.authenticated &&
          previous?.userId == next.userId) {
        _linkedAccountReady();
      }
    });
    final firstUse =
        ref.watch(accountChoicePendingProvider) &&
        ref.watch(onboardingCompleteProvider);
    final user = ref.watch(userProfileProvider);
    final split = ref
        .watch(splitsProvider)
        .splits
        .where((s) => s.id == user?.preferredSplit)
        .firstOrNull;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final small = MediaQuery.sizeOf(context).height < 740;
    final artHeight = keyboard
        ? 0.0
        : _emailMode
        ? 105.0
        : small
        ? 220.0
        : 290.0;
    final error = _localError ?? auth.error;
    final heading = widget.createAccount
        ? 'A stronger start.'
        : _emailMode
        ? 'Welcome back.'
        : firstUse
        ? 'Your plan is ready.'
        : 'Make every rep count.';

    return PopScope(
      canPop: !_emailMode || widget.createAccount,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !auth.isLoading) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(.7, -.8),
              radius: 1.3,
              colors: [Color(0xFF202A38), AppColors.background],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (_emailMode || Navigator.canPop(context))
                            IconButton(
                              tooltip: 'Back',
                              onPressed: auth.isLoading ? null : _back,
                              icon: const Icon(Icons.arrow_back_rounded),
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                          const AeonLogo(size: 30, showGlow: false),
                          const SizedBox(width: 10),
                          Text(
                            'AEON',
                            style: AppTypography.headlineSmall.copyWith(
                              letterSpacing: 4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (!_emailMode)
                            const Icon(
                              Icons.fitness_center_rounded,
                              size: 18,
                              color: AppColors.platinum,
                            ),
                        ],
                      ),
                      AnimatedContainer(
                        duration:
                            MediaQuery.disableAnimationsOf(context) ||
                                MediaQuery.accessibleNavigationOf(context) ||
                                keyboard
                            ? Duration.zero
                            : const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                        height: artHeight,
                        child: artHeight == 0
                            ? null
                            : TickerMode(
                                enabled: !_emailMode,
                                child: const WeightPlateArt(),
                              ),
                      ),
                      if (keyboard) const SizedBox(height: 20),
                      if (!_emailMode) ...[
                        Text(
                          firstUse
                              ? 'BUILT AROUND YOU'
                              : 'PROGRESS, AT YOUR PACE',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 2,
                            color: AppColors.platinum,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Semantics(
                        header: true,
                        child: Text(heading, style: EntryStyle.heading),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.createAccount
                            ? 'Create an account to save your training and progress.'
                            : _emailMode
                            ? 'Log in to pick up where you left off.'
                            : 'Save your workouts and keep them synced.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (!_emailMode &&
                          firstUse &&
                          split != null &&
                          user?.trainingDaysPerWeek != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFF35404E)),
                              bottom: BorderSide(color: Color(0xFF35404E)),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                color: EntryStyle.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${split.name} · ${user!.trainingDaysPerWeek} days / week',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (error != null) EntryNotice(error, error: true),
                      if (auth.message != null) EntryNotice(auth.message!),
                      if (_emailMode)
                        _form(auth)
                      else ...[
                        EntryButton(
                          label: 'Continue with Google',
                          busy: auth.isLoading,
                          icon: Image.asset(
                            'assets/images/google_g.png',
                            width: 20,
                            height: 20,
                            excludeFromSemantics: true,
                          ),
                          onPressed: () => _attempt(
                            () => ref
                                .read(authProvider.notifier)
                                .signInWithGoogle(),
                          ),
                        ),
                        if (auth.isAnonymous)
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => _attempt(
                                    () => ref
                                        .read(authProvider.notifier)
                                        .signInWithGoogle(
                                          useExistingAccount: true,
                                        ),
                                  ),
                            child: const Text(
                              'Use an existing Google account',
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        const SizedBox(height: 12),
                        EntryButton(
                          label: 'Continue with email',
                          primary: true,
                          icon: const Icon(
                            Icons.alternate_email_rounded,
                            size: 20,
                          ),
                          onPressed: auth.isLoading
                              ? null
                              : () => setState(() {
                                  _emailMode = true;
                                  _localError = null;
                                }),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: auth.isLoading ? null : _guest,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text(
                          'Continue as guest',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      if (!_emailMode)
                        const Text(
                          'You can connect an account later.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
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

  Widget _form(AuthState auth) => AutofillGroup(
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.createAccount) ...[
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              style: AppTypography.bodyLarge,
              decoration: EntryStyle.input('Display name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your name.' : null,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.next,
            style: AppTypography.bodyLarge,
            decoration: EntryStyle.input('Email address'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your email address.';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: [
              widget.createAccount
                  ? AutofillHints.newPassword
                  : AutofillHints.password,
            ],
            textInputAction: widget.createAccount
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!widget.createAccount && !auth.isLoading) _submit();
            },
            style: AppTypography.bodyLarge,
            decoration: EntryStyle.input(
              'Password',
              helper: widget.createAccount ? 'At least 6 characters' : null,
              suffix: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            validator: (v) => v == null || v.length < 6
                ? 'Password must be at least 6 characters.'
                : null,
          ),
          if (widget.createAccount) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!auth.isLoading) _submit();
              },
              style: AppTypography.bodyLarge,
              decoration: EntryStyle.input('Confirm password'),
              validator: (v) =>
                  v != _password.text ? 'Passwords do not match.' : null,
            ),
          ],
          const SizedBox(height: 24),
          EntryButton(
            label: widget.createAccount ? 'Create account' : 'Log in',
            primary: true,
            busy: auth.isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: auth.isLoading
                ? null
                : () {
                    if (widget.createAccount) {
                      if (Navigator.canPop(context)) {
                        context.pop();
                      } else {
                        context.go(AppConstants.routeLogin);
                      }
                    } else {
                      context.push(AppConstants.routeSignup);
                    }
                  },
            child: Text(
              widget.createAccount
                  ? 'Already have an account? Log in'
                  : 'New to AEON? Create account',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: EntryStyle.accent,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
