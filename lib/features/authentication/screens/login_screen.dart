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
import 'auth_email_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.createAccount = false});
  final bool createAccount;
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _transitionDuration = Duration(milliseconds: 600);
  static const _transitionCurve = Curves.easeInOutCubic;
  late final AnimationController _transition;
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
    _transition =
        AnimationController(
          vsync: this,
          duration: _transitionDuration,
          value: _emailMode ? 1 : 0,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            setState(() {});
          }
        });
  }

  @override
  void dispose() {
    _transition.dispose();
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
    if (!ref.read(onboardingCompleteProvider)) {
      context.go(AppConstants.routeOnboarding);
      return;
    }
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
      _setEmailMode(false);
    } else if (Navigator.canPop(context)) {
      context.pop();
    } else {
      context.go(AppConstants.routeLogin);
    }
  }

  bool get _reduceMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  void _setEmailMode(bool emailMode) {
    setState(() {
      _emailMode = emailMode;
      _localError = null;
      if (_reduceMotion) {
        _transition.value = emailMode ? 1 : 0;
      } else if (emailMode) {
        _transition.forward();
      } else {
        _transition.reverse();
      }
    });
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
    final duration = _reduceMotion ? Duration.zero : _transitionDuration;
    final error = _localError ?? auth.error;
    final choiceContent = _content(
      emailMode: false,
      firstUse: firstUse,
      auth: auth,
      error: error,
      summary: split != null && user?.trainingDaysPerWeek != null
          ? '${split.name} · ${user!.trainingDaysPerWeek} days / week'
          : null,
    );
    final emailContent = _content(
      emailMode: true,
      firstUse: firstUse,
      auth: auth,
      error: error,
    );

    return PopScope(
      canPop: !auth.isLoading && (!_emailMode || widget.createAccount),
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
                          AnimatedBuilder(
                            animation: _transition,
                            child: IconButton(
                              tooltip: 'Back',
                              onPressed: auth.isLoading ? null : _back,
                              icon: const Icon(Icons.arrow_back_rounded),
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                            builder: (context, child) => ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: Navigator.canPop(context)
                                    ? 1
                                    : _transitionCurve.transform(
                                        _transition.value,
                                      ),
                                child: IgnorePointer(
                                  ignoring:
                                      !_emailMode && !Navigator.canPop(context),
                                  child: ExcludeSemantics(
                                    excluding:
                                        !_emailMode &&
                                        !Navigator.canPop(context),
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
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
                          AnimatedOpacity(
                            duration: duration,
                            curve: _transitionCurve,
                            opacity: _emailMode ? 0 : 1,
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              size: 18,
                              color: AppColors.platinum,
                            ),
                          ),
                        ],
                      ),
                      if (!keyboard)
                        LayoutBuilder(
                          builder: (context, constraints) => AnimatedBuilder(
                            animation: _transition,
                            child: TickerMode(
                              // Freeze the detailed painting in both directions
                              // so its cached layer can be scaled during the morph.
                              enabled: !_emailMode && !_transition.isAnimating,
                              child: const SizedBox(
                                width: 400,
                                height: 310,
                                child: WeightPlateArt(),
                              ),
                            ),
                            builder: (context, child) {
                              final progress = _transitionCurve.transform(
                                _transition.value,
                              );
                              final expandedHeight = small ? 220.0 : 290.0;
                              final height =
                                  expandedHeight +
                                  (105 - expandedHeight) * progress;
                              final expandedScale = (expandedHeight / 310)
                                  .clamp(0.0, constraints.maxWidth / 400);
                              final compactScale = (105 / 310).clamp(
                                0.0,
                                constraints.maxWidth / 400,
                              );
                              final scale =
                                  expandedScale +
                                  (compactScale - expandedScale) * progress;
                              return SizedBox(
                                key: const ValueKey('login-art-space'),
                                height: height,
                                child: OverflowBox(
                                  minWidth: 400,
                                  maxWidth: 400,
                                  minHeight: 310,
                                  maxHeight: 310,
                                  child: Transform.scale(
                                    key: const ValueKey('login-art-scale'),
                                    scale: scale,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (keyboard) const SizedBox(height: 20),
                      if (_reduceMotion)
                        _emailMode ? emailContent : choiceContent
                      else
                        AnimatedCrossFade(
                          duration: duration,
                          reverseDuration: duration,
                          sizeCurve: _transitionCurve,
                          firstCurve: const Interval(
                            0,
                            .45,
                            curve: Curves.easeInOut,
                          ),
                          secondCurve: const Interval(
                            .45,
                            1,
                            curve: Curves.easeInOut,
                          ),
                          alignment: Alignment.topCenter,
                          crossFadeState: _emailMode
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: _pane(
                            emailMode: false,
                            child: choiceContent,
                          ),
                          secondChild: _pane(
                            emailMode: true,
                            child: emailContent,
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

  Widget _pane({required bool emailMode, required Widget child}) {
    final inactive = emailMode != _emailMode;
    return Offstage(
      offstage: inactive && !_transition.isAnimating,
      child: IgnorePointer(
        ignoring: inactive,
        child: ExcludeFocus(
          excluding: inactive,
          child: ExcludeSemantics(excluding: inactive, child: child),
        ),
      ),
    );
  }

  Widget _content({
    required bool emailMode,
    required bool firstUse,
    required AuthState auth,
    String? error,
    String? summary,
  }) {
    final heading = widget.createAccount
        ? 'A stronger start.'
        : emailMode
        ? 'Welcome back.'
        : firstUse
        ? 'Your plan is ready.'
        : 'Make every rep count.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!emailMode) ...[
          Text(
            firstUse ? 'BUILT AROUND YOU' : 'PROGRESS, AT YOUR PACE',
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
              : emailMode
              ? 'Log in to pick up where you left off.'
              : 'Save your workouts and keep them synced.',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (!emailMode && firstUse && summary != null) ...[
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
                Expanded(child: Text(summary, style: AppTypography.bodyMedium)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (error != null) EntryNotice(error, error: true),
        if (auth.message != null) EntryNotice(auth.message!),
        if (emailMode)
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
                  .signInWithGoogle(
                    useExistingAccount: !ref.read(onboardingCompleteProvider),
                  ),
            ),
          ),
          if (auth.isAnonymous)
            TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () => _attempt(
                      () => ref
                          .read(authProvider.notifier)
                          .signInWithGoogle(useExistingAccount: true),
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
            icon: const Icon(Icons.alternate_email_rounded, size: 20),
            onPressed: auth.isLoading ? null : () => _setEmailMode(true),
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
        if (!emailMode)
          const Text(
            'You can connect an account later.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
      ],
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
          if (!widget.createAccount)
            TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AuthEmailScreen(initialEmail: _email.text),
                      ),
                    ),
              child: const Text('Forgot password?'),
            ),
          EntryButton(
            label: widget.createAccount ? 'Create account' : 'Log in',
            primary: true,
            busy: auth.isLoading,
            onPressed: _submit,
          ),
          TextButton(
            onPressed: auth.isLoading
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AuthEmailScreen(
                        confirmation: true,
                        initialEmail: _email.text,
                      ),
                    ),
                  ),
            child: const Text('Resend confirmation email'),
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
