import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef PairingScannerViewBuilder = Widget Function(
  ValueChanged<String> onPayloadScanned,
);

class MobilePairingScannerPage extends StatelessWidget {
  const MobilePairingScannerPage({
    required this.onPairingPayloadScanned,
    required this.onCancel,
    this.cameraViewBuilder,
    super.key,
  });

  final ValueChanged<String> onPairingPayloadScanned;
  final VoidCallback onCancel;
  final PairingScannerViewBuilder? cameraViewBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: cameraViewBuilder?.call(onPairingPayloadScanned) ??
                _MobileScannerView(onPayloadScanned: onPairingPayloadScanned),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: '取消扫码',
                        onPressed: onCancel,
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.45),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '扫描配对二维码',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '/remote-control-pair',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.76),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileScannerView extends StatefulWidget {
  const _MobileScannerView({required this.onPayloadScanned});

  final ValueChanged<String> onPayloadScanned;

  @override
  State<_MobileScannerView> createState() => _MobileScannerViewState();
}

class _MobileScannerViewState extends State<_MobileScannerView> {
  var _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        if (_hasScanned) return;
        for (final barcode in capture.barcodes) {
          final rawValue = barcode.rawValue?.trim();
          if (rawValue == null || rawValue.isEmpty) continue;
          _hasScanned = true;
          widget.onPayloadScanned(rawValue);
          return;
        }
      },
    );
  }
}
