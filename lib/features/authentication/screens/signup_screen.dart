import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Registration shares the responsive form and account safety behavior.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});
  @override
  Widget build(BuildContext context) => const LoginScreen(createAccount: true);
}
