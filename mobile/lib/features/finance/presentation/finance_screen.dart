import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/app_colors.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan & SPP'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total Outstanding / Summary Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Tagihan Bulan Ini',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  currencyFormat.format(350000),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 14, color: AppColors.statusPending),
                      SizedBox(width: 4),
                      Text(
                        'Jatuh Tempo: 20 Oktober 2026',
                        style: TextStyle(
                          color: AppColors.statusPending,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Riwayat Tagihan & Pembayaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _InvoiceCard(
            invoiceNo: 'INV/2026/10/0042',
            period: 'Oktober 2026',
            amount: currencyFormat.format(350000),
            status: 'Belum Lunas',
            statusColor: AppColors.statusPending,
            onTap: () {},
          ),
          const SizedBox(height: 12),

          _InvoiceCard(
            invoiceNo: 'INV/2026/09/0115',
            period: 'September 2026',
            amount: currencyFormat.format(350000),
            status: 'Lunas',
            statusColor: AppColors.statusPaid,
            paidAt: '08 Sep 2026',
            onTap: () {},
          ),
          const SizedBox(height: 12),

          _InvoiceCard(
            invoiceNo: 'INV/2026/08/0091',
            period: 'Agustus 2026',
            amount: currencyFormat.format(350000),
            status: 'Lunas',
            statusColor: AppColors.statusPaid,
            paidAt: '05 Agu 2026',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final String invoiceNo;
  final String period;
  final String amount;
  final String status;
  final Color statusColor;
  final String? paidAt;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoiceNo,
    required this.period,
    required this.amount,
    required this.status,
    required this.statusColor,
    this.paidAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoiceNo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'SPP Periode $period',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (paidAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Dibayar pada: $paidAt',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
