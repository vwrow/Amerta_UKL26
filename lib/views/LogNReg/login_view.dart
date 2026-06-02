import 'package:flutter/material.dart';
import '../../models/user_session.dart';
import '../../models/userLogin_models.dart';
import '../../services/auth_service.dart';
import '../../services/user_session_service.dart';
import '../../services/user_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final targetRole =
        ModalRoute.of(context)!.settings.arguments as String? ?? 'Admin';

    setState(() => _isLoggingIn = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final response = await AuthService().login(
      UserLoginRequest(username: username, password: password),
    );

    if (!mounted) return;

    if (!response.success || response.token == null) {
      setState(() => _isLoggingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty
              ? response.message
              : 'Username atau password salah'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final localAccount =
        await UserSessionService().findRegisteredAccount(username);
    final role = response.role ?? localAccount?.role ?? targetRole;

    final apiData = await UserService().fetchProfile(
      token: response.token!,
      role: role,
    );

    final userObj = apiData?['user'] as Map<String, dynamic>?;
    final activeSession = UserSession(
      username: userObj?['username']?.toString() ?? username,
      name: apiData?['name']?.toString() ??
          localAccount?.name ??
          username,
      userId: (apiData?['user_id'] ?? apiData?['id'])?.toString() ??
          localAccount?.userId ??
          '0',
      phone: apiData?['phone']?.toString() ?? localAccount?.phone ?? '',
      role: userObj?['role']?.toString() ?? role,
      createdAt: apiData?['createdAt']?.toString() ??
          localAccount?.createdAt ??
          DateTime.now().toIso8601String(),
      token: response.token!,
    );

    await UserSessionService().saveCurrentSession(activeSession);
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final String role = ModalRoute.of(context)!.settings.arguments as String? ?? 'Unknown';
    final String title = role == 'Admin' ? 'Login Sebagai Admin' : 'Login';

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
              const SizedBox(height: 20),
              // Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
                    size: 120,
                  );
                },
              ),
              const SizedBox(height: 30),
              // Title
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE8EEF5),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              // Form Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF5).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username Label
                          const Text(
                            'Username',
                            style: TextStyle(
                              color: Color(0xFF033A82),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Username Field
                          TextFormField(
                            controller: _usernameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Username tidak boleh kosong';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Masukkan username',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF729AC4),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF729AC4),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF033A82),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Password Label
                          const Text(
                            'Password',
                            style: TextStyle(
                              color: Color(0xFF033A82),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Masukkan password',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF729AC4),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF729AC4),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF033A82),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF729AC4),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Lupa Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                // Dummy - tidak melakukan apa-apa
                              },
                              child: const Text(
                                'Lupa Password',
                                style: TextStyle(
                                  color: Color(0xFF033A82),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Login Button
                          Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF729AC4),
                                  Color(0xFF033A82),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoggingIn ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoggingIn
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          if (role == 'Admin') ...[
                            const SizedBox(height: 16),
                            // Register Text
                            Center(
                              child: Text(
                                'Belum punya akun? Register sekarang!',
                                style: TextStyle(
                                  color: const Color(0xFF033A82).withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Register Button
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8BB8E0),
                                    Color(0xFF4A90C6),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                   Navigator.pushNamed(context, '/register', arguments: role);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}