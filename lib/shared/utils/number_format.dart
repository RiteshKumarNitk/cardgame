/// Formats a non-negative integer with thousands separators, e.g. `1250`
/// -> `1,250`. Small and local rather than pulling in `intl` for one thing.
String formatThousands(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
