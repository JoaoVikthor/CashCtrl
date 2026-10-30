String _fmt(double v) {
  final abs = v.abs();
  final s = abs.toStringAsFixed(2);
  final parts = s.split('.');
  final intPart = parts[0];
  final dec = parts[1];
  final withSeparators = _groupThousands(intPart);
  return '$withSeparators,$dec';
}

String _groupThousands(String intPart) {
  final buf = StringBuffer();
  var count = 0;
  for (var i = intPart.length - 1; i >= 0; i--) {
    if (count == 3) {
      buf.write('.');
      count = 0;
    }
    buf.write(intPart[i]);
    count++;
  }
  final out = buf.toString();
  return String.fromCharCodes(out.runes.toList().reversed);
}

String formatCurrency(double value) {
  final sign = value < 0 ? '-' : '';
  return '$sign R\$ ${_fmt(value)}';
}

String formatCurrencyAbs(double value) => 'R\$ ${_fmt(value)}';

String formatQuantity(double value) {
  var s = value.toStringAsFixed(2);
  if (s.endsWith('.00')) {
    s = s.substring(0, s.length - 3);
  } else if (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  return s.replaceAll('.', ',');
}

String _pad(int n) => n < 10 ? '0$n' : '$n';

String formatDate(DateTime d) =>
    '${_pad(d.day)}/${_pad(d.month)}/${d.year}';

const List<String> _months = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
];

String formatDateShort(DateTime d) => '${_pad(d.day)} ${_months[d.month - 1]}';