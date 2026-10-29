import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.user?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                    color: Color(0xFFEEE9FF), shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_unread_outlined,
                    size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('Verify your email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'We sent a verification link to\n$email\nOpen it, then come back and tap the button below.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'I have verified my email',
                loading: auth.loading,
                onPressed: () =>
                    context.read<AuthProvider>().checkVerified(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await context.read<AuthProvider>().resendVerification();
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Verification email sent')));
                },
                child: const Text('Resend email'),
              ),
              TextButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('Use a different account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
