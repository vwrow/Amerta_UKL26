import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../../services/bill_service.dart';
import '../../widgets/payment_proof_preview.dart';

class VerifikasiTagihanView extends StatefulWidget {
  final BillModel bill;
  final String token;

  const VerifikasiTagihanView({
    super.key,
    required this.bill,
    required this.token,
  });

  @override
  State<VerifikasiTagihanView> createState() => _VerifikasiTagihanViewState();
}

class _VerifikasiTagihanViewState extends State<VerifikasiTagihanView> {
  bool _isProcessing = false;
  final BillService _billService = BillService();

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

  Future<void> _verifyPayment(bool accept) async {
    final payment = widget.bill.payment;
    if (payment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti pembayaran tidak ditemukan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    Map<String, dynamic> result;
    if (accept) {
      result = await _billService.acceptPayment(
        token: widget.token,
        paymentId: payment.id,
      );
    } else {
      result = await _billService.rejectPayment(
        token: widget.token,
        paymentId: payment.id,
      );
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (accept ? 'Pembayaran berhasil dikonfirmasi' : 'Pembayaran berhasil ditolak')),
          backgroundColor: const Color(0xFF2EBD59),
        ),
      );
      Navigator.pop(context, true); // Return true to refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal memproses verifikasi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final customer = bill.customer;
    final service = bill.service;

    // Customer details
    final customerName = customer?.name ?? 'Sonthony Mackie';
    final customerNum = customer?.customerNumber ?? 'C-33';
    final serviceName = service?.name ?? 'Rumah A';
    final customerAddress = customer?.address ?? 'Jl. Kepala Muda No. 67';

    // Amount formatting
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
                          onTap: _isProcessing ? null : () => Navigator.pop(context),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: Customer Info
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF035191).withOpacity(0.12),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Circular avatar (clean icon per user instructions)
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$customerNum  •  $serviceName  •  $customerAddress',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF729AC4),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card 2: Detail Pembayaran Box
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

                              // Total Row with Solid Blue Box
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

                        // Card 3: Bukti Pembayaran / Receipt Box
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF035191).withOpacity(0.12),
                              width: 1.5,
                            ),
                          ),
                          child: bill.payment == null
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                                  child: Column(
                                    children: [
                                      Icon(Icons.info_outline_rounded, color: Colors.grey, size: 48),
                                      SizedBox(height: 12),
                                      Text(
                                        'Pelanggan belum mengunggah bukti pembayaran',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(12),
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
                                      const SizedBox(height: 12),
                                      PaymentProofPreview(
                                        paymentProof: bill.payment!.paymentProof,
                                        token: widget.token,
                                        height: 320,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Two bottom Action Buttons
                        if (bill.payment != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
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
                                    onPressed: _isProcessing ? null : () => _verifyPayment(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isProcessing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Konfirmasi',
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE65100),
                                        Color(0xFFBF360C),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isProcessing ? null : () => _verifyPayment(false),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isProcessing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Tolak',
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
                        ],
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
