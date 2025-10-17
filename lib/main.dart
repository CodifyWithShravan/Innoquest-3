import 'package:flutter/material.dart';
import 'package:krishi_sakhi_final/home_page.dart';
import 'package:krishi_sakhi_final/login_page.dart';
import 'package:krishi_sakhi_final/splash_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:krishi_sakhi_final/profile_page.dart';
import 'package:krishi_sakhi_final/news_page.dart';
import 'package:krishi_sakhi_final/calendar_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:krishi_sakhi_final/pest_id_page.dart';
import 'package:krishi_sakhi_final/activity_log_page.dart';
import 'package:krishi_sakhi_final/market_price_page.dart';
import 'package:krishi_sakhi_final/chat_advisor_page.dart';
import 'package:krishi_sakhi_final/sustainability_page.dart';
import 'package:krishi_sakhi_final/management_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:
        'https://rwlrqmsfzpburbsubbjk.supabase.co', // Don't forget to paste your keys here
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3bHJxbXNmenBidXJic3ViYmprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0MzIzNTUsImV4cCI6MjA3NDAwODM1NX0.v2jQCldp_2ba7dgJ9EfD-t0yAr0yCwCBjBgqrVugSJE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define our custom colors
    const Color primaryColor = Color(0xFF4CAF50); // A vibrant, earthy green
    const Color accentColor = Color(0xFFFFC107); // A warm, sunny yellow
    const Color backgroundColor = Color(
      0xFFF5F5F5,
    ); // A light, clean beige/grey

    return MaterialApp(
      title: 'Krishi Sakhi',
      // -- THEME DATA STARTS HERE --
      theme: ThemeData(
        primarySwatch: Colors.green, // Fallback
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: GoogleFonts.lato().fontFamily, // Set default font
        // App Bar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white, // White text and icons
          elevation: 2,
        ),

        // Floating Action Button Theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
        ),

        // Elevated Button Theme (This is the corrected part)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        // Text Field Theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor),
          ),
        ),
      ),
      // -- THEME DATA ENDS HERE --
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/profile': (_) => const ProfilePage(),
        '/news': (_) => const NewsPage(),
        '/calendar': (_) => const CalendarPage(),
        '/pest_id': (_) => const PestIdPage(),
        '/activity_log': (_) => const ActivityLogPage(),
        '/market_prices': (_) => const MarketPricePage(),
        '/chat_advisor': (_) => const ChatAdvisorPage(),
        '/sustainability': (_) => const SustainabilityPage(),
        '/management': (_) => const ManagementDashboardPage(),
      },
    );
  }
}
