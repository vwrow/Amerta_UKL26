import 'package:flutter/material.dart';
import '../../models/user_session.dart';
import '../../models/bill_model.dart';
import '../../models/pelanggan_model.dart';
import '../../services/user_session_service.dart';
import '../../services/bill_service.dart';
import '../../services/pelanggan_service.dart';
import '../../widgets/navBar_widget.dart';
import 'verifikasiTagihan_view.dart';

class KelolaTagihanView extends StatefulWidget {
  const KelolaTagihanView({super.key});

  @override
  State<KelolaTagihanView> createState() => _KelolaTagihanViewState();
}

class _KelolaTagihanViewState extends State<KelolaTagihanView> {
  UserSession? _session;
  List<BillModel> _billsList = [];
  List<PelangganModel> _pelangganList = [];
  bool _isLoading = true;
  String? _errorMessage;

  final BillService _billService = BillService();
  final PelangganService _pelangganService = PelangganService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // Filter: 'semua', 'verifikasi', 'lunas', 'menunggu'
  String _statusFilter = 'semua';

  @override
  void initState() {
    super.initState();
    _loadSessionAndData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionAndData() async {
    try {
      final session = await UserSessionService().getCurrentSession();
      if (!mounted) return;

      setState(() {
        _session = session;
      });

      if (session != null && session.token.isNotEmpty) {
        final bills = await _billService.getBills(token: session.token);
        final customers = await _pelangganService.getPelanggan(
          token: session.token,
        );

        if (!mounted) return;

        setState(() {
          if (bills != null) {
            _billsList = bills;
            _errorMessage = null;
          } else {
            _errorMessage = 'Gagal memuat data tagihan';
          }
          if (customers != null) {
            _pelangganList = customers;
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
    final bills = await _billService.getBills(token: _session!.token);
    if (!mounted) return;
    setState(() {
      if (bills != null) {
        _billsList = bills;
        _errorMessage = null;
      }
    });
  }

  List<BillModel> get _filteredBillsList {
    List<BillModel> list = _billsList;

    // Apply status filter
    if (_statusFilter == 'verifikasi') {
      list = list.where((item) {
        final hasProof = item.payment != null &&
            item.payment!.paymentProof.trim().isNotEmpty;
        return hasProof && !item.verifiedPayment;
      }).toList();
    } else if (_statusFilter == 'lunas') {
      list = list.where((item) => item.verifiedPayment).toList();
    } else if (_statusFilter == 'menunggu') {
      list = list.where((item) {
        final hasProof = item.payment != null &&
            item.payment!.paymentProof.trim().isNotEmpty;
        return !hasProof && !item.verifiedPayment;
      }).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((item) {
        final customerName = item.customer?.name.toLowerCase() ?? '';
        final serviceName = item.service?.name.toLowerCase() ?? '';
        final measurementNumber = item.measurementNumber.toLowerCase();
        return customerName.contains(query) ||
            serviceName.contains(query) ||
            measurementNumber.contains(query);
      }).toList();
    }

    return list;
  }

  String _getFriendlyTime(String createdAtStr) {
    try {
      final createdAt = DateTime.parse(createdAtStr);
      final difference = DateTime.now().difference(createdAt);
      if (difference.inDays > 0) {
        return '${difference.inDays}h lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}j lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return '5h lalu';
    }
  }

  // ─── Add / Edit Bill Dialog ──────────────────────────────────────
  void _showBillDialog({BillModel? existing}) {
    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();

    // Controllers
    final monthCtrl = TextEditingController(
      text: existing?.month.toString() ?? DateTime.now().month.toString(),
    );
    final yearCtrl = TextEditingController(
      text: existing?.year.toString() ?? DateTime.now().year.toString(),
    );
    final measurementNumberCtrl = TextEditingController(
      text:
          existing?.measurementNumber ??
          'M-${100000 + (DateTime.now().millisecond * 133) % 899999}',
    );
    final usageValueCtrl = TextEditingController(
      text: existing?.usageValue.toString() ?? '',
    );

    int? selectedCustomerId = existing?.customerId;
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
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
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
                              isEdit ? 'Edit Tagihan' : 'Tambah Tagihan',
                              style: const TextStyle(
                                color: Color(0xFF033A82),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Customer Selection (Create only)
                        if (!isEdit) ...[
                          _buildFieldLabel('Pilih Pelanggan'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: selectedCustomerId,
                            hint: const Text(
                              'Pilih pelanggan terdaftar',
                              style: TextStyle(
                                color: Color(0xFF729AC4),
                                fontSize: 14,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
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
                            ),
                            items: _pelangganList.map((customer) {
                              return DropdownMenuItem<int>(
                                value: customer.id,
                                child: Text(
                                  '${customer.name} (${customer.customerNumber})',
                                  style: const TextStyle(
                                    color: Color(0xFF031B46),
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: isSaving
                                ? null
                                : (val) {
                                    setDialogState(() {
                                      selectedCustomerId = val;
                                    });
                                  },
                            validator: (v) =>
                                v == null ? 'Silakan pilih pelanggan' : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Month Field
                        _buildFieldLabel('Bulan (1 - 12)'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: monthCtrl,
                          hint: 'Contoh: 6 untuk Juni',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Wajib diisi';
                            final m = int.tryParse(v);
                            if (m == null || m < 1 || m > 12)
                              return 'Bulan harus 1 - 12';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Year Field
                        _buildFieldLabel('Tahun'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: yearCtrl,
                          hint: 'Contoh: 2026',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Wajib diisi';
                            final y = int.tryParse(v);
                            if (y == null || y < 2000 || y > 2100)
                              return 'Tahun tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Meter measurement number
                        _buildFieldLabel('No Meteran'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: measurementNumberCtrl,
                          hint: 'Contoh: M-132422',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Usage Value
                        _buildFieldLabel('Total Penggunaan (m³)'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: usageValueCtrl,
                          hint: 'Contoh: 33',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Wajib diisi';
                            final val = int.tryParse(v);
                            if (val == null || val < 0)
                              return 'Penggunaan tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Gradient Button
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A90E2), Color(0xFF0B4B85)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate())
                                      return;
                                    setDialogState(() => isSaving = true);

                                    final token = _session!.token;
                                    Map<String, dynamic> result;

                                    if (isEdit) {
                                      result = await _billService.updateBill(
                                        token: token,
                                        id: existing.id,
                                        month: int.parse(monthCtrl.text.trim()),
                                        year: int.parse(yearCtrl.text.trim()),
                                        measurementNumber: measurementNumberCtrl
                                            .text
                                            .trim(),
                                        usageValue: int.parse(
                                          usageValueCtrl.text.trim(),
                                        ),
                                      );
                                    } else {
                                      result = await _billService.createBill(
                                        token: token,
                                        customerId: selectedCustomerId!,
                                        month: int.parse(monthCtrl.text.trim()),
                                        year: int.parse(yearCtrl.text.trim()),
                                        measurementNumber: measurementNumberCtrl
                                            .text
                                            .trim(),
                                        usageValue: int.parse(
                                          usageValueCtrl.text.trim(),
                                        ),
                                      );
                                    }

                                    if (!ctx.mounted) return;

                                    if (result['success'] == true) {
                                      Navigator.pop(ctx);
                                      _refreshData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['message'] ??
                                                  (isEdit
                                                      ? 'Tagihan diperbarui'
                                                      : 'Tagihan ditambahkan'),
                                            ),
                                            backgroundColor: const Color(
                                              0xFF2EBD59,
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      setDialogState(() => isSaving = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['message'] ??
                                                  'Terjadi kesalahan',
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
                                    isEdit
                                        ? 'Simpan Perubahan'
                                        : 'Tambah Tagihan',
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Color(0xFF031B46), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF729AC4), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
    );
  }

  // ─── Delete Bill Dialog ──────────────────────────────────────────
  void _showDeleteDialog(BillModel item) {
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
                'Hapus Tagihan',
                style: TextStyle(
                  color: Color(0xFF8B1A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Apakah Anda yakin ingin menghapus tagihan pelanggan "${item.customer?.name ?? 'Pelanggan'}"?',
                style: const TextStyle(color: Color(0xFF031B46), fontSize: 14),
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

                          final result = await _billService.deleteBill(
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
                                    result['message'] ?? 'Tagihan dihapus',
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

  // ─── Build Empty State ───────────────────────────────────────────
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
              'Belum Ada Tagihan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0B4B85),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tambah tagihan untuk pelanggan tersedia',
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

  // ─── Filter Chip ─────────────────────────────────────────────────
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF5A8FD4), Color(0xFF033A82)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xFF035191).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF035191),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── Build Bills List ────────────────────────────────────────────
  Widget _buildBillsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      itemCount: _filteredBillsList.length,
      itemBuilder: (context, index) {
        final item = _filteredBillsList[index];
        final customerName = item.customer?.name ?? 'Sonthony Mackie';
        final serviceName = item.service?.name ?? 'Rumah B';
        final friendlyTime = _getFriendlyTime(item.createdAt);
        final priceFormatted =
            'Rp ${item.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

        // Check if verified
        final isVerified = item.verifiedPayment;
        final hasPaymentProof =
            item.payment != null &&
            item.payment!.paymentProof.trim().isNotEmpty;
        final canVerify = hasPaymentProof && !isVerified;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF035191).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Row 1: Profile and Action Edit/Delete
              Row(
                children: [
                  // Circular Avatar containing clean icon (per user instruction)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8EEF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF729AC4),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            color: Color(0xFF033A82),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$serviceName   •   $friendlyTime',
                          style: const TextStyle(
                            color: Color(0xFF729AC4),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pencil and Trash
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showBillDialog(existing: item),
                        child: Image.asset(
                          'assets/additional_icons/edit.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showDeleteDialog(item),
                        child: Image.asset(
                          'assets/additional_icons/delete.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 2: Price Box and Verification Button
              Row(
                children: [
                  // Left Amount Display
                  Expanded(
                    flex: 4,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isVerified
                              ? const [
                                  Color.fromARGB(10, 0, 210, 112),
                                  Color.fromARGB(10, 13, 140, 66),
                                ]
                              : canVerify
                              ? const [
                                  Color.fromARGB(10, 90, 143, 212),
                                  Color.fromARGB(10, 3, 106, 161),
                                ]
                              : const [
                                  Color.fromARGB(10, 168, 192, 189),
                                  Color.fromARGB(10, 111, 114, 128),
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        border: Border.all(
                          color: isVerified
                              ? const Color.fromARGB(255, 0, 210, 112).withOpacity(0.4)
                              : canVerify
                              ? const Color.fromARGB(255, 90, 143, 212).withOpacity(0.4)
                              : const Color.fromARGB(255, 168, 192, 189).withOpacity(0.4),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        priceFormatted,
                        style: TextStyle(
                          color: isVerified
                              ? const Color(0xFF0D8C42)
                              : canVerify
                              ? const Color(0xFF036BA1)
                              : const Color(0xFF6F7280),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Right Action Button
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Matches the button's shape
                          gradient: isVerified
                              ? const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF00D270),
                                    Color(0xFF0D8C42),
                                  ],
                                )
                              : canVerify
                              ? const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF5A8FD4),
                                    Color(0xFF036BA1),
                                  ],
                                )
                              : const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFA8C0BD),
                                    Color(0xFF6F7280),
                                  ],
                                ),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isVerified) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tagihan ini sudah lunas terverifikasi',
                                  ),
                                  backgroundColor: Color(
                                    0xFF2EBD59,
                                  ), // Snackbar color untouched
                                ),
                              );
                              return;
                            }

                            if (!canVerify) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Pelanggan belum mengunggah bukti pembayaran',
                                  ),
                                  backgroundColor:
                                      Colors.orange, // Snackbar color untouched
                                ),
                              );
                              return;
                            }

                            // Open payment verification screen
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VerifikasiTagihanView(
                                  bill: item,
                                  token: _session!.token,
                                ),
                              ),
                            );

                            if (result == true) {
                              _refreshData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isVerified
                                ? 'Tagihan Lunas'
                                : canVerify
                                ? 'Verifikasi'
                                : 'Menunggu Bukti',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Build Main ──────────────────────────────────────────────────
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
            colors: [Color(0xFF729AC4), Color(0xFF031B46)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Kelola Tagihan',
                          style: TextStyle(
                            color: Color(0xFFE8EEF5),
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
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // White Content Area
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
                      : Column(
                          children: [
                            // Search Bar
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Cari Tagihan',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF035191),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF035191),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFC2D4E6).withOpacity(0.4),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF035191).withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF033A82),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF035191),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            // Filter Chips
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip('Semua', 'semua'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Perlu Verifikasi', 'verifikasi'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Sudah Lunas', 'lunas'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Menunggu Bukti', 'menunggu'),
                                  ],
                                ),
                              ),
                            ),
                            // List
                            Expanded(
                              child: _filteredBillsList.isEmpty
                                  ? _buildEmptyState()
                                  : _buildBillsList(),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBillDialog(),
        backgroundColor: const Color(0xFF0B4B85),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, color: Colors.white, size: 36),
      ),
      bottomNavigationBar: CustomBottomNavBar(role: 'admin', currentIndex: 3),
    );
  }
}
