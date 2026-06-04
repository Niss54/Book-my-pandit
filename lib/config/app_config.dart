/// Securely loads app configuration via --dart-define.
/// No secrets (like service_role keys) should be hardcoded here.
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasRazorpayKey => razorpayKeyId.isNotEmpty;
}
