import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/url.dart';

/// Loads payment proof via `GET {baseURL}/payment-proof/{fileName}` with auth headers.
class PaymentProofPreview extends StatefulWidget {
  final String paymentProof;
  final String? token;
  final double height;
  final BoxFit fit;

  const PaymentProofPreview({
    super.key,
    required this.paymentProof,
    this.token,
    this.height = 280,
    this.fit = BoxFit.contain,
  });

  /// Extracts the file name from API value (plain name, path, or full URL).
  static String extractFileName(String proof) {
    final trimmed = proof.trim();
    if (trimmed.isEmpty) return '';

    var value = trimmed.split('?').first;

    final lower = value.toLowerCase();
    const marker = '/payment-proof/';
    final markerIndex = lower.indexOf(marker);
    if (markerIndex >= 0) {
      value = value.substring(markerIndex + marker.length);
    }

    return value.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty).last;
  }

  static String resolveUrl(String proof) {
    final trimmed = proof.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed.split('?').first;
    }

    final fileName = extractFileName(trimmed);
    if (fileName.isEmpty) return '';

    final base = baseURL.endsWith('/')
        ? baseURL.substring(0, baseURL.length - 1)
        : baseURL;
    return '$base/payment-proof/$fileName';
  }

  @override
  State<PaymentProofPreview> createState() => _PaymentProofPreviewState();
}

class _PaymentProofPreviewState extends State<PaymentProofPreview> {
  Uint8List? _bytes;
  bool _isLoading = true;
  bool _isPdf = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProof();
  }

  @override
  void didUpdateWidget(PaymentProofPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paymentProof != widget.paymentProof ||
        oldWidget.token != widget.token) {
      _loadProof();
    }
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'APP-KEY': appKey};
    if (widget.token != null && widget.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${widget.token}';
    }
    return headers;
  }

  bool _looksLikePdf(Uint8List bytes, String proof) {
    final lower = proof.toLowerCase();
    if (lower.endsWith('.pdf') || lower.contains('.pdf?')) return true;
    return bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46; // %PDF
  }

  Future<void> _loadProof() async {
    final proof = widget.paymentProof.trim();
    if (proof.isEmpty) {
      setState(() {
        _isLoading = false;
        _bytes = null;
        _errorMessage = 'Bukti pembayaran tidak tersedia';
      });
      return;
    }

    final url = PaymentProofPreview.resolveUrl(proof);
    if (url.isEmpty) {
      setState(() {
        _isLoading = false;
        _bytes = null;
        _errorMessage = 'Bukti pembayaran tidak tersedia';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _bytes = null;
    });

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final bytes = response.bodyBytes;
        if (!mounted) return;
        setState(() {
          _bytes = bytes;
          _isPdf = _looksLikePdf(bytes, proof);
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }
    } catch (_) {
      // fall through to error state
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _bytes = null;
      _errorMessage = 'Gagal memuat bukti pembayaran';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _frame(
        child: SizedBox(
          height: widget.height,
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF0B4B85)),
          ),
        ),
      );
    }

    if (_errorMessage != null || _bytes == null) {
      return _frame(
        child: SizedBox(
          height: widget.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                color: Color(0xFF729AC4),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Gagal memuat bukti pembayaran',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF729AC4), fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadProof,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0B4B85),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isPdf) {
      return _frame(
        child: SizedBox(
          height: widget.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFF8B1A1A),
                size: 64,
              ),
              const SizedBox(height: 12),
              const Text(
                'Bukti Pembayaran (PDF)',
                style: TextStyle(
                  color: Color(0xFF033A82),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                PaymentProofPreview.extractFileName(widget.paymentProof),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF729AC4), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return _frame(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _bytes!,
          height: widget.height,
          width: double.infinity,
          fit: widget.fit,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  Widget _frame({required Widget child}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: widget.height),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF729AC4).withOpacity(0.3),
        ),
      ),
      child: child,
    );
  }
}
