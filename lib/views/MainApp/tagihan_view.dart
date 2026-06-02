import 'package:flutter/material.dart';
import '../../models/user_session.dart';
import '../../models/bill_model.dart';
import '../../services/user_session_service.dart';
import '../../services/bill_service.dart';
import '../../widgets/navBar_widget.dart';
import 'rincianTagihan_view.dart';
import 'bayarTagihan_view.dart';

class TagihanView extends StatefulWidget {
  const TagihanView({super.key});

  @override
  State<TagihanView> createState() => _TagihanViewState();
}

class _TagihanViewState extends State<TagihanView> {
  UserSession? _session;
  List<BillModel> _billsList = [];
  bool _isLoading = true;
  String? _errorMessage;

  final BillService _billService = BillService();

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
        final data = await _billService.getMyBills(token: session.token);
        if (!mounted) return;

        setState(() {
          if (data != null) {
            _billsList = data;
            // Sort by month and year descending
            _billsList.sort((a, b) {
              final compareYear = b.year.compareTo(a.year);
              if (compareYear != 0) return compareYear;
              return b.month.compareTo(a.month);
            });
            _errorMessage = null;
          } else {
            _errorMessage = 'Gagal memuat data tagihan';
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

  Future<void> _refreshBills() async {
    if (_session == null || _session!.token.isEmpty) return;
    final data = await _billService.getMyBills(token: _session!.token);
    if (!mounted) return;
    setState(() {
      if (data != null) {
        _billsList = data;
        _billsList.sort((a, b) {
          final compareYear = b.year.compareTo(a.year);
          if (compareYear != 0) return compareYear;
          return b.month.compareTo(a.month);
        });
        _errorMessage = null;
      }
    });
  }

  String _getMonthName(int monthNum) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    if (monthNum >= 1 && monthNum <= 12) {
      return months[monthNum - 1];
    }
    return 'Juni';
  }

  Future<void> _navigateToDetails(BillModel bill) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RincianTagihanView(bill: bill, token: _session!.token),
      ),
    );
    if (updated is BillModel) {
      _refreshBills();
    }
  }

  Future<void> _navigateToPay(BillModel bill) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BayarTagihanView(bill: bill, token: _session!.token),
      ),
    );
    if (updated is BillModel) {
      _refreshBills();
    }
  }

  // ─── Build Card Items ────────────────────────────────────────────
  Widget _buildBillItem(BillModel bill) {
    final monthName = _getMonthName(bill.month);
    final usage = bill.usageValue;
    final formattedPrice =
        'Rp ${bill.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

    // Status logic
    final isVerified = bill.verifiedPayment;
    final hasReceipt = bill.payment != null;

    String statusText = 'Belum dibayar';
    Color themeColor = const Color(0xFF8B1A1A); // Red/brown
    Color softBgColor = const Color(0xFFFFEBEE);

    if (isVerified) {
      statusText = 'Sudah Lunas';
      themeColor = const Color(0xFF2EBD59); // Green
      softBgColor = const Color(0xFFE8F5E9);
    } else if (hasReceipt) {
      statusText = 'Menunggu verifikasi';
      themeColor = const Color(0xFFFF9800); // Orange
      softBgColor = const Color(0xFFFFF3E0);
    }

    final isUnpaid = !isVerified && !hasReceipt;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF035191).withOpacity(0.3),
              width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B4B85).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Period and Price Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName ${bill.year}',
                style: const TextStyle(
                  color: Color(0xFF033A82),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: softBgColor,
                  border: Border.all(
                    color: themeColor.withOpacity(0.4),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  formattedPrice,
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: usage and status description
          Row(
            children: [
              Text(
                '$usage m³',
                style: const TextStyle(
                  color: Color(0xFF729AC4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Action Buttons
          if (isUnpaid)
            Row(
              children: [
                // Lihat detail
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => _navigateToDetails(bill),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF0B4B85),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Lihat detail',
                        style: TextStyle(
                          color: Color(0xFF0B4B85),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Bayar sekarang
                Expanded(
                  flex: 6,
                  child: SizedBox(
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF5A8FD4), Color(0xFF036BA1)],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () => _navigateToPay(bill),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors
                              .transparent, // Makes the button transparent
                          shadowColor: Colors.transparent, // Removes the shadow
                          elevation: 0, // Flattens the button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Matches container radius
                          ),
                        ),
                        child: const Text(
                          'Bayar Sekarang',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Just Lihat detail covering full width
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () => _navigateToDetails(bill),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0B4B85), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Lihat detail',
                  style: TextStyle(
                    color: Color(0xFF0B4B85),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
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
                    const Text(
                      'Tagihan',
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

              // White Content Card Grid
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
                      : _billsList.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada data tagihan',
                            style: TextStyle(
                              color: Color(0xFF031B46),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshBills,
                          color: const Color(0xFF0B4B85),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                            itemCount: _billsList.length,
                            itemBuilder: (context, index) {
                              final bill = _billsList[index];
                              return _buildBillItem(bill);
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        role: _session?.role.toLowerCase() ?? 'user',
        currentIndex: 1,
      ),
    );
  }
}
