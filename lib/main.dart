import 'package:flutter/material.dart';
import 'views/LogNReg/roleSelector_view.dart';
import 'views/LogNReg/register_view.dart';
import 'views/LogNReg/registerConfirmation_view.dart';
import 'views/LogNReg/login_view.dart';
import 'views/MainApp/dashboard_view.dart';
import 'views/MainApp/kelolaPelanggan_view.dart';
import 'views/MainApp/kelolaLayanan_view.dart';
import 'views/MainApp/profile_view.dart';
import 'views/MainApp/kelolaTagihan_view.dart';
import 'views/MainApp/tagihan_view.dart';
import 'views/LogNReg/splashScreen_view.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const RoleSelectorView(),
        '/register': (context) => const RegisterView(),
        '/register-confirm': (context) => const RegisterConfirmView(),
        '/login': (context) => const LoginView(),
        '/dashboard': (context) => const DashboardView(),
        '/profile': (context) => const ProfileView(),
        '/kelolaPelanggan': (context) => const KelolaPelangganView(),
        '/kelolaLayanan': (context) => const KelolaLayananView(),
        '/kelolaTagihan': (context) => const KelolaTagihanView(),
        '/tagihan': (context) => const TagihanView(),
      },
    );
  }
}
