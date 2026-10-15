import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/design_system/app_colors.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  Map<String, dynamic>? _lastScannedStudent;
  String? _scanMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _scanMessage = 'Memvalidasi Kartu Pelajar...';
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post(
        ApiEndpoints.attendanceScans,
        data: {
          'card_token': code,
          'idempotency_key': 'scan_${DateTime.now().millisecondsSinceEpoch}_$code',
        },
      );

      final data = response.data['data'];
      setState(() {
        _isSuccess = true;
        _lastScannedStudent = data['student'];
        _scanMessage = response.data['message'] ?? 'Absensi berhasil dicatat.';
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _scanMessage = 'Kartu tidak valid, tidak terdaftar, atau sudah tercatat hadir.';
      });
    } finally {
      // Cooldown before scanning next card
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai Kartu Pelajar'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // Overlay guidance
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing
                      ? (_isSuccess ? AppColors.statusPresent : AppColors.statusAbsent)
                      : Colors.white.withOpacity(0.8),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Bottom card feedback
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scanMessage != null) ...[
                    Row(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.error_outline,
                          color: _isSuccess ? AppColors.statusPresent : AppColors.statusAbsent,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _scanMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isSuccess ? AppColors.statusPresent : AppColors.statusAbsent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_lastScannedStudent != null) ...[
                      const Divider(height: 16),
                      Text(
                        _lastScannedStudent!['name'] ?? '',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'NIS: ${_lastScannedStudent!['admission_no'] ?? '-'} · Kelas: ${_lastScannedStudent!['class_name'] ?? '-'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ] else ...[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Arahkan kamera ke QR Kartu Pelajar',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
