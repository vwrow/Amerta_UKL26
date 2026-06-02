import 'package:flutter/material.dart';
import '../models/pelanggan_model.dart';

class PelangganCard extends StatelessWidget {
  final PelangganModel pelanggan;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PelangganCard({
    super.key,
    required this.pelanggan,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {

    // Get service name from nested service object, or fallback
    final serviceName =
        pelanggan.service?.name ?? 'Layanan ID: ${pelanggan.serviceId}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF035191).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Profile Image
          ClipOval(child: const Icon(Icons.person, size: 30,color: Color(0xFF729AC4))),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pelanggan.name,
                  style: const TextStyle(
                    color: Color(0xFF033A82),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      pelanggan.customerNumber,
                      style: const TextStyle(
                        color: Color(0xFF729AC4),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF033A82).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        serviceName,
                        style: const TextStyle(
                          color: Color(0xFF729AC4),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  pelanggan.address,
                  style: const TextStyle(
                    color: Color(0xFF729AC4),
                    fontSize: 12,
                  ),
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
              const SizedBox(width: 14),
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
