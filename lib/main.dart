import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; 
import 'views/login/login_page.dart';
import 'views/dashboard/admin_dashboard_page.dart';
import 'views/layouts/client_main_layout.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  String? loginDateStr = prefs.getString('login_date');
  String? userRole = prefs.getString('user_role');
  
  Widget initialScreen = const LoginPage();

  if (loginDateStr != null && FirebaseAuth.instance.currentUser != null) {
    DateTime loginDate = DateTime.parse(loginDateStr);
    // Cek apakah session masih berlaku (kurang dari 30 hari)
    if (DateTime.now().difference(loginDate).inDays <= 30) {
      if (userRole == 'admin') {
        initialScreen = const AdminDashboardPage();
      } else if (userRole == 'user') {
        initialScreen = const ClientMainLayout();
      }
    } else {
      // Session expired
      await FirebaseAuth.instance.signOut();
      await prefs.remove('login_date');
      await prefs.remove('user_role');
    }
  }
  
  runApp(ProviderScope(child: AdminApp(initialScreen: initialScreen)));
}

class AdminApp extends StatelessWidget {
  final Widget initialScreen;
  
  const AdminApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MFW Admin',
      theme: AppTheme.darkTheme,
      home: initialScreen,
    );
  }
}