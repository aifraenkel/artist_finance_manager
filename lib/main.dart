import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/project_provider.dart';
import 'services/project_service.dart';
import 'services/firestore_project_sync_service.dart';
import 'services/preferences_service.dart';
import 'models/user_preferences.dart';
import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  /// Access the application state to update locale or reload preferences.
  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  final PreferencesService _preferencesService = PreferencesService();
  String? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadUserPreferences(String userId, {bool force = false}) async {
    print('[_loadUserPreferences] Called with userId: $userId');
    print('[_loadUserPreferences] _lastLoadedUserId: $_lastLoadedUserId');

    // Only load if we haven't loaded for this user yet, unless forced
    if (!force && _lastLoadedUserId == userId) {
      print('[_loadUserPreferences] Already loaded for this user, skipping');
      return;
    }

    print('[_loadUserPreferences] Loading preferences from service...');
    try {
      final prefs = await _preferencesService.getPreferences(userId);
      print(
          '[_loadUserPreferences] Got preferences - language: ${prefs.language.code}');
      final newLocale = Locale(prefs.language.code);
      if (mounted && newLocale != _locale) {
        print(
            '[_loadUserPreferences] Updating locale from ${_locale.languageCode} to ${newLocale.languageCode}');
        setState(() {
          _locale = newLocale;
          _lastLoadedUserId = userId;
        });
      } else {
        print(
            '[_loadUserPreferences] Locale unchanged, just updating lastLoadedUserId');
        _lastLoadedUserId = userId;
      }
    } catch (e) {
      print('[_loadUserPreferences] ERROR: $e');
      print('[_loadUserPreferences] Stack trace: ${StackTrace.current}');
      // Keep default locale
    }
  }

  Future<void> refreshUserPreferences(String userId) {
    return _loadUserPreferences(userId, force: true);
  }

  @override
  Widget build(BuildContext context) {
    print('[MyApp] build() called');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => ProjectProvider(
            ProjectService(
              syncService: FirestoreProjectSyncService(),
            ),
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          print(
              '[MyApp] Consumer builder - currentUser: ${authProvider.currentUser?.uid ?? "null"}');
          print(
              '[MyApp] Consumer builder - _lastLoadedUserId: $_lastLoadedUserId');

          // Load user preferences when signed in (only once per user)
          if (authProvider.currentUser != null) {
            print('[MyApp] User is signed in, scheduling preference load');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('[MyApp] PostFrameCallback - loading preferences');
              _loadUserPreferences(authProvider.currentUser!.uid);
            });
          } else {
            print('[MyApp] User is NOT signed in');
            // User signed out, reset to default
            if (_lastLoadedUserId != null) {
              print('[MyApp] Resetting locale to default');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _locale = const Locale('en');
                  _lastLoadedUserId = null;
                });
              });
            }
          }

          return MaterialApp(
            title: 'Art Finance Hub',
            debugShowCheckedModeBanner: false,
            locale: _locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('de'), // German
              Locale('es'), // Spanish
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
