import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
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

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Full name',
                  hint: 'Amina Hassan',
                  controller: _name,
                  validator: (v) => Validators.minLength(v, 3, 'Name'),
                  prefixIcon: Icons.person_outline,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Department',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _department,
                      hint: const Text('Select your department'),
                      items: departments
                          .map((d) =>
                              DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _department = v),
                      validator: (v) =>
                          v == null ? 'Select your department' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'ALU email',
                  hint: 'name@alustudent.com',
                  controller: _email,
                  validator: Validators.aluEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: 'At least 6 characters',
                  controller: _password,
                  validator: Validators.password,
                  obscure: true,
                  prefixIcon: Icons.lock_outline,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  controller: _confirm,
                  validator: (v) =>
                      v != _password.text ? 'Passwords do not match' : null,
                  obscure: true,
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                    label: 'Create account',
                    loading: loading,
                    onPressed: _submit),
                const SizedBox(height: 12),
                const Text(
                  'We will send a verification link to your ALU email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
