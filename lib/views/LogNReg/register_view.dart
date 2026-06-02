import 'package:flutter/material.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _goToConfirmation() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushNamed(
        context,
        '/register-confirm',
        arguments: {
          'name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
        },
      );
    }
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
                'Registrasi Admin',
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
                          // Nama Label
                          const Text(
                            'Nama Lengkap',
                            style: TextStyle(
                              color: Color(0xFF033A82),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Nama Field
                          TextFormField(
                            controller: _nameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                            decoration: _inputDecoration('Masukkan Nama Lengkap'),
                          ),
                          const SizedBox(height: 16),
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
                            decoration: _inputDecoration('Masukkan Username'),
                          ),
                          const SizedBox(height: 30),
                          // Register Button
                          _gradientButton(
                            text: 'Register',
                            colors: const [Color(0xFF729AC4), Color(0xFF033A82)],
                            onPressed: _goToConfirmation,
                          ),
                          const SizedBox(height: 16),
                          // Login Text
                          Center(
                            child: Text(
                              'Sudah punya akun? Login sekarang!',
                              style: TextStyle(
                                color: const Color(0xFF033A82).withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Login Button
                          _gradientButton(
                            text: 'Login',
                            colors: const [Color(0xFF8BB8E0), Color(0xFF4A90C6)],
                            onPressed: () {
                              Navigator.pop(context);
                            },
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

  InputDecoration _inputDecoration(String hint) {
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
    );
  }

  Widget _gradientButton({
    required String text,
    required List<Color> colors,
    required VoidCallback onPressed,
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
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
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