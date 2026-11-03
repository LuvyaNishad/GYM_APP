import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/leon_button.dart';

/// Truthful local-build entry while account services are unconfigured.
class AccountUnavailableScreen extends StatelessWidget {
  const AccountUnavailableScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Continue on this device',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sign-in and cloud sync are not available in this build. Guest workouts and preferences are saved on this device.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Export a JSON backup from Account to keep a recoverable copy before uninstalling or changing phones.',
                  ),
                  const SizedBox(height: 24),
                  LeonButton(
                    label: 'CONTINUE AS GUEST',
                    onPressed: () => context.go(AppConstants.routeDashboard),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
