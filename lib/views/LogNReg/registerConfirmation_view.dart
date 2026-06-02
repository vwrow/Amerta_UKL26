import 'package:flutter/material.dart';
import '../../services/admin.dart';
import '../../services/user_session_service.dart';
import '../../models/response_data_map.dart';

class RegisterConfirmView extends StatefulWidget {
  const RegisterConfirmView({super.key});

  @override
  State<RegisterConfirmView> createState() => _RegisterConfirmViewState();
}

class _RegisterConfirmViewState extends State<RegisterConfirmView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // 1. Extract the data passed from register_view.dart
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String username = args['username'];
    final String name = args['name'] ?? '';

    // 2. Prepare the payload for the API
    Map<String, dynamic> adminData = {
      "username": username,
      "password": _passwordController.text,
      "phone": _phoneController.text,
      "name": name,
    };

    // 3. Call the API
    AdminService adminService = AdminService();
    ResponseDataMap result = await adminService.registerAdmin(adminData);

    if (!mounted) return;

    // 4. Handle the result
    if (result.status == true) {
      final apiData = result.data ?? {};
      final sessionService = UserSessionService();

      await sessionService.saveRegisteredAccount(
        username: username,
        password: _passwordController.text,
        name: apiData['name']?.toString() ?? name,
        userId: (apiData['user_id'] ?? apiData['id'])?.toString() ?? '',
        phone: apiData['phone']?.toString() ?? _phoneController.text,
        role: 'Admin',
        createdAt: apiData['createdAt']?.toString() ??
            DateTime.now().toIso8601String(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
        arguments: 'Admin',
      );
      return;
    }

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: Colors.red,
      ),
    );
  }

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
              const Text(
                'Konfirmasi Registrasi',
                style: TextStyle(
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
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                            decoration: _inputDecoration(
                              'Masukkan password',
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
                          const SizedBox(height: 16),
                          // Confirm Password Label
                          const Text(
                            'Konfirmasi Password',
                            style: TextStyle(
                              color: Color(0xFF033A82),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Konfirmasi password tidak boleh kosong';
                              }
                              if (value != _passwordController.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                            decoration: _inputDecoration(
                              'Konfirmasi password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF729AC4),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Phone Label
                          const Text(
                            'No Telepon',
                            style: TextStyle(
                              color: Color(0xFF033A82),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'No telepon tidak boleh kosong';
                              }
                              return null;
                            },
                            decoration: _inputDecoration('Masukkan no telepon'),
                          ),
                          const SizedBox(height: 40),
                          // Final Register Button
                          _gradientButton(
                            text: 'Register',
                            colors: const [Color(0xFF729AC4), Color(0xFF033A82)],
                            onPressed: _submitRegistration,
                            isLoading: _isSubmitting,
                          ),
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

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
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
      suffixIcon: suffixIcon,
    );
  }

  Widget _gradientButton({
    required String text,
    required List<Color> colors,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
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
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}