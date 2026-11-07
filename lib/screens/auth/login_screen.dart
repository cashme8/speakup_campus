import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().login(_email.text, _password.text);
  }

  void _openRegister() {
    context.read<AuthProvider>().clearError();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthScaffold(
      title: 'Welcome back 👋',
      subtitle: 'Sign in with your ALU email to report and\n'
          'track issues around campus.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'ALU email',
                hint: 'name@alustudent.com',
                controller: _email,
                validator: Validators.aluEmail,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline,
                action: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _password,
                validator: Validators.password,
                obscure: _hide,
                prefixIcon: Icons.lock_outline,
                action: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                suffix: IconButton(
                  tooltip: _hide ? 'Show password' : 'Hide password',
                  icon: Icon(
                      _hide
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 14),
                NoticeBanner(auth.error!),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                  label: 'Sign in', loading: auth.loading, onPressed: _submit),
              const SizedBox(height: 20),
              const _OrDivider(),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _openRegister,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: const Text('Create a student account'),
              ),
              const SizedBox(height: 24),
              const _TrustNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('New to SpeakUp?',
              style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_outlined, size: 16, color: AppColors.muted),
        SizedBox(width: 6),
        Flexible(
          child: Text('Only verified ALU accounts can sign in',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
      ],
    );
  }
}
