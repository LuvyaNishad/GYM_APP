import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/entry_widgets.dart';
import '../providers/auth_provider.dart';

class AuthEmailScreen extends ConsumerStatefulWidget {
  const AuthEmailScreen({
    super.key,
    this.confirmation = false,
    this.initialEmail = '',
  });
  final bool confirmation;
  final String initialEmail;

  @override
  ConsumerState<AuthEmailScreen> createState() => _AuthEmailScreenState();
}

class _AuthEmailScreenState extends ConsumerState<AuthEmailScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  String? _error, _message;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (ref.read(authProvider).isLoading || !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _message = null;
    });
    try {
      final auth = ref.read(authProvider.notifier);
      if (widget.confirmation) {
        await auth.resendConfirmation(_email.text);
      } else {
        await auth.requestPasswordReset(_email.text);
      }
      if (mounted) setState(() => _message = ref.read(authProvider).message);
    } catch (_) {
      if (mounted) setState(() => _error = ref.read(authProvider).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return PopScope(
      canPop: !auth.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.confirmation ? 'Confirm your email' : 'Reset password',
          ),
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
                        widget.confirmation
                            ? 'Check your inbox.'
                            : 'Get back to your training.',
                        style: EntryStyle.heading,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.confirmation
                            ? 'Enter the email you used to create your account. We’ll send another confirmation link.'
                            : 'Enter your account email. We’ll send a link to choose a new password.',
                        style: AppTypography.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        enabled: !auth.isLoading,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        style: AppTypography.bodyLarge,
                        decoration: EntryStyle.input('Email address'),
                        validator: (value) =>
                            value == null ||
                                !RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(value.trim())
                            ? 'Enter a valid email address.'
                            : null,
                        onFieldSubmitted: (_) {
                          if (auth.emailCooldown == 0) _send();
                        },
                      ),
                      if (_error != null) EntryNotice(_error!, error: true),
                      if (_message != null) EntryNotice(_message!),
                      const SizedBox(height: 24),
                      EntryButton(
                        label: widget.confirmation
                            ? 'Send confirmation email'
                            : 'Send reset link',
                        primary: true,
                        busy: auth.isLoading,
                        onPressed: auth.emailCooldown > 0 ? null : _send,
                      ),
                      if (auth.emailCooldown > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'You can send another email in ${auth.emailCooldown}s.',
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
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
