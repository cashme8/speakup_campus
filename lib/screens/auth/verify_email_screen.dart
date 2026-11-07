import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/primary_button.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.user?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const _MailIllustration(),
                const SizedBox(height: 28),
                const Text('Check your inbox',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: 'We sent a verification link to\n',
                    children: [
                      TextSpan(
                          text: email,
                          style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700)),
                      const TextSpan(
                          text: '\nOpen it, then come back and tap continue.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.6),
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 16),
                  NoticeBanner(auth.error!),
                ],
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'I’ve verified, continue',
                  icon: Icons.arrow_forward_rounded,
                  loading: auth.loading,
                  onPressed: () =>
                      context.read<AuthProvider>().checkVerified(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await context.read<AuthProvider>().resendVerification();
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Verification email sent')));
                  },
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Resend email'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                  child: const Text('Use a different account'),
                ),
                const SizedBox(height: 8),
                const Text('Can’t find it? Check your spam or junk folder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Layered circles + icon - a lightweight "illustration" with no assets.
class _MailIllustration extends StatelessWidget {
  const _MailIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(alpha: 0.5),
                shape: BoxShape.circle),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
                color: AppColors.primarySoft, shape: BoxShape.circle),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C47FF), Color(0xFFA48BFF)]),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.mark_email_unread_rounded,
                color: Colors.white, size: 38),
          ),
          const Positioned(
            top: 22,
            right: 26,
            child: Icon(Icons.auto_awesome, color: Color(0xFFFFB020), size: 22),
          ),
        ],
      ),
    );
  }
}
