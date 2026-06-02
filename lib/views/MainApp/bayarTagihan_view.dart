import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/bill_model.dart';
import '../../services/bill_service.dart';

class BayarTagihanView extends StatefulWidget {
  final BillModel bill;
  final String token;

  const BayarTagihanView({
    super.key,
    required this.bill,
    required this.token,
  });

  @override
  State<BayarTagihanView> createState() => _BayarTagihanViewState();
}

class _BayarTagihanViewState extends State<BayarTagihanView> {
  File? _selectedFile;
  String? _selectedFileName;
  bool _selectedFileIsPdf = false;
  bool _isUploading = false;
  bool _isSuccess = false;
  BillModel? _updatedBill;

  final BillService _billService = BillService();

  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
  static const _maxFileBytes = 10 * 1024 * 1024; // 10 MB

  String _getMonthName(int monthNum) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (monthNum >= 1 && monthNum <= 12) {
      return months[monthNum - 1];
    }
    return 'Juni';
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final path = picked.path;
      if (path == null || path.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berkas tidak dapat diakses. Coba pilih dari folder lain.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final file = File(path);
      final size = await file.length();
      if (size > _maxFileBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran berkas maksimal 10 MB'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final ext = (picked.extension ?? path.split('.').last).toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipe berkas tidak didukung. Gunakan JPG, PNG, atau PDF.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _selectedFile = file;
        _selectedFileName = picked.name;
        _selectedFileIsPdf = ext == 'pdf';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih berkas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitReceipt() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih berkas bukti pembayaran terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final result = await _billService.uploadPayment(
      token: widget.token,
      billId: widget.bill.id,
      file: _selectedFile!,
      fileName: _selectedFileName,
    );

    if (!mounted) return;

    setState(() {
      _isUploading = false;
    });

    if (result['success'] == true) {
      final paymentData = result['data'];
      // Create the new payment object
      final newPayment = BillPaymentModel.fromJson(paymentData);
      
      // Update local BillModel
      final updated = BillModel(
        id: widget.bill.id,
        customerId: widget.bill.customerId,
        adminId: widget.bill.adminId,
        month: widget.bill.month,
        year: widget.bill.year,
        measurementNumber: widget.bill.measurementNumber,
        usageValue: widget.bill.usageValue,
        price: widget.bill.price,
        serviceId: widget.bill.serviceId,
        paid: widget.bill.paid,
        ownerToken: widget.bill.ownerToken,
        createdAt: widget.bill.createdAt,
        updatedAt: widget.bill.updatedAt,
        service: widget.bill.service,
        admin: widget.bill.admin,
        customer: widget.bill.customer,
        payment: newPayment,
        amount: widget.bill.amount,
        verifiedPayment: false,
      );

      setState(() {
        _isSuccess = true;
        _updatedBill = updated;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengunggah bukti pembayaran'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final formattedPrice = 'Rp ${bill.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

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
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context, _updatedBill ?? widget.bill),
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
                        const Text(
                          'Bayar Tagihan',
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
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Main body
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
                  child: _isSuccess ? _buildSuccessPanel() : _buildUploadForm(formattedPrice),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Upload Form Panel (Mockup 2) ────────────────────────────────
  Widget _buildUploadForm(String formattedPrice) {
    final bill = widget.bill;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: Detail Pembayaran Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF035191).withOpacity(0.12),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Pembayaran',
                  style: TextStyle(
                    color: Color(0xFF033A82),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _buildDetailRow('Periode', '${_getMonthName(bill.month)} ${bill.year}'),
                const Divider(height: 20, color: Color(0xFFE8EEF5)),
                _buildDetailRow('No meteran', bill.measurementNumber),
                const Divider(height: 20, color: Color(0xFFE8EEF5)),
                _buildDetailRow('Total Penggunaan', '${bill.usageValue} m³'),
                const SizedBox(height: 16),

                // Total Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B4B85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formattedPrice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: Bukti Pembayaran Card with File selector
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF035191).withOpacity(0.12),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bukti Pembayaran',
                  style: TextStyle(
                    color: Color(0xFF033A82),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // Dashed box with Pilih Berkas button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF729AC4).withOpacity(0.5),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_selectedFile == null) ...[
                          const Icon(
                            Icons.upload_rounded,
                            color: Color(0xFF0B4B85),
                            size: 64,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Unggah File Disini',
                            style: TextStyle(
                              color: Color(0xFF033A82),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'JPG, PNG, PDF max 10mb',
                            style: TextStyle(
                              color: Color(0xFF729AC4),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _pickFile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B4B85),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text(
                              'Pilih Berkas',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ] else ...[
                          // File preview layout
                          if (_selectedFileIsPdf)
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EEF5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    color: Color(0xFF8B1A1A),
                                    size: 56,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Dokumen PDF',
                                    style: TextStyle(
                                      color: Color(0xFF033A82),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedFile!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFileName ??
                                _selectedFile!.path.split(Platform.pathSeparator).last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF031B46), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _pickFile,
                                icon: Image.asset(
                                  'assets/additional_icons/edit.png',
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                ),
                                label: const Text('Ubah Berkas', style: TextStyle(color: Color(0xFF0B4B85))),
                              ),
                              const SizedBox(width: 16),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedFile = null;
                                    _selectedFileName = null;
                                    _selectedFileIsPdf = false;
                                  });
                                },
                                icon: Image.asset(
                                  'assets/additional_icons/delete.png',
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                ),
                                label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Kirim Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4A90E2),
                    Color(0xFF0B4B85),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kirim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Success Panel Rendering (Mockup 3) ──────────────────────────
  Widget _buildSuccessPanel() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'File Telah Terkirim!',
              style: TextStyle(
                color: Color(0xFF033A82),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Large green folder checkmark icon matching mockup 3
            Image.asset(
              'assets/additional_icons/fileDikirim.png',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 36),

            const Text(
              'Menunggu verifikasi admin',
              style: TextStyle(
                color: Color(0xFF033A82),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tagihan akan ditandai lunas setelah admin memverifikasi bukti dan data pembayaran.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF729AC4),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // Back button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _updatedBill),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4B85),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF729AC4),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF033A82),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
