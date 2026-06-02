import 'package:flutter/material.dart';
import '../../models/user_session.dart';
import '../../services/user_session_service.dart';
import '../../services/user_service.dart';
import '../../widgets/navBar_widget.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // Tracks if the user is actively changing password
  bool _isChangingPassword = false;
  UserSession? _session;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String _storedPassword = '';
  // The admin account's actual `id` from the API (distinct from `user_id`)
  String _accountId = '';

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _loadSession();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final session = await UserSessionService().getCurrentSession();
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final apiData = await UserService().fetchProfile(
      token: session.token,
      role: session.role,
    );

    UserSession updatedSession = session;
    if (apiData != null) {
      final userObj = apiData['user'] as Map<String, dynamic>?;
      // Store the admin account `id` separately for API calls like delete
      // Check top-level first, then inside 'user' object
      _accountId = (apiData['id'] ?? userObj?['id'] ?? apiData['user_id'])?.toString() ?? session.userId;
      updatedSession = UserSession(
        username: userObj?['username']?.toString() ?? session.username,
        name: apiData['name']?.toString() ?? session.name,
        userId: (apiData['id'] ?? apiData['user_id'])?.toString() ??
            session.userId,
        phone: apiData['phone']?.toString() ?? session.phone,
        role: userObj?['role']?.toString() ?? session.role,
        createdAt: apiData['createdAt']?.toString() ?? session.createdAt,
        token: session.token,
      );
      await UserSessionService().saveCurrentSession(updatedSession);
    } else {
      _accountId = session.userId;
    }

    final storedPassword =
        await UserSessionService().getStoredPassword(updatedSession.username);

    if (!mounted) return;
    setState(() {
      _session = updatedSession;
      _isLoading = false;
      _nameController.text = updatedSession.name;
      _phoneController.text = updatedSession.phone;
      _storedPassword = storedPassword ?? '';
      _passwordController.text = _storedPassword;
    });
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing && _isChangingPassword) {
        // If exiting edit mode, reset password change flag
        _isChangingPassword = false;
      }
      if (_isEditing && _session != null) {
        _nameController.text = _session!.name;
        _phoneController.text = _session!.phone;
        _passwordController.text = _storedPassword;
      }
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (_session == null || _session!.token.isEmpty) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final id = _session!.userId.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap wajib diisi')),
      );
      return;
    }

    if (_isChangingPassword && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password wajib diisi')),
      );
      return;
    }

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID pengguna tidak ditemukan')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await UserService().updateProfile(
      token: _session!.token,
      role: _session!.role,
      id: id,
      password: _isChangingPassword ? password : _storedPassword,
      name: name,
      phone: phone,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result['success'] == true) {
      final data = result['data'];
      final Map<String, dynamic>? profileData =
          data is Map<String, dynamic> ? data : null;

      final updatedSession = UserSession(
        username: _session!.username,
        name: profileData?['name']?.toString() ?? name,
        userId: (profileData?['id'] ?? profileData?['user_id'])?.toString() ?? id,
        phone: profileData?['phone']?.toString() ?? phone,
        role: _session!.role,
        createdAt:
            profileData?['createdAt']?.toString() ?? _session!.createdAt,
        token: _session!.token,
      );

      await UserSessionService().saveCurrentSession(updatedSession);
      
      if (_isChangingPassword) {
        await UserSessionService().saveRegisteredAccount(
          username: updatedSession.username,
          password: password,
          name: updatedSession.name,
          userId: updatedSession.userId,
          phone: updatedSession.phone,
          role: updatedSession.role,
          createdAt: updatedSession.createdAt,
        );
      }

      if (!mounted) return;

      setState(() {
        _session = updatedSession;
        _isEditing = false;
        _storedPassword = _isChangingPassword ? password : _storedPassword;
        _isChangingPassword = false;
        _nameController.text = updatedSession.name;
        _phoneController.text = updatedSession.phone;
        _passwordController.text = _storedPassword;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Profil berhasil diperbarui',
          ),
          backgroundColor: const Color(0xFF2EBD59),
        ),
      );
    } else {
      final message = result['message'];
      String errorText = 'Gagal memperbarui profil';
      if (message is String && message.isNotEmpty) {
        errorText = message;
      } else if (message is Map) {
        errorText = message.values
            .expand((v) => v is List ? v : [v])
            .map((e) => e.toString())
            .join(' ');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorText.trim()),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      return '$day/$month/$year';
    } catch (e) {
      if (dateStr.length >= 10) {
        final parts = dateStr.substring(0, 10).split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }
      return '10/10/2026';
    }
  }

  Future<void> _confirmDeleteAccount() async {
    bool isDeleting = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFF8F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.delete_forever_rounded, color: Color(0xFFB71C1C), size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Hapus Akun',
                    style: TextStyle(
                      color: Color(0xFFB71C1C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Apakah Anda yakin ingin menghapus akun ini secara permanen? Semua data Anda akan dihapus dan tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(color: Color(0xFF330000), fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF729AC4))),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() {
                            isDeleting = true;
                          });
                          
                          final result = await UserService().deleteAccount(
                            token: _session!.token,
                            id: _accountId,
                          );
                          
                          if (!ctx.mounted) return;
                          setDialogState(() {
                            isDeleting = false;
                          });
                          
                          Navigator.pop(ctx);
                          
                          if (result['success'] == true) {
                            setState(() {
                              _isChangingPassword = false;
                            });
                            await UserSessionService().clearCurrentSession();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Akun Anda berhasil dihapus secara permanen.'),
                                  backgroundColor: Color(0xFF2EBD59),
                                ),
                              );
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Gagal menghapus akun.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Hapus Akun', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _session?.role.toLowerCase() ?? 'admin';
    final isCustomer = role == 'customer' || role == 'user';
    final roleBadgeText = isCustomer ? 'Pelanggan' : 'Admin';

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
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _session == null
                  ? const Center(
                      child: Text(
                        'Data profil tidak ditemukan. Silakan login kembali.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.topRight,
                                child: Image.asset(
                                  'assets/additional_icons/Bell.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Static Circle Avatar (no image picker overlay)
                              const CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF729AC4),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _session!.name.isEmpty ? '-' : _session!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${_session!.username}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  roleBadgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
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
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                              child: Column(
                                children: [
                                  if (!_isEditing)
                                    _buildActionButton(
                                      label: 'Edit Profil',
                                      icon: Icons.person_outline,
                                      iconColor: const Color(0xFF036BA1),
                                      borderColor: const Color(0xFF035191).withOpacity(0.3),
                                      textColor: const Color(0xFF036BA1),
                                      onTap: _toggleEdit,
                                    ),
                                  if (!_isEditing) const SizedBox(height: 20),
                                  _buildInfoRow(
                                    label: 'Nama Lengkap',
                                    value: _session!.name.isEmpty
                                        ? _session!.username
                                        : _session!.name,
                                    controller: _nameController,
                                    editable: _isEditing,
                                  ),
                                  _buildInfoRow(
                                    label: 'Username',
                                    value: _session!.username,
                                    editable: false,
                                  ),
                                  _buildInfoRow(
                                    label: 'User ID',
                                    value: _session!.userId,
                                    editable: false,
                                  ),
                                  _buildInfoRow(
                                    label: 'No Telepon',
                                    value: _session!.phone,
                                    controller: _phoneController,
                                    editable: _isEditing,
                                  ),
                                  if (_isChangingPassword)
                                    _buildInfoRow(
                                      label: 'Password',
                                      value: '',
                                      controller: _passwordController,
                                      editable: true,
                                      obscureText: true,
                                    ),
                                  _buildInfoRow(
                                    label: 'Posisi',
                                    value: roleBadgeText,
                                    editable: false,
                                  ),
                                  _buildInfoRow(
                                    label: 'Tanggal Akun Dibuat',
                                    value: _formatDate(_session!.createdAt),
                                    editable: false,
                                  ),
                                  if (_isEditing) ...[
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildGradientButton(
                                            text: _isSaving ? 'Menyimpan...' : 'Simpan',
                                            colors: const [
                                              Color(0xFF729AC4),
                                              Color(0xFF033A82),
                                            ],
                                            onTap: _isSaving ? () {} : _saveProfile,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildGradientButton(
                                            text: 'Batal',
                                            colors: const [
                                              Color(0xFF8BB8E0),
                                              Color(0xFF4A90E6),
                                            ],
                                            onTap: _toggleEdit,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  if (!_isEditing)
                                    _buildActionButton(
                                      label: 'Ganti Password',
                                      icon: Icons.lock_outline,
                                      iconColor: const Color(0xFF4CAF50),
                                      borderColor: const Color(0xFF4CAF50),
                                      textColor: const Color(0xFF4CAF50),
                                      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                                      onTap: () {
                                        setState(() {
                                          _isEditing = true;
                                          _isChangingPassword = true;
                                          // Ensure password field is cleared for new input
                                          _passwordController.text = '';
                                        });
                                      },
                                    ),
                                  const SizedBox(height: 16),
                                  _buildGradientButton(
                                    text: 'Keluar Dari Akun',
                                    colors: const [
                                      Color(0xFFFF9800),
                                      Color(0xFFE65100),
                                    ],
                                    onTap: () async {
                                      await UserSessionService().clearCurrentSession();
                                      if (!mounted) return;
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/',
                                        (route) => false,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  if (role == 'admin')
                                    _buildBorderedButton(
                                      text: 'Hapus Akun',
                                      borderColor: const Color(0xFFB71C1C),
                                      textColor: const Color(0xFFB71C1C),
                                      backgroundColor: const Color(0xFFFFEBEE),
                                      onTap: _confirmDeleteAccount,
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
      bottomNavigationBar: CustomBottomNavBar(
        role: role,
        currentIndex: role == 'customer' || role == 'user' ? 2 : 3,
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    TextEditingController? controller,
    bool editable = false,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF729AC4),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (editable && controller != null)
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF033A82),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            )
          else
            Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Color(0xFF033A82),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required Color textColor,
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(icon, color: iconColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required List<Color> colors,
    required VoidCallback onTap,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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

  Widget _buildBorderedButton({
    required String text,
    required Color borderColor,
    required Color textColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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