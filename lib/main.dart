import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'services/supabase_service.dart';
import 'services/razorpay_service.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/booking_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepositoryImpl())),
        ChangeNotifierProvider(create: (_) => BookingProvider(RazorpayService())),
      ],
      child: const BookMyPanditApp(),
    ),
  );
}

class BookMyPanditApp extends StatelessWidget {
  const BookMyPanditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Book My Pandit',
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8F4E00),
          primary: const Color(0xFF8F4E00),
          primaryContainer: const Color(0xFFFF9933),
          surface: const Color(0xFFFAF9F8),
          onSurface: const Color(0xFF1A1C1C),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF9F8),
        textTheme: GoogleFonts.manropeTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.outfit(),
          displayMedium: GoogleFonts.outfit(),
          displaySmall: GoogleFonts.outfit(),
          headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
