import 'package:flutter/material.dart';
import '../../models/user_session.dart';
import '../../models/pelanggan_model.dart';
import '../../models/layanan_model.dart';
import '../../models/bill_model.dart';
import '../../services/user_session_service.dart';
import '../../services/pelanggan_service.dart';
import '../../services/layanan_service.dart';
import '../../services/bill_service.dart';
import '../../widgets/navBar_widget.dart';
import 'rincianTagihan_view.dart';
import 'bayarTagihan_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  UserSession? _session;
  List<PelangganModel> _pelangganList = [];
  List<LayananModel> _layananList = [];
  List<BillModel> _billsList = [];
  bool _isLoading = true;
  String? _errorMessage;

  final PelangganService _pelangganService = PelangganService();
  final LayananService _layananService = LayananService();
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
        final isCustomer =
            session.role.toLowerCase() == 'customer' ||
            session.role.toLowerCase() == 'user';

        if (isCustomer) {
          final bills = await _billService.getMyBills(token: session.token);
          if (!mounted) return;
          setState(() {
            if (bills != null) _billsList = bills;
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          // Admin fetching all statistics in parallel
          final results = await Future.wait([
            _pelangganService.getPelanggan(token: session.token),
            _layananService.getLayanan(token: session.token),
            _billService.getBills(token: session.token),
          ]);

          final customers = results[0] as List<PelangganModel>?;
          final services = results[1] as List<LayananModel>?;
          final bills = results[2] as List<BillModel>?;

          if (!mounted) return;

          setState(() {
            if (customers != null) _pelangganList = customers;
            if (services != null) _layananList = services;
            if (bills != null) _billsList = bills;
            _isLoading = false;
            _errorMessage = null;
          });
        }
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

  Future<void> _refreshDashboard() async {
    if (_session == null || _session!.token.isEmpty) return;
    try {
      final isCustomer =
          _session!.role.toLowerCase() == 'customer' ||
          _session!.role.toLowerCase() == 'user';
      if (isCustomer) {
        final bills = await _billService.getMyBills(token: _session!.token);
        if (!mounted) return;
        setState(() {
          if (bills != null) _billsList = bills;
        });
      } else {
        final results = await Future.wait([
          _pelangganService.getPelanggan(token: _session!.token),
          _layananService.getLayanan(token: _session!.token),
          _billService.getBills(token: _session!.token),
        ]);

        final customers = results[0] as List<PelangganModel>?;
        final services = results[1] as List<LayananModel>?;
        final bills = results[2] as List<BillModel>?;

        if (!mounted) return;

        setState(() {
          if (customers != null) _pelangganList = customers;
          if (services != null) _layananList = services;
          if (bills != null) _billsList = bills;
        });
      }
    } catch (e) {
      // Background reload failed silently
    }
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

  String _getFriendlyTime(String createdAtStr) {
    try {
      final createdAt = DateTime.parse(createdAtStr);
      final difference = DateTime.now().difference(createdAt);
      if (difference.inDays > 0) {
        return '${difference.inDays}h yang lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}j yang lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m yang lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return '2j yang lalu';
    }
  }

  Widget _buildAmertaLogo({double height = 40}) {
    return Image.asset(
      'assets/Vector1.png',
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.opacity_rounded,
              color: Colors.white,
              size: height * 0.85,
            ),
            const SizedBox(width: 8),
            Text(
              'AMERTA',
              style: TextStyle(
                color: Colors.white,
                fontSize: height * 0.6,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeText(String name) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFFE8EEF5),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        children: [
          const TextSpan(text: 'Selamat Datang, '),
          TextSpan(
            text: name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for customer: get current month bill, or most recent unpaid
  BillModel? get _currentMonthBill {
    if (_billsList.isEmpty) return null;
    final now = DateTime.now();
    try {
      return _billsList.firstWhere(
        (b) => b.month == now.month && b.year == now.year,
        orElse: () => _billsList.firstWhere(
          (b) => !b.verifiedPayment,
          orElse: () => _billsList.first,
        ),
      );
    } catch (e) {
      return _billsList.first;
    }
  }

  // Get chart data points for the last 5 months
  List<Map<String, dynamic>> _getChartData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> chartPoints = [];

    // We want the last 5 months, e.g. for June: Feb, Mar, Apr, Mei, Jun
    for (int i = 4; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthVal = date.month;
      final yearVal = date.year;

      // Find bill for this month & year
      final bill = _billsList.firstWhere(
        (b) => b.month == monthVal && b.year == yearVal,
        orElse: () => BillModel(
          id: 0,
          customerId: 0,
          adminId: 0,
          month: monthVal,
          year: yearVal,
          measurementNumber: '',
          usageValue: 0,
          price: 0,
          serviceId: 0,
          paid: false,
          ownerToken: '',
          createdAt: '',
          updatedAt: '',
          amount: 0,
          verifiedPayment: false,
        ),
      );

      const shortMonths = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      chartPoints.add({
        'label': shortMonths[monthVal - 1],
        'amount': bill.amount.toDouble(),
      });
    }

    return chartPoints;
  }

  @override
  Widget build(BuildContext context) {
    final role = _session?.role.toLowerCase() ?? 'admin';

    if (_isLoading) {
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
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }

    if (role == 'customer' || role == 'user') {
      return _buildCustomerDashboard();
    } else {
      return _buildAdminDashboard();
    }
  }

  // ─── Customer Dashboard Layout (Mockup accurate) ────────────────────
  Widget _buildCustomerDashboard() {
    final name = _session?.name ?? 'Customer';

    final currentBill = _currentMonthBill;
    final String monthName = currentBill != null
        ? _getMonthName(currentBill.month)
        : _getMonthName(DateTime.now().month);
    final formattedPrice = currentBill != null
        ? 'Rp ${currentBill.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'
        : 'Rp 0';

    final bool isPaid = currentBill?.verifiedPayment ?? true;
    final bool hasReceipt = currentBill?.payment != null;

    String currentBillStatus = 'Sudah Lunas';
    Color statusColor = const Color(0xFF2EBD59);

    if (!isPaid) {
      if (hasReceipt) {
        currentBillStatus = 'Menunggu Verifikasi';
        statusColor = const Color(0xFFFF9800);
      } else {
        currentBillStatus = 'Belum Dibayar';
        statusColor = const Color(0xFFFF8F00);
      }
    }

    final unpaidCount = _billsList.where((b) => !b.verifiedPayment).length;
    final paidCount = _billsList.where((b) => b.verifiedPayment).length;

    final chartPoints = _getChartData();
    final List<double> chartValues = chartPoints
        .map((pt) => pt['amount'] as double)
        .toList();
    final List<String> chartLabels = chartPoints
        .map((pt) => pt['label'] as String)
        .toList();

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAmertaLogo(),
                        const SizedBox(height: 16),
                        _buildWelcomeText(name),
                      ],
                    ),
                    Image.asset(
                      'assets/additional_icons/Bell.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Main Dashboard Body
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _refreshDashboard,
                    color: const Color(0xFF0B4B85),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card 1: Tagihan Bulan Ini
                          _buildCurrentMonthBillCard(
                            monthName: monthName,
                            priceText: formattedPrice,
                            statusText: currentBillStatus,
                            statusColor: statusColor,
                            bill: currentBill,
                          ),
                          const SizedBox(height: 16),

                          // Row 2: stats boxes
                          Row(
                            children: [
                              Expanded(
                                child: _buildCustomerStatCard(
                                  title: 'Belum Dibayar',
                                  count: unpaidCount,
                                  isRed: true,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildCustomerStatCard(
                                  title: 'Sudah Lunas',
                                  count: paidCount,
                                  isRed: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Row 3: Grafik Tagihan Card
                          _buildChartCard(chartValues, chartLabels),
                        ],
                      ),
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
        currentIndex: 0,
      ),
    );
  }

  Widget _buildCurrentMonthBillCard({
    required String monthName,
    required String priceText,
    required String statusText,
    required Color statusColor,
    required BillModel? bill,
  }) {
    final bool canPay =
        bill != null && !bill.verifiedPayment && bill.payment == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC2D4E6).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A8FD4).withOpacity(0.5),
          width: 1.5,
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
          // Row: Title and Month
          Row(
            children: [
              const Text(
                'Tagihan Bulan Ini',
                style: TextStyle(
                  color: Color(0xFF035191),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '•',
                style: TextStyle(
                  color: Color(0xFF729AC4),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                monthName,
                style: const TextStyle(
                  color: Color(0xFF729AC4),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row: Amount and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                priceText,
                style: const TextStyle(
                  color: Color(0xFF031B46),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF0B4B85)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (bill == null) return;
                  if (canPay) {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BayarTagihanView(
                          bill: bill,
                          token: _session!.token,
                        ),
                      ),
                    );
                    if (updated != null) {
                      _refreshDashboard();
                    }
                  } else {
                    // Navigate to detail page
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RincianTagihanView(
                          bill: bill,
                          token: _session!.token,
                        ),
                      ),
                    );
                    if (updated != null) {
                      _refreshDashboard();
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
                child: Text(
                  canPay ? 'Bayar Sekarang' : 'Lihat Detail',
                  style: const TextStyle(
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

  Widget _buildCustomerStatCard({
    required String title,
    required int count,
    required bool isRed,
  }) {
    final Color themeColor = isRed
        ? const Color(0xFFFF8F00)
        : const Color(0xFF2EBD59);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFC2D4E6).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A8FD4).withOpacity(0.5),
          width: 1.5,
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF035191),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isRed) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Lebih dari sebulan',
                  style: TextStyle(
                    color: Color(0xFFFF8F00),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF8F00),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else ...[
            const SizedBox(height: 29),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                isRed
                    ? 'assets/additional_icons/belumDibayar.png'
                    : 'assets/additional_icons/sudahLunas.png',
                width: 40,
                height: 40,
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: themeColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<double> values, List<String> labels) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC2D4E6).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A8FD4).withOpacity(0.5),
          width: 1.5,
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
          // Header: Grafik Tagihan • 5 bulan terakhir
          Row(
            children: [
              const Text(
                'Grafik Tagihan',
                style: TextStyle(
                  color: Color(0xFF035191),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '•',
                style: TextStyle(
                  color: Color(0xFF729AC4),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '5 bulan terakhir',
                  style: TextStyle(
                    color: Color(0xFF2EBD59),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart CustomPainter
          SizedBox(
            width: double.infinity,
            height: 180,
            child: CustomPaint(
              painter: ChartPainter(values: values, labels: labels),
            ),
          ),
          const SizedBox(height: 16),

          // Labels Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((label) {
              return SizedBox(
                width: 48,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF035191),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Admin Dashboard Layout (Legacy verified intact) ──────────────────
  Widget _buildAdminDashboard() {
    final name = _session?.name ?? 'User Admin';
    final totalPelanggan = _pelangganList.length;
    final jumlahLayanan = _layananList.length;
    final pendingBills = _billsList.where((b) => !b.verifiedPayment).length;
    final totalTagihan = _billsList.length;

    final sortedBills = List<BillModel>.from(_billsList)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentBills = sortedBills.take(3).toList();

    // Calculate Pendapatan
    final now = DateTime.now();
    double totalPendapatan = 0;
    double pendapatanBulanIni = 0;
    for (var bill in _billsList.where((b) => b.verifiedPayment)) {
      if (bill.month == now.month && bill.year == now.year) {
        pendapatanBulanIni += bill.amount;
      }
      final billDate = DateTime(bill.year, bill.month, 1);
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      if (!billDate.isBefore(sixMonthsAgo)) {
        totalPendapatan += bill.amount;
      }
    }
    
    final formattedTotalPendapatan = 'Rp ${totalPendapatan.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    final formattedPendapatanBulanIni = 'Rp ${pendapatanBulanIni.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

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
          child: RefreshIndicator(
            onRefresh: _refreshDashboard,
            color: const Color(0xFF0B4B85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAmertaLogo(),
                          const SizedBox(height: 16),
                          _buildWelcomeText(name),
                        ],
                      ),
                      Image.asset(
                        'assets/additional_icons/Bell.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Main Dashboard Body Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTotalPelangganCard(totalPelanggan),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: _buildJumlahLayananCard(jumlahLayanan),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: _buildTertundaCard(pendingBills)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _buildKelolaTagihanCard(totalTagihan),
                          const SizedBox(height: 14),
                          
                          _buildPendapatanCard(formattedTotalPendapatan, formattedPendapatanBulanIni),
                          const SizedBox(height: 28),

                          const Text(
                            'Aktivitas Terakhir',
                            style: TextStyle(
                              color: Color(0xFF033A82),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (recentBills.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              alignment: Alignment.center,
                              child: const Text(
                                'Tidak ada aktivitas terbaru',
                                style: TextStyle(
                                  color: Color(0xFF729AC4),
                                  fontSize: 14,
                                ),
                              ),
                            )
                          else
                            ...recentBills.map(
                              (bill) => _buildActivityItem(bill),
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
      ),
      bottomNavigationBar: CustomBottomNavBar(
        role: _session?.role.toLowerCase() ?? 'admin',
        currentIndex: 0,
      ),
    );
  }

  Widget _buildTotalPelangganCard(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFC2D4E6).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A8FD4).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: Color(0xFF035191),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Pelanggan',
                style: TextStyle(
                  color: Color(0xFF035191),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Image.asset(
                'assets/additional_icons/totalPelanggan.png',
                width: 38,
                height: 38,
              ),
              const SizedBox(width: 16),
              Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFF031B46),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJumlahLayananCard(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFC2D4E6).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A8FD4).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jumlah Layanan',
            style: TextStyle(
              color: Color(0xFF035191),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/additional_icons/jLayanan.png',
                width: 40,
                height: 40,
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFF031B46),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTertundaCard(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFC2D4E6).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A8FD4).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tertunda',
            style: TextStyle(
              color: Color(0xFF035191),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Butuh verifikasi •',
            style: TextStyle(
              color: Color(0xFFFF8F00),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/additional_icons/tertunda.png',
                width: 40,
                height: 40,
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFF031B46),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKelolaTagihanCard(int count) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF99F800).withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB72121).withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/kelolaTagihan'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola',
                      style: TextStyle(
                        color: Color(0xFFFF8F00),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tagihan',
                      style: TextStyle(
                        color: Color(0xFFFF8F00),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Image.asset(
                      'assets/additional_icons/kTagihan.png',
                      width: 34,
                      height: 34,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: Color(0xFF031B46),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendapatanCard(String total, String bulanIni) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC2D4E6).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A8FD4).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Pendapatan 6 Bulan Terakhir',
            style: TextStyle(
              color: Color(0xFF035191),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Image.asset(
                'assets/additional_icons/pendapatan6.png',
                width: 44,
                height: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  total,
                  style: const TextStyle(
                    color: Color(0xFF033A82),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Bulan Ini',
                style: TextStyle(
                  color: Color(0xFF035191),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '•',
                style: TextStyle(
                  color: Color(0xFF035191),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                bulanIni,
                style: const TextStyle(
                  color: Color(0xFF2EBD59),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BillModel bill) {
    final customerName = bill.customer?.name ?? 'Customer';
    final billId = 123000 + bill.id;
    final friendlyTime = _getFriendlyTime(bill.createdAt);
    final isVerified = bill.verifiedPayment;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A8FD4).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE8EEF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF729AC4), size: 28),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#T-$billId   •   $friendlyTime',
                  style: const TextStyle(
                    color: Color(0xFF729AC4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                          colors: isVerified
                              ? [
                                Color(0xFF00D270), 
                                Color(0xFF0D8C42)]
                              : [
                                Color(0xFFF86700),
                                Color(0xFFA18000),
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isVerified ? 'Berhasil' : 'Tertunda',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ChartPainter ────────────────────────────────────────────────────
class ChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  ChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF035191).withOpacity(0.06)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines (5 lines)
    final double gridSpacing = size.height / 4;
    for (int i = 0; i < 5; i++) {
      final double y = i * gridSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;

    // Find min and max values to scale
    double maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    if (maxVal == 0) maxVal = 100000.0; // Default scale if all zero

    // Calculate points coordinates
    final double xSpacing = size.width / (values.length - 1);
    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = i * xSpacing;
      // Invert Y because canvas origin (0,0) is top-left
      final double ratio = values[i] / maxVal;
      // Leave 10% padding top and bottom
      final double y = size.height * 0.9 - (ratio * size.height * 0.8);
      points.add(Offset(x, y));
    }

    // Draw area path (gradient fill)
    final Path areaPath = Path();
    areaPath.moveTo(points.first.dx, size.height);
    for (var pt in points) {
      areaPath.lineTo(pt.dx, pt.dy);
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF729AC4).withOpacity(0.4),
          const Color(0xFF729AC4).withOpacity(0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, fillPaint);

    // Draw the boundary line (thick blue line)
    final linePaint = Paint()
      ..color = const Color(0xFF4A90E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final Path linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots at points
    final dotPaint = Paint()
      ..color = const Color(0xFF0B4B85)
      ..style = PaintingStyle.fill;
    final dotOutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var pt in points) {
      canvas.drawCircle(pt, 5.0, dotPaint);
      canvas.drawCircle(pt, 5.0, dotOutlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}
