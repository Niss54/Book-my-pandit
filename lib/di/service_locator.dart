import 'package:get_it/get_it.dart';
import '../domain/services/i_supabase_service.dart';
import '../data/services/supabase_service_impl.dart';
import '../domain/services/i_auth_service.dart';
import '../data/services/google_auth_service_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/booking_repository.dart';
import '../data/repositories/booking_repository_impl.dart';
import '../domain/repositories/pandit_repository.dart';
import '../data/repositories/pandit_repository_impl.dart';
import '../services/payment_gateway.dart';
import '../services/razorpay_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // Services
  getIt.registerLazySingleton<ISupabaseService>(() => SupabaseServiceImpl());
  getIt.registerLazySingleton<IAuthService>(() => GoogleAuthServiceImpl());
  getIt.registerLazySingleton<PaymentGateway>(() => RazorpayService());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<ISupabaseService>(), getIt<IAuthService>()),
  );
  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(getIt<ISupabaseService>()),
  );
  getIt.registerLazySingleton<PanditRepository>(
    () => PanditRepositoryImpl(getIt<ISupabaseService>()),
  );
}
