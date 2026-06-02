import 'package:flutter/material.dart';
import '../../models/user_session.dart';
import '../../models/pelanggan_model.dart';
import '../../models/layanan_model.dart';
import '../../services/user_session_service.dart';
import '../../services/pelanggan_service.dart';
import '../../services/layanan_service.dart';
import '../../widgets/navBar_widget.dart';
import '../../widgets/pelanggan_card.dart';

class KelolaPelangganView extends StatefulWidget {
  const KelolaPelangganView({super.key});

  @override
  State<KelolaPelangganView> createState() => _KelolaPelangganViewState();
}

class _KelolaPelangganViewState extends State<KelolaPelangganView> {
  UserSession? _session;
  List<PelangganModel> _pelangganList = [];
  List<LayananModel> _layananList = [];
  bool _isLoading = true;
  String? _errorMessage;

  final PelangganService _pelangganService = PelangganService();
  final LayananService _layananService = LayananService();

  @override
  void initState() {
    super.initState();
    _loadSessionAndData();
  }

  Future<void> _loadSessionAndData() async {
    try {
      final session = await UserSessionService().getCurrentSession();
      if (!mounted) return;

      setState(() {
        _session = session;
      });

      if (session != null && session.token.isNotEmpty) {
        // Fetch pelanggan list
        final data = await _pelangganService.getPelanggan(token: session.token);
        // Fetch services for selector
        final services = await _layananService.getLayanan(token: session.token);

        if (!mounted) return;

        setState(() {
          if (data != null) {
            _pelangganList = data;
            _errorMessage = null;
          } else {
            _errorMessage = 'Gagal memuat data pelanggan';
          }
          if (services != null) {
            _layananList = services;
          }
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Sesi tidak valid. Silakan login kembali.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (_session == null || _session!.token.isEmpty) return;
    final data = await _pelangganService.getPelanggan(token: _session!.token);
    if (!mounted) return;
    setState(() {
      if (data != null) {
        _pelangganList = data;
        _errorMessage = null;
      }
    });
  }

  /// Returns the smallest available number C-1, C-2, ... not already in use.
  String _generateNextCustomerNumber() {
    final usedNumbers = <int>{};
    final pattern = RegExp(r'^C-(\d+)$', caseSensitive: false);

    for (final pelanggan in _pelangganList) {
      final match = pattern.firstMatch(pelanggan.customerNumber.trim());
      if (match != null) {
        usedNumbers.add(int.parse(match.group(1)!));
      }
    }

    var candidate = 1;
    while (usedNumbers.contains(candidate)) {
      candidate++;
    }
    return 'C-$candidate';
  }

  // ─── Add / Edit Dialog ───────────────────────────────────────────
  void _showPelangganDialog({PelangganModel? existing}) {
    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();

    // Controllers
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final customerNumber = isEdit
        ? existing.customerNumber
        : _generateNextCustomerNumber();
    final customerNumberCtrl = TextEditingController(text: customerNumber);
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');

    int? selectedServiceId = existing?.serviceId;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFF0F7FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            InkWell(
                              onTap: isSaving ? null : () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF729AC4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan',
                              style: const TextStyle(
                                color: Color(0xFF033A82),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Username field (Create only)
                        if (!isEdit) ...[
                          _buildFieldLabel('Username'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: usernameCtrl,
                            hint: 'Masukkan username',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Username tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Password field (Create only)
                          _buildFieldLabel('Password'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: passwordCtrl,
                            hint: 'Masukkan password',
                            obscureText: true,
                            caption: 'Password minimal 8 karakter dengan simbol dan angka',
                            validator: (v) => (v == null || v.length < 8)
                                ? 'Password minimal 8 karakter'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Full Name
                        _buildFieldLabel('Nama Lengkap Pelanggan'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: nameCtrl,
                          hint: 'Masukkan Nama Lengkap',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nama tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Customer Number
                        _buildFieldLabel('No Pelanggan'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: customerNumberCtrl,
                          hint: 'C-1',
                          caption: 'Otomatis terisi',
                          readOnly: true,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nomor pelanggan tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Phone Number
                        _buildFieldLabel('No Telepon'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: phoneCtrl,
                          hint: '08XXXXXXXXXX',
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nomor telepon tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Address
                        _buildFieldLabel('Alamat Lengkap'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: addressCtrl,
                          hint: 'Masukkan alamat lengkap',
                          maxLines: 2,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Alamat tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Service Selector
                        _buildFieldLabel('Pilih Layanan'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: selectedServiceId,
                          hint: const Text(
                            'Pilih layanan tersedia',
                            style: TextStyle(color: Color(0xFF729AC4), fontSize: 14),
                          ),
                          dropdownColor: Colors.white,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF729AC4), width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF729AC4), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF033A82), width: 2),
                            ),
                          ),
                          items: _layananList.map((layanan) {
                            return DropdownMenuItem<int>(
                              value: layanan.id,
                              child: Text(
                                '${layanan.name} (Rp ${layanan.price}/m³)',
                                style: const TextStyle(color: Color(0xFF031B46), fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  setDialogState(() {
                                    selectedServiceId = val;
                                  });
                                },
                          validator: (v) => v == null ? 'Silakan pilih layanan' : null,
                        ),
                        const SizedBox(height: 32),

                        // Gradient Button
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4A90E2),
                                Color(0xFF0B4B85),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setDialogState(() => isSaving = true);

                                    final token = _session!.token;
                                    Map<String, dynamic> result;

                                    if (isEdit) {
                                      result = await _pelangganService.updatePelanggan(
                                        token: token,
                                        id: existing.id,
                                        customerNumber: customerNumberCtrl.text.trim(),
                                        address: addressCtrl.text.trim(),
                                        serviceId: selectedServiceId!,
                                        name: nameCtrl.text.trim(),
                                        phone: phoneCtrl.text.trim(),
                                      );
                                    } else {
                                      result = await _pelangganService.createPelanggan(
                                        token: token,
                                        username: usernameCtrl.text.trim(),
                                        password: passwordCtrl.text.trim(),
                                        customerNumber: customerNumberCtrl.text.trim(),
                                        address: addressCtrl.text.trim(),
                                        serviceId: selectedServiceId!,
                                        name: nameCtrl.text.trim(),
                                        phone: phoneCtrl.text.trim(),
                                      );
                                    }

                                    if (!ctx.mounted) return;

                                    if (result['success'] == true) {
                                      Navigator.pop(ctx);
                                      _refreshData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['message'] ??
                                                  (isEdit
                                                      ? 'Pelanggan diperbarui'
                                                      : 'Pelanggan ditambahkan'),
                                            ),
                                            backgroundColor: const Color(0xFF2EBD59),
                                          ),
                                        );
                                      }
                                    } else {
                                      setDialogState(() => isSaving = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['message'] ?? 'Terjadi kesalahan',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isEdit ? 'Simpan Perubahan' : 'Tambah Pelanggan',
                                    style: const TextStyle(
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
            );
          },
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF033A82),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    bool readOnly = false,
    String? caption,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          validator: validator,
          style: TextStyle(
            color: readOnly
                ? const Color(0xFF729AC4)
                : const Color(0xFF031B46),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF729AC4), fontSize: 14),
            filled: true,
            fillColor: readOnly ? const Color(0xFFE8EEF5) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF729AC4), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF729AC4), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF033A82), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(color: Color(0xFF729AC4), fontSize: 11),
          ),
        ]
      ],
    );
  }

  // ─── Delete Confirmation Dialog ──────────────────────────────────
  void _showDeleteDialog(PelangganModel item) {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFE8EEF5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Hapus Pelanggan',
                style: TextStyle(
                  color: Color(0xFF8B1A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Apakah Anda yakin ingin menghapus pelanggan "${item.name}"?',
                style: const TextStyle(
                  color: Color(0xFF031B46),
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Color(0xFF729AC4)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);

                          final result = await _pelangganService.deletePelanggan(
                            token: _session!.token,
                            id: item.id,
                          );

                          if (!ctx.mounted) return;

                          if (result['success'] == true) {
                            Navigator.pop(ctx);
                            _refreshData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ?? 'Pelanggan dihapus',
                                  ),
                                  backgroundColor: const Color(0xFF2EBD59),
                                ),
                              );
                            }
                          } else {
                            setDialogState(() => isDeleting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ?? 'Gagal menghapus',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Hapus'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final role = _session?.role.toLowerCase() ?? 'admin';

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kelola Pelanggan',
                      style: TextStyle(
                        color: Color(0xFFE8EEF5),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.asset(
                      'assets/additional_icons/Bell.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // White Card List Area
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0B4B85),
                          ),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF031B46),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : _pelangganList.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Tidak ada data pelanggan',
                                    style: TextStyle(
                                      color: Color(0xFF031B46),
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
                                  itemCount: _pelangganList.length,
                                  itemBuilder: (context, index) {
                                    final item = _pelangganList[index];
                                    return PelangganCard(
                                      pelanggan: item,
                                      onEdit: () => _showPelangganDialog(existing: item),
                                      onDelete: () => _showDeleteDialog(item),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPelangganDialog(),
        backgroundColor: const Color(0xFF0B4B85),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 36,
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        role: role,
        currentIndex: 1,
      ),
    );
  }
}