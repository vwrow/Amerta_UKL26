import 'package:flutter/material.dart';

class RoleSelectorView extends StatelessWidget {
  const RoleSelectorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF729AC4),
              Color(0xFF031B46),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo
              Image.asset(
                'assets/Vector.png',
                height: 120,
                width: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.water_drop,
                    color: Colors.white,
                    size: 80,
                  );
                },
              ),
              const SizedBox(height: 40),
              // Main Title
              const Text(
                'Kamu Masuk Sebagai?',
                style: TextStyle(
                  color: Color(0xFFE8EEF5),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              // Role Buttons Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Admin Button
                    Expanded(
                      child: _buildRoleCard(
                        context: context,
                        title: 'Admin',
                        imagePath: 'assets/Admin.png',
                        role: 'Admin',
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User Button
                    Expanded(
                      child: _buildRoleCard(
                        context: context,
                        title: 'User',
                        imagePath: 'assets/Member.png',
                        role: 'User',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    required String role,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/login',
          arguments: role,
        );
      },
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF5).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF033A82),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Image.asset(
              imagePath,
              height: 150,
              width: 300,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  title == 'Admin' ? Icons.admin_panel_settings : Icons.person,
                  color: const Color(0xFF033A82),
                  size: 100,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}