import 'package:flutter/material.dart';
import 'package:insurance/admininsuraance.dart';
import 'package:insurance/login.dart';
import 'package:insurance/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xpdtgngkkjihmconczuy.supabase.co',
    anonKey: 'sb_publishable_NzPB-SFYyY4NrhcFvBMssA_82GT9Oyl',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Insurance Manager',
      home: SupabaseService.isAuthenticated
          ? const InsuranceDashboard()
          : const Login(),
    );
  }
}
