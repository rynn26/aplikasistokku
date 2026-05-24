import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'admin/screens/admin_main_screen.dart';
import 'screens/cashier_main_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService()..init(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StokKu - Inventory & Kasir',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily, // ← default Inter untuk semua Text
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00ADEF),
          primary: const Color(0xFF00ADEF),
          secondary: const Color(0xFF0077B6),
          surface: const Color(0xFFF8F9FE),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
            .copyWith(
              displayLarge: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: Colors.black87,
              ),
              displayMedium: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                color: Colors.black87,
              ),
              titleLarge: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
              bodyMedium: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black54,
              ),
              labelLarge: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              labelSmall: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
          labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn && auth.currentUser != null) {
            if (auth.currentUser!.isAdmin) {
              return const AdminMainScreen();
            } else {
              return const CashierMainScreen();
            }
          }
          return const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
