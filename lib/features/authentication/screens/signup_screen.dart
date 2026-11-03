import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/leon_button.dart';

/// LEON Sign-up screen.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CREATE ACCOUNT', style: AppTypography.headlineLarge),
                  const SizedBox(height: 4),
                  Text('Join the programme.', style: AppTypography.bodyMedium),
                  const SizedBox(height: 32),

                  GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Name',
                              floatingLabelStyle: AppTypography.bodyMedium
                                  .copyWith(fontSize: 16),
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: AppColors.primaryDim,
                              ),
                            ),
                            validator: (v) =>
                                v != null && v.length >= 2 ? null : 'Too short',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              floatingLabelStyle: AppTypography.bodyMedium
                                  .copyWith(fontSize: 16),
                              prefixIcon: const Icon(
                                Icons.mail_outline,
                                color: AppColors.primaryDim,
                              ),
                            ),
                            validator: (v) => v != null && v.contains('@')
                                ? null
                                : 'Invalid email',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              floatingLabelStyle: AppTypography.bodyMedium
                                  .copyWith(fontSize: 16),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.primaryDim,
                              ),
                            ),
                            validator: (v) => v != null && v.length >= 6
                                ? null
                                : 'Min 6 chars',
                          ),
                          const SizedBox(height: 24),
                          LeonButton(
                            label: 'Create Account',
                            icon: Icons.person_add_alt_1,
                            isLoading: _isLoading,
                            width: double.infinity,
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                // TODO(auth): call authProvider.signUp(...)
                              }
                            },
                          ),
                        ],
                      ),
                    ),
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
