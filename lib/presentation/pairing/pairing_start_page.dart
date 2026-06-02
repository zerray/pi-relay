import 'package:flutter/material.dart';

import 'mobile_pairing_scanner_page.dart';

class PairingStartPage extends StatefulWidget {
  const PairingStartPage({
    required this.onPairingPayloadSubmitted,
    this.scannerBuilder,
    super.key,
  });

  final Future<void> Function(String pairingPayload) onPairingPayloadSubmitted;
  final PairingScannerViewBuilder? scannerBuilder;

  @override
  State<PairingStartPage> createState() => _PairingStartPageState();
}

class _PairingStartPageState extends State<PairingStartPage> {
  bool _isPairing = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = switch (theme.platform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows =>
        false,
    };
    final buttonLabel = isMobile ? '扫码配对' : '输入配对字符串';
    final buttonIcon = isMobile ? Icons.qr_code_scanner : Icons.link;
    final errorText = _errorText;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.hub_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pi Relay',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '连接到 Pi Remote Control',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '配对后即可远程查看和控制已共享的 Pi 会话。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    key: const Key('pairing-action-button'),
                    onPressed: _isPairing
                        ? null
                        : () => isMobile
                            ? _handleScanButtonPressed(context)
                            : _handlePairButtonPressed(context),
                    icon: _isPairing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(buttonIcon),
                    label: Text(_isPairing ? '配对中…' : buttonLabel),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorText,
                      key: const Key('pairing-error-text'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleScanButtonPressed(BuildContext context) async {
    final scannerBuilder = widget.scannerBuilder ??
        (onScanned) => MobilePairingScannerPage(
              onPairingPayloadScanned: onScanned,
              onCancel: () => Navigator.of(context).pop(),
            );
    final payload = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (routeContext) => scannerBuilder(
          (payload) => Navigator.of(routeContext).pop(payload),
        ),
      ),
    );
    await _submitPairingPayload(payload);
  }

  Future<void> _handlePairButtonPressed(BuildContext context) async {
    final payload = await showDialog<String>(
      context: context,
      builder: (context) => const _PairingPayloadDialog(),
    );
    await _submitPairingPayload(payload);
  }

  Future<void> _submitPairingPayload(String? payload) async {
    if (payload == null || payload.trim().isEmpty) return;

    setState(() {
      _isPairing = true;
      _errorText = null;
    });

    try {
      await widget.onPairingPayloadSubmitted(payload.trim());
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _isPairing = false;
        _errorText = error.toString();
      });
    }
  }
}

class _PairingPayloadDialog extends StatefulWidget {
  const _PairingPayloadDialog();

  @override
  State<_PairingPayloadDialog> createState() => _PairingPayloadDialogState();
}

class _PairingPayloadDialogState extends State<_PairingPayloadDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('输入配对字符串'),
      content: TextField(
        key: const Key('pairing-payload-field'),
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '配对字符串',
          helperText: '粘贴 /remote-control-pair 显示的 hex payload',
        ),
        minLines: 1,
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('配对'),
        ),
      ],
    );
  }
}
