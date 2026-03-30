import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
     // TODO: Replace with real credentials in production
     await Supabase.initialize(
       url: 'https://npegesjgzkooqoocuqmu.supabase.co',
       anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wZWdlc2pnemtvb3Fvb2N1cW11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3MDkwODMsImV4cCI6MjA5MDI4NTA4M30.C-AJl9Yu_qe_2w4rNuS_F6f2XVjpB6kuZGRvozFMolI',
     );
  }

  static Future<List<dynamic>> getPandits() async {
    try {
      final response = await client.from('pandits').select();
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching pandits');
      return [];
    }
  }
}
