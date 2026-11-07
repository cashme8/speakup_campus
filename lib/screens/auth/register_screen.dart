import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _department;
  bool _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final ok = await context.read<AuthProvider>().register(
          name: _name.text,
          department: _department!,
          email: _email.text,
          password: _password.text,
        );
    // AuthGate swaps to the verify screen; close this pushed route.
    if (ok) navigator.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Join SpeakUp Campus with your ALU email.',
      showBack: true,
      headerHeight: 230,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Full name',
                hint: 'e.g. Amina Hassan',
                controller: _name,
                validator: (v) => Validators.minLength(v, 3, 'Name'),
                prefixIcon: Icons.person_outline,
                capitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                action: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              const FieldLabel('Department'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _department,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                hint: const Text('Select your department'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined,
                      color: AppColors.muted, size: 20),
                ),
                items: departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _department = v),
                validator: (v) => v == null ? 'Select your department' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'ALU email',
                hint: 'name@alustudent.com',
                controller: _email,
                validator: Validators.aluEmail,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline,
                autofillHints: const [AutofillHints.email],
                action: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                hint: 'At least 6 characters',
                controller: _password,
                validator: Validators.password,
                obscure: _hide,
                prefixIcon: Icons.lock_outline,
                autofillHints: const [AutofillHints.newPassword],
                action: TextInputAction.next,
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
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirm password',
                hint: 'Re-enter your password',
                controller: _confirm,
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match' : null,
                obscure: _hide,
                prefixIcon: Icons.lock_outline,
                action: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 14),
                NoticeBanner(auth.error!),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                  label: 'Create account',
                  loading: auth.loading,
                  onPressed: _submit),
              const SizedBox(height: 16),
              const NoticeBanner(
                'We’ll send a verification link to your ALU email. '
                'Staff accounts are set up by the facilities office.',
                type: NoticeType.info,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
