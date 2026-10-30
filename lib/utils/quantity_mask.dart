import 'dart:math';

import 'package:flutter/services.dart';

class QuantityMask {
  const QuantityMask._();

  static int shiftFor(String unit) {
    final u = unit.trim().toLowerCase();
    switch (u) {
      case 'un':
      case 'pct':
        return 1;
      case 'g':
      case 'ml':
        return 0;
      case 'kg':
      case 'l':
      case 'litro':
        return 3;
      default:
        return 0;
    }
  }

  static String display(String digits, String unit) {
    final d = _digitsOnly(digits);
    if (d.isEmpty) return '0';
    final shift = shiftFor(unit);
    if (shift == 0) {
      final stripped = d.replaceAll(RegExp(r'^0+'), '');
      return stripped.isEmpty ? '0' : stripped;
    }
    final intPart =
        d.substring(0, max(0, d.length - shift)).replaceAll(RegExp(r'^0+'), '');
    final dec =
        d.length <= shift ? _padLeft(d, shift) : d.substring(d.length - shift);
    if (intPart.isEmpty) return '0,$dec';
    return '$intPart,$dec';
  }

  static double toValue(String displayText, String unit) {
    final d = _digitsOnly(displayText);
    if (d.isEmpty) return 0.0;
    final shift = shiftFor(unit);
    final factor = pow(10, shift).toInt();
    return int.parse(d) / factor;
  }

  static String fromValue(double value, String unit) {
    final shift = shiftFor(unit);
    final factor = pow(10, shift).toInt();
    final digits = (value * factor).round().abs().toString();
    if (digits == '0') return '';
    return digits;
  }

  static String nextDisplay(
    String oldDigits,
    String newRaw,
    String unit, {
    int maxDigits = 9,
  }) {
    var newDigits = _digitsOnly(newRaw);
    if (newDigits.length > maxDigits) {
      newDigits = oldDigits;
    }
    return display(newDigits, unit);
  }

  static TextInputFormatter formatterFor(String unit) =>
      _QuantityMaskFormatter(unit);

  static String _digitsOnly(String text) =>
      text.replaceAll(RegExp(r'[^0-9]'), '');

  static String _padLeft(String digits, int length) =>
      digits.padLeft(length, '0');
}

class _QuantityMaskFormatter extends TextInputFormatter {
  final String unit;

  _QuantityMaskFormatter(this.unit);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = QuantityMask._digitsOnly(oldValue.text);
    final newText = QuantityMask.nextDisplay(oldDigits, newValue.text, unit);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
      composing: TextRange.empty,
    );
  }
}
