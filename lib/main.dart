import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import 'app_tab/utils/colors.dart';
import 'home_tab/screens/providers/theme_provider.dart';
import 'home_tab/screens/providers/auth_provider.dart';
import 'home_tab/screens/providers/user_provider.dart';
import 'home_tab/screens/auth/login_screen.dart';
import 'home_tab/utils/theme.dart';

// Portal shells (role-based routing)
import 'users/student_shell.dart';  // All non-admin users
import 'admin/admin_shell.dart';    // swasthikaponnusamy05@gmail.com only

// Firebase services
import 'services/firebase_service.dart';
import 'providers/firebase_auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/chatbot_provider.dart';
import 'services/data_seeder.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  print('📝 Environment loaded. GROQ_API_KEY present: ${dotenv.env['GROQ_API_KEY']?.isNotEmpty}');

  
  // Initialize Firebase
  try {
    await FirebaseService.instance.initialize();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  runApp(const LearnHubApp());
}

/// Root application widget
class LearnHubApp extends StatelessWidget {
  const LearnHubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseAuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            title: localeProvider.t('app_name'),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Consumer<FirebaseAuthProvider>(
              builder: (context, auth, _) {
                // ── Loading splash ───────────────────────────────────────
                if (auth.isLoading) {
                  return Scaffold(
                    backgroundColor:
                        Theme.of(context).scaffoldBackgroundColor,
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.school_rounded,
                                color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 24),
                          CircularProgressIndicator(
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                }

                // ── Not authenticated → Login ─────────────────────────────
                if (!auth.isAuthenticated) {
                  return const LoginScreen();
                }

                // ── STRICT ROLE GATE ─────────────────────────────────────
                // ONLY swasthikaponnusamy05@gmail.com  →  Admin Portal
                // Every other authenticated user       →  Student Portal
                return auth.isAdmin
                    ? const AdminShell()
                    : const StudentShell();
              },
            ),
          );
        },
      ),
    );
  }
}