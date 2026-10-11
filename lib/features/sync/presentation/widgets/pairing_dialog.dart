import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef PairingSubmit = Future<void> Function(String pin);

class PairingDialog extends StatefulWidget {
  const PairingDialog({
    super.key,
    required this.localPin,
    required this.onSubmit,
    this.remoteDeviceName = '对端设备',
  });

  final String localPin;
  final String remoteDeviceName;
  final PairingSubmit onSubmit;

  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.length != 4 || int.tryParse(pin) == null || _submitting) {
      setState(() => _error = '请输入 4 位数字配对码');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(pin);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _copyPin() async {
    await Clipboard.setData(ClipboardData(text: widget.localPin));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配对码已复制')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('连接 ${widget.remoteDeviceName}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '本机配对码',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    widget.localPin,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              key: const Key('pairing-pin-input'),
              controller: _controller,
              autofocus: true,
              enabled: !_submitting,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => unawaited(_submit()),
              decoration: InputDecoration(
                labelText: '输入对端配对码',
                hintText: '0000',
                errorText: _error,
                suffixIcon: IconButton(
                  tooltip: '复制本机配对码',
                  onPressed: _copyPin,
                  icon: const Icon(Icons.copy_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : () => unawaited(_submit()),
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link_rounded),
          label: const Text('配对'),
        ),
      ],
    );
  }
}
