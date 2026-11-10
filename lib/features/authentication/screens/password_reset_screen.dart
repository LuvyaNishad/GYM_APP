import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/entry_widgets.dart';
import '../../../services/auth_link_service.dart';
import '../providers/auth_link_provider.dart';
import 'auth_email_screen.dart';

/// Above account restoration and its provider containers, including cold starts.
class AuthLinkGate extends ConsumerWidget {
  const AuthLinkGate({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(authLinkProvider);
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Offstage(
          offstage: link.visible,
          child: ExcludeFocus(
            excluding: link.visible,
            child: TickerMode(enabled: !link.visible, child: child),
          ),
        ),
        if (link.visible)
          Positioned.fill(
            child: MaterialApp(
              key: ValueKey('${link.phase.name}-${link.userId}'),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: const PasswordResetScreen(),
            ),
          ),
      ],
    );
  }
}

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true, _leaving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (ref.read(authLinkProvider).busy || !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    try {
      await ref.read(authLinkProvider.notifier).updatePassword(_password.text);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'This reset session is no longer available. Request a new link.',
        );
      }
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() {
      _leaving = true;
      _error = null;
    });
    try {
      await ref.read(authLinkProvider.notifier).leave();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not close recovery. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = ref.watch(authLinkProvider);
    final busy = link.busy || _leaving;
    final recovery = link.phase == AuthLinkPhase.recovery;
    final complete = link.phase == AuthLinkPhase.complete;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Account recovery'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        recovery
                            ? 'Set a new password.'
                            : complete
                            ? 'Password updated.'
                            : link.phase == AuthLinkPhase.verifying
                            ? 'Opening your link…'
                            : 'This link couldn’t be opened.',
                        style: EntryStyle.heading,
                      ),
                      const SizedBox(height: 16),
                      if (link.phase == AuthLinkPhase.verifying)
                        const Center(child: CircularProgressIndicator())
                      else
                        Text(
                          recovery
                              ? 'Choose a password for ${link.email ?? 'your account'}. Your saved workouts stay with your account.'
                              : complete
                              ? 'Your new password is ready to use. Continue to your account.'
                              : 'The link may have expired, already been used, or been opened on a different device. Request a new link here and open the newest email on this device.',
                          style: AppTypography.bodyLarge,
                        ),
                      if (recovery) ...[
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          enabled: !busy && !link.passwordSaved,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.next,
                          style: AppTypography.bodyLarge,
                          decoration: EntryStyle.input(
                            'New password',
                            helper: 'At least 6 characters',
                            suffix: IconButton(
                              tooltip: _obscure
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: busy
                                  ? null
                                  : () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.length < 6
                              ? 'Use at least 6 characters.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmation,
                          obscureText: _obscure,
                          enabled: !busy && !link.passwordSaved,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.done,
                          style: AppTypography.bodyLarge,
                          decoration: EntryStyle.input('Confirm new password'),
                          validator: (value) => value != _password.text
                              ? 'Passwords do not match.'
                              : null,
                          onFieldSubmitted: (_) => _save(),
                        ),
                      ],
                      if (link.error != null)
                        EntryNotice(link.error!, error: !link.passwordSaved),
                      if (_error != null) EntryNotice(_error!, error: true),
                      const SizedBox(height: 24),
                      if (recovery)
                        EntryButton(
                          label: link.passwordSaved
                              ? 'Finish'
                              : 'Update password',
                          primary: true,
                          busy: busy,
                          onPressed: _save,
                        ),
                      if (complete)
                        EntryButton(
                          label: 'Continue',
                          primary: true,
                          busy: busy,
                          onPressed: _leave,
                        ),
                      if (link.phase == AuthLinkPhase.invalid ||
                          (recovery &&
                              link.error != null &&
                              !link.passwordSaved))
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => AuthEmailScreen(
                                      initialEmail: link.email ?? '',
                                    ),
                                  ),
                                ),
                          child: const Text('Request a new reset link'),
                        ),
                      if (!complete)
                        TextButton(
                          onPressed: busy ? null : _leave,
                          child: const Text('Back to sign in'),
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
