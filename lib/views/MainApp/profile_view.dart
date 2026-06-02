import 'package:flutter/material.dart';
import '../../models/user_session.dart';
import '../../services/user_session_service.dart';
import '../../services/user_service.dart';
import '../../widgets/navBar_widget.dart';
import 'editProfil_view.dart';
import 'gantiPassword_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  UserSession? _session;
  bool _isLoading = true;
  String _address = '-';
  // The admin account's actual `id` from the API (distinct from `user_id`)
  String _accountId = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
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

    final addressStr = apiData != null ? apiData['address']?.toString() : null;

    if (!mounted) return;
    setState(() {
      _session = updatedSession;
      _address = addressStr ?? '-';
      _isLoading = false;
    });
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
                                  _buildActionButton(
                                    label: 'Edit Profil',
                                    backgroundColor: Color(0xFFC2D4E6).withOpacity(0.4),
                                    icon: Icons.person_outline,
                                    iconColor: const Color(0xFF036BA1),
                                    borderColor: const Color(0xFF035191).withOpacity(0.3),
                                    textColor: const Color(0xFF036BA1),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProfilView(
                                            session: _session!,
                                            address: _address,
                                          ),
                                        ),
                                      );
                                      _loadSession();
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInfoRow(
                                    label: 'Nama Lengkap',
                                    value: _session!.name.isEmpty
                                        ? _session!.username
                                        : _session!.name,
                                  ),
                                  _buildInfoRow(
                                    label: 'Username',
                                    value: _session!.username,
                                  ),
                                  _buildInfoRow(
                                    label: 'User ID',
                                    value: _session!.userId,
                                  ),
                                  _buildInfoRow(
                                    label: 'No Telepon',
                                    value: _session!.phone,
                                  ),
                                  _buildInfoRow(
                                    label: 'Posisi',
                                    value: roleBadgeText,
                                  ),
                                  if (isCustomer)
                                    _buildInfoRow(
                                      label: 'Alamat Lengkap',
                                      value: _address,
                                    ),
                                  _buildInfoRow(
                                    label: 'Tanggal Akun Dibuat',
                                    value: _formatDate(_session!.createdAt),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildActionButton(
                                    label: 'Ganti Password',
                                    icon: Icons.lock_outline,
                                    iconColor: const Color(0xFF4CAF50),
                                    borderColor: const Color(0xFF4CAF50),
                                    textColor: const Color(0xFF4CAF50),
                                    backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GantiPasswordView(session: _session!),
                                        ),
                                      );
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
        currentIndex: role == 'customer' || role == 'user' ? 2 : 4,
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
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
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF033A82),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
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