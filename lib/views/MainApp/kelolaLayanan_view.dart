import 'package:flutter/material.dart';
import '../../models/user_session.dart';
import '../../models/layanan_model.dart';
import '../../services/user_session_service.dart';
import '../../services/layanan_service.dart';
import '../../widgets/navBar_widget.dart';
import '../../widgets/layanan_card.dart';

class KelolaLayananView extends StatefulWidget {
  const KelolaLayananView({super.key});

  @override
  State<KelolaLayananView> createState() => _KelolaLayananViewState();
}

class _KelolaLayananViewState extends State<KelolaLayananView> {
  UserSession? _session;
  List<LayananModel> _layananList = [];
  bool _isLoading = true;
  String? _errorMessage;

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
        final data = await _layananService.getLayanan(token: session.token);
        if (!mounted) return;
        setState(() {
          if (data != null) {
            _layananList = data;
            _errorMessage = null;
          } else {
            _errorMessage = 'Gagal memuat data layanan';
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
    final data = await _layananService.getLayanan(token: _session!.token);
    if (!mounted) return;
    setState(() {
      if (data != null) {
        _layananList = data;
        _errorMessage = null;
      }
    });
  }

  bool get _hasValidSession =>
      _session != null && _session!.token.isNotEmpty;

  // ─── Add / Edit Dialog ───────────────────────────────────────────
  void _showLayananDialog({LayananModel? existing}) {
    if (!_hasValidSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi tidak valid. Silakan login kembali.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final minCtrl =
        TextEditingController(text: existing?.minUsage.toString() ?? '');
    final maxCtrl =
        TextEditingController(text: existing?.maxUsage.toString() ?? '');
    final priceCtrl =
        TextEditingController(text: existing?.price.toString() ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Back + Title
                        Row(
                          children: [
                            GestureDetector(
                              onTap: isSaving ? null : () => Navigator.pop(ctx),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF729AC4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              isEdit ? 'Edit Layanan' : 'Tambah Layanan',
                              style: const TextStyle(
                                color: Color(0xFF033A82),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Nama Layanan
                        _buildDialogField(
                          controller: nameCtrl,
                          label: 'Nama Layanan',
                          hint: 'Contoh: Rumah Medium A',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nama tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Min Penggunaan
                        _buildDialogField(
                          controller: minCtrl,
                          label: 'Min Penggunaan',
                          hint: 'Xx m³',
                          keyboardType: TextInputType.number,
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: 16),
                        // Max Penggunaan
                        _buildDialogField(
                          controller: maxCtrl,
                          label: 'Max Penggunaan',
                          hint: 'Xx m³',
                          keyboardType: TextInputType.number,
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: 16),
                        // Harga / m³
                        _buildDialogField(
                          controller: priceCtrl,
                          label: 'Harga / m³',
                          hint: 'Rp X.xxx',
                          keyboardType: TextInputType.number,
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: 30),
                        // Submit Button
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
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;

                                    final min = int.tryParse(minCtrl.text.trim());
                                    final max = int.tryParse(maxCtrl.text.trim());
                                    if (min == null || max == null) return;

                                    if (max < min) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Max penggunaan harus lebih besar atau sama dengan min',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSaving = true);

                                    final token = _session!.token;
                                    Map<String, dynamic> result;

                                    if (isEdit) {
                                      result = await _layananService.updateLayanan(
                                        token: token,
                                        id: existing.id,
                                        name: nameCtrl.text.trim(),
                                        minUsage: minCtrl.text.trim(),
                                        maxUsage: maxCtrl.text.trim(),
                                        price: priceCtrl.text.trim(),
                                      );
                                    } else {
                                      result = await _layananService.createLayanan(
                                        token: token,
                                        name: nameCtrl.text.trim(),
                                        minUsage: minCtrl.text.trim(),
                                        maxUsage: maxCtrl.text.trim(),
                                        price: priceCtrl.text.trim(),
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
                                                      ? 'Layanan diperbarui'
                                                      : 'Layanan ditambahkan'),
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
                              foregroundColor: Colors.white,
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
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isEdit ? 'Simpan' : 'Tambah Layanan',
                                    style: const TextStyle(
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

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }
    if (int.tryParse(value.trim()) == null) {
      return 'Harus berupa angka';
    }
    return null;
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF033A82),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ],
    );
  }

  // ─── Delete Confirmation Dialog ──────────────────────────────────
  void _showDeleteDialog(LayananModel item) {
    if (!_hasValidSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi tidak valid. Silakan login kembali.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
                'Hapus Layanan',
                style: TextStyle(
                  color: Color(0xFF8B1A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Apakah Anda yakin ingin menghapus layanan "${item.name}"?',
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

                          final result = await _layananService.deleteLayanan(
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
                                    result['message'] ?? 'Layanan dihapus',
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Blue Icon with Ban Symbol
            Image.asset(
              'assets/additional_icons/cuciTangan.png',
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 32),
            const Text(
              'Belum Ada Layanan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0B4B85),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tambahkan layanan baru beserta datanya',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF729AC4),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kelola Layanan',
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
                          : _layananList.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 24, 20, 80),
                                  itemCount: _layananList.length,
                                  itemBuilder: (context, index) {
                                    final item = _layananList[index];
                                    return LayananCard(
                                      layanan: item,
                                      onEdit: () =>
                                          _showLayananDialog(existing: item),
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
      floatingActionButton: _hasValidSession
          ? FloatingActionButton(
              onPressed: () => _showLayananDialog(),
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
            )
          : null,
      bottomNavigationBar: CustomBottomNavBar(
        role: role,
        currentIndex: 2,
      ),
    );
  }
}