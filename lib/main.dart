import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  // Later: WidgetsFlutterBinding.ensureInitialized();
  //        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CampusIncidentApp());
}

class CampusIncidentApp extends StatelessWidget {
  const CampusIncidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
      ],
      child: MaterialApp(
        title: 'Campus Incident Reporter',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Routes by auth state: signed out -> login, unverified -> verify, else app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const LoginScreen();
    if (!auth.user!.emailVerified) return const VerifyEmailScreen();
    return const MainShell();
  }
}
