import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'data/firebase_auth_repository.dart';
import 'data/firebase_photo_storage.dart';
import 'data/firestore_incident_repository.dart';
import 'data/repositories.dart';
import 'data/supabase_photo_storage.dart';
import 'firebase_options.dart';
import 'supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Photos go to Supabase Storage (no paid plan needed). Supabase does not
  // run its own login: it receives the user's Firebase ID token through
  // `accessToken` (Supabase "third-party auth"), so Firebase Auth stays the
  // single identity provider.
  if (supabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
      accessToken: () async =>
          FirebaseAuth.instance.currentUser?.getIdToken(),
    );
  }

  runApp(CampusIncidentApp(
    authRepository: FirebaseAuthRepository(),
    incidentRepository: FirestoreIncidentRepository(),
    // Swap to FirebasePhotoStorage() once the project is on the Blaze plan.
    photoStorage:
        supabaseConfigured ? SupabasePhotoStorage() : FirebasePhotoStorage(),
  ));
}

/// Root widget. Repositories are injected so tests can pass in fakes.
class CampusIncidentApp extends StatelessWidget {
  final AuthRepository authRepository;
  final IncidentRepository incidentRepository;
  final PhotoStorage photoStorage;

  const CampusIncidentApp({
    super.key,
    required this.authRepository,
    required this.incidentRepository,
    required this.photoStorage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        // IncidentProvider follows the signed-in user: it starts listening
        // to Firestore after login and stops on logout.
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (_) => IncidentProvider(
              repository: incidentRepository, storage: photoStorage),
          update: (_, auth, incidents) => incidents!..bindUser(auth.user),
        ),
      ],
      child: MaterialApp(
        title: 'SpeakUp Campus',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Routes by auth state: loading -> splash, signed out -> login,
/// unverified -> verify email, otherwise the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final Widget page;
    if (auth.initializing) {
      page = const _Splash();
    } else if (user == null) {
      page = const LoginScreen();
    } else if (!user.emailVerified) {
      page = const VerifyEmailScreen();
    } else {
      page = const MainShell();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(page.runtimeType), child: page),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_rounded, color: Colors.white, size: 56),
            SizedBox(height: 12),
            Text('SpeakUp Campus',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
