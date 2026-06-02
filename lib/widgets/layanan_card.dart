import 'package:flutter/material.dart';
import '../models/layanan_model.dart';

class LayananCard extends StatelessWidget {
  final LayananModel layanan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LayananCard({
    super.key,
    required this.layanan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Determine image asset based on name
    final lowerName = layanan.name.toLowerCase();
    final bool isRuko =
        lowerName.contains('ruko') ||
        lowerName.contains('toko') ||
        lowerName.contains('kios');
    final String imageAsset = isRuko
        ? 'assets/Ruko-layanan.png'
        : 'assets/Rumah-layanan.png';

    // Helper to format price to Indonesian Rupiah currency format
    String formatPrice(int price) {
      final valueString = price.toString();
      final buffer = StringBuffer();
      int count = 0;
      for (int i = valueString.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(valueString[i]);
        count++;
      }
      return 'Rp ${buffer.toString().split('').reversed.join('')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF035191).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Asset
          Image.asset(
            imageAsset,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                isRuko ? Icons.storefront_outlined : Icons.home_outlined,
                size: 40,
                color: const Color(0xFF729AC4),
              );
            },
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layanan.name,
                  style: const TextStyle(
                    color: Color(0xFF036BA1),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Penggunaan Air',
                          style: TextStyle(
                            color: Color(0xFF729AC4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${layanan.minUsage}-${layanan.maxUsage}m³',
                          style: const TextStyle(
                            color: Color(0xFF033A82),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Color(0xFF033A82).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Biaya/m³',
                          style: TextStyle(
                            color: Color(0xFF729AC4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatPrice(layanan.price),
                          style: const TextStyle(
                            color: Color(0xFF033A82),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Image.asset(
                  'assets/additional_icons/edit.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDelete,
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
    );
  }
}