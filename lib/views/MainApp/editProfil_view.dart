import 'package:flutter/material.dart';
import '../../models/user_session.dart';
import '../../services/user_service.dart';
import '../../services/user_session_service.dart';

class EditProfilView extends StatefulWidget {
  final UserSession session;
  final String address;

  const EditProfilView({
    super.key,
    required this.session,
    this.address = '-',
  });

  @override
  State<EditProfilView> createState() => _EditProfilViewState();
}

class _EditProfilViewState extends State<EditProfilView> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _userIdController;
  late TextEditingController _phoneController;
  late TextEditingController _roleController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
    _usernameController = TextEditingController(text: widget.session.username);
    _userIdController = TextEditingController(text: widget.session.userId);
    _phoneController = TextEditingController(text: widget.session.phone);
    
    final role = widget.session.role.toLowerCase();
    final roleBadgeText = (role == 'customer' || role == 'user') ? 'Pelanggan' : 'Admin';
    _roleController = TextEditingController(text: roleBadgeText);
    _addressController = TextEditingController(text: widget.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _userIdController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    
    // We get the stored password to send it along since API might require it
    final storedPassword = await UserSessionService().getStoredPassword(widget.session.username) ?? '';

    final result = await UserService().updateProfile(
      token: widget.session.token,
      role: widget.session.role,
      id: widget.session.userId,
      password: storedPassword,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Color(0xFF2EBD59),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Gagal memperbarui profil'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.session.role.toLowerCase();
    final isCustomer = role == 'customer' || role == 'user';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF729AC4), Color(0xFF031B46)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF729AC4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Edit Profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Image.asset(
                      'assets/additional_icons/Bell.png',
                      width: 32,
                      height: 32,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Content Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 55,
                          backgroundColor: Color.fromARGB(160, 194, 212, 230),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Color(0xFF729AC4),
                          ),
                        ),
                        const SizedBox(height: 50),
                        
                        _buildInputField(label: 'Nama Lengkap', controller: _nameController),
                        _buildInputField(label: 'Username', controller: _usernameController, enabled: false),
                        _buildInputField(label: 'User ID', controller: _userIdController, enabled: false),
                        _buildInputField(label: 'No Telepon', controller: _phoneController),
                        _buildInputField(label: 'Posisi', controller: _roleController, enabled: false),
                        
                        if (isCustomer)
                          _buildInputField(label: 'Alamat Lengkap', controller: _addressController),
                        
                        const SizedBox(height: 32),
                        
                        // Button
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5A8FD4), Color(0xFF033A82)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  'Konfirmasi Perubahan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? Colors.transparent : Colors.grey.withOpacity(0.05),
          border: Border.all(color: const Color(0xFF035191).withOpacity(0.4), width: 1.2),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF729AC4),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: TextField(
                controller: controller,
                enabled: enabled,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: enabled ? const Color(0xFF033A82) : const Color(0xFF033A82).withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
