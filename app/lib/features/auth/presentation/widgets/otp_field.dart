import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// One-time code input (T1.5.03): a single field so paste, SMS/e-mail autofill
/// (`oneTimeCode`) and screen readers work natively; Arabic-Indic digits are accepted and
/// [onCompleted] fires as soon as [length] digits are present (auto-advance).
class OtpField extends StatefulWidget {
  const OtpField({
    required this.onCompleted,
    super.key,
    this.length = 6,
    this.enabled = true,
    this.label,
    this.errorText,
    this.controller,
    this.autofocus = true,
  });

  final ValueChanged<String> onCompleted;
  final int length;
  final bool enabled;
  final String? label;
  final String? errorText;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  String _lastCompleted = '';

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final digits = normalizeOtp(raw, length: widget.length);
    if (digits != raw) {
      _controller.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    if (digits.length == widget.length && digits != _lastCompleted) {
      _lastCompleted = digits;
      widget.onCompleted(digits);
    } else if (digits.length < widget.length) {
      _lastCompleted = '';
    }
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    enabled: widget.enabled,
    autofocus: widget.autofocus,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
    autofillHints: const [AutofillHints.oneTimeCode],
    textAlign: TextAlign.center,
    // Codes are always read left-to-right, even in Arabic.
    textDirection: TextDirection.ltr,
    maxLength: widget.length * 2,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩۰-۹ -]'))],
    style: context.text.headlineMedium?.copyWith(letterSpacing: 12, fontFeatures: const [FontFeature.tabularFigures()]),
    decoration: InputDecoration(labelText: widget.label, counterText: '', errorText: widget.errorText),
    onChanged: _onChanged,
    onSubmitted: (v) {
      final digits = normalizeOtp(v, length: widget.length);
      if (digits.length == widget.length) widget.onCompleted(digits);
    },
  );
}
