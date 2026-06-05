import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'di/service_locator.dart';
import 'domain/services/i_supabase_service.dart';
import 'services/payment_gateway.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/booking_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/booking_provider.dart';

import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  setupLocator();
  await getIt<ISupabaseService>().initialize();
  
  // Initialize Push Notifications (will safely fail if Firebase is not configured)
  await PushNotificationService.initialize();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(getIt<AuthRepository>())),
          ChangeNotifierProvider(
            create: (_) => BookingProvider(getIt<PaymentGateway>(), getIt<BookingRepository>()),
          ),
        ],
        child: const BookMyPanditApp(),
      ),
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
