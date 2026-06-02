import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    if (monthNum >= 1 && monthNum <= 12) {
      return months[monthNum - 1];
    }
    return 'Juni';
  }

  String _formatPaymentDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _navigateToPay() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BayarTagihanView(bill: _currentBill, token: widget.token),
      ),
    );

    if (result is BillModel) {
      setState(() {
        _currentBill = result;
      });
    }
  }

  // --- PDF GENERATION LOGIC ---
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final customer = _currentBill.customer;
    
    final formattedPrice = 'Rp ${_currentBill.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Rincian Tagihan - AMERTA', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              
              pw.Text('Data Pelanggan', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Nama:'), pw.Text(customer?.name ?? 'Sonthony Mackie')]),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Layanan:'), pw.Text(_currentBill.service?.name ?? 'Rumah A')]),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('No Pelanggan:'), pw.Text(customer?.customerNumber ?? 'C-33')]),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Alamat:'), pw.Text(customer?.address ?? 'Jl. Danau Poso 1 G2E16')]),
              
              pw.SizedBox(height: 30),
              
              pw.Text('Detail Pembayaran', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Periode:'), pw.Text('${_getMonthName(_currentBill.month)} ${_currentBill.year}')]),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('No meteran:'), pw.Text(_currentBill.measurementNumber)]),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Penggunaan:'), pw.Text('${_currentBill.usageValue} m3')]),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Status:'), pw.Text(_currentBill.verifiedPayment ? 'Lunas' : 'Belum Lunas')]),
              
              pw.SizedBox(height: 20),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: PdfColors.blue100,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(formattedPrice, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
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
    final formattedPrice =
        'Rp ${_currentBill.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

    // Verification states
    final isVerified = _currentBill.verifiedPayment;
    final hasReceipt = _currentBill.payment != null;

    String statusText = 'Belum bayar';
    Color statusColor = const Color(0xFF8B1A1A); // Red/brown

    bool isDenied = false;
    if (_currentBill.payment != null && !isVerified) {
      if (_currentBill.payment!.paymentProof == 'rejected' ||
          _currentBill.payment!.totalAmount == 99) {
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
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.notifications, color: Colors.white),
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF035191).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data Pelanggan',
                                style: TextStyle(
                                  color: Color(0xFF033A82),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildDetailRow('Nama', customerName),
                              const Divider(height: 20, color: Color(0xFFE8EEF5)),
                              _buildDetailRow('Layanan', serviceName),
                              const Divider(height: 20, color: Color(0xFFE8EEF5)),
                              _buildDetailRow('No Pelanggan', customerNum),
                              const Divider(height: 20, color: Color(0xFFE8EEF5)),
                              _buildDetailRowMultiline('Alamat', customerAddress),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card 2: Detail Pembayaran Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF035191).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detail Pembayaran Tagihan',
                                style: TextStyle(
                                  color: Color(0xFF033A82),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildDetailRow(
                                'Periode',
                                '${_getMonthName(_currentBill.month)} ${_currentBill.year}',
                              ),
                              const Divider(height: 20, color: Color(0xFFE8EEF5)),
                              _buildDetailRow('No meteran', _currentBill.measurementNumber),
                              const Divider(height: 20, color: Color(0xFFE8EEF5)),
                              _buildDetailRow('Total Penggunaan', '${_currentBill.usageValue} m³'),
                              
                              if (hasReceipt && _currentBill.payment != null) ...[
                                const Divider(height: 20, color: Color(0xFFE8EEF5)),
                                _buildDetailRow(
                                  'Tanggal Pembayaran',
                                  _formatPaymentDate(_currentBill.payment!.paymentDate),
                                ),
                              ],
                              
                              const Divider(height: 20, color: Color(0xFFE8EEF5)),
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
                        if (statusText != 'Lunas')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF035191).withOpacity(0.3),
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

                                if (statusText == 'Belum bayar')
                                  Container(
                                    width: double.infinity,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F9F9),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFFFB300).withOpacity(0.5),
                                        width: 2,
                                        style: BorderStyle.solid, 
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
                                ],
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // --- ACTIONS FOR 'LUNAS' ---
                        if (statusText == 'Lunas') ...[
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5A8FD4), Color(0xFF033A82)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                // Triggers Print / Save as PDF
                                await Printing.layoutPdf(
                                  onLayout: (PdfPageFormat format) async => await _generatePdf(format),
                                  name: 'Tagihan_${_currentBill.customer?.name ?? "Pelanggan"}_${_currentBill.month}.pdf',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Cetak PDF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                // Triggers Share menu (WhatsApp, Email, etc.)
                                final pdfBytes = await _generatePdf(PdfPageFormat.a4);
                                await Printing.sharePdf(
                                  bytes: pdfBytes,
                                  filename: 'Tagihan_${_currentBill.customer?.name ?? "Pelanggan"}.pdf',
                                );
                              },
                              icon: Image.asset(
                                'assets/additional_icons/share.png',
                                width: 24,
                                height: 24,
                                color: const Color(0xFF033A82),
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.share, color: Color(0xFF033A82)),
                              ),
                              label: const Text(
                                'Bagikan',
                                style: TextStyle(
                                  color: Color(0xFF033A82),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF035191),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],

                        // --- ACTIONS FOR 'BELUM BAYAR' ---
                        if (statusText == 'Belum bayar')
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5A8FD4), Color(0xFF036BA1)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _navigateToPay(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
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
          style: const TextStyle(color: Color(0xFF729AC4), fontSize: 14),
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

  Widget _buildDetailRowMultiline(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF729AC4), fontSize: 14),
        ),
        const SizedBox(width: 32),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF033A82),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}