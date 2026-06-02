import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../../widgets/payment_proof_preview.dart';
import 'bayarTagihan_view.dart';

class RincianTagihanView extends StatefulWidget {
  final BillModel bill;
  final String token;

  const RincianTagihanView({
    super.key,
    required this.bill,
    required this.token,
  });

  @override
  State<RincianTagihanView> createState() => _RincianTagihanViewState();
}

class _RincianTagihanViewState extends State<RincianTagihanView> {
  late BillModel _currentBill;

  @override
  void initState() {
    super.initState();
    _currentBill = widget.bill;
  }

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

  @override
  Widget build(BuildContext context) {
    final customer = _currentBill.customer;
    final service = _currentBill.service;

    // Customer details
    final customerName = customer?.name ?? 'Sonthony Mackie';
    final customerNum = customer?.customerNumber ?? 'C-33';
    final serviceName = service?.name ?? 'Rumah A';
    final customerAddress = customer?.address ?? 'Jl. Danau Poso 1 G2E16';

    // Amount formatting
    final formattedPrice = 'Rp ${_currentBill.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

    // Verification states
    final isVerified = _currentBill.verifiedPayment;
    final hasReceipt = _currentBill.payment != null;

    String statusText = 'Belum bayar';
    Color statusColor = const Color(0xFF8B1A1A); // Red/brown
    
 
    bool isDenied = false;
    if (_currentBill.payment != null && !isVerified) {
      if (_currentBill.payment!.paymentProof == 'rejected' || _currentBill.payment!.totalAmount == 99) {
        isDenied = true;
      }
    }

    if (isVerified) {
      statusText = 'Lunas';
      statusColor = const Color(0xFF2EBD59); // Green
    } else if (isDenied) {
      statusText = 'Ditolak';
      statusColor = const Color(0xFFB71C1C); // Red
    } else if (hasReceipt) {
      statusText = 'Menunggu verifikasi';
      statusColor = const Color(0xFFFF9800); // Orange
    }

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
                          onTap: () => Navigator.pop(context, _currentBill),
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
                          'Rincian Tagihan',
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
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
                              _buildDetailRow('Periode', '${_getMonthName(_currentBill.month)} ${_currentBill.year}'),
                              const Divider(height: 20, color: Color(0xFFE8EEF5)),
                              _buildDetailRow('No meteran', _currentBill.measurementNumber),
                              const Divider(height: 20, color: Color(0xFFE8EEF5)),
                              _buildDetailRow('Total Penggunaan', '${_currentBill.usageValue} m³'),
                              const Divider(height: 20, color: Color(0xFFE8EEF5)),
                              
                              // Status Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Status',
                                    style: TextStyle(
                                      color: Color(0xFF729AC4),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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

                              // Conditional Bukti rendering
                              if (statusText == 'Belum bayar')
                                // Dashed upload area matching mockup 1
                                Container(
                                  width: double.infinity,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFFFB300).withOpacity(0.5),
                                      width: 2,
                                      style: BorderStyle.solid, // Uses standard border
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_rounded,
                                        color: Color(0xFFFF8F00),
                                        size: 64,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Bukti File Belum Diunggah',
                                        style: TextStyle(
                                          color: Color(0xFFFF8F00),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'JPG atau PNG max 10mb',
                                        style: TextStyle(
                                          color: Color(0xFFFFB300),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                PaymentProofPreview(
                                  paymentProof: _currentBill.payment!.paymentProof,
                                  token: widget.token,
                                  height: 220,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(height: 16),

                                // Outline state badge below receipt
                                if (statusText == 'Menunggu verifikasi')
                                  _buildOutlineBadge('Menunggu Verifikasi', const Color(0xFFFF9800))
                                else if (statusText == 'Lunas')
                                  _buildOutlineBadge('Berhasil Verifikasi', const Color(0xFF2EBD59))
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bottom Button for Belum bayar
                        if (statusText == 'Belum bayar')
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => _navigateToPay(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B4B85),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Bayar Sekarang',
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

  Widget _buildOutlineBadge(String text, Color color) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        border: Border.all(color: color.withOpacity(0.7), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Future<void> _navigateToPay() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BayarTagihanView(
          bill: _currentBill,
          token: widget.token,
        ),
      ),
    );

    if (result is BillModel) {
      setState(() {
        _currentBill = result;
      });
    }
  }
}
