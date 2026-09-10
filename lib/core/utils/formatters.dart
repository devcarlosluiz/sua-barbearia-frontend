import 'package:intl/intl.dart';

/// Formatação pt-BR: moeda em BRL, datas DD/MM/AAAA e horários HH:MM.
class Formatters {
  const Formatters._();

  static final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);
  static final NumberFormat _compactCurrency =
      NumberFormat.compactCurrency(locale: 'pt_BR', symbol: r'R$');
  static final NumberFormat _decimal = NumberFormat.decimalPattern('pt_BR');

  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final DateFormat _dateShort = DateFormat('dd/MM', 'pt_BR');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  static final DateFormat _time = DateFormat('HH:mm', 'pt_BR');
  static final DateFormat _weekday = DateFormat('EEEE', 'pt_BR');
  static final DateFormat _monthYear = DateFormat('MMMM/yyyy', 'pt_BR');
  static final DateFormat _dayMonthLong = DateFormat("d 'de' MMMM", 'pt_BR');
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  // --- Moeda ---
  static String currency(num? value) => _currency.format(value ?? 0);

  static String currencyFromString(String? value) =>
      currency(double.tryParse(value ?? '') ?? 0);

  static String compactCurrency(num? value) =>
      _compactCurrency.format(value ?? 0);

  static String number(num? value) => _decimal.format(value ?? 0);

  static String percent(num? value) =>
      '${_decimal.format(value ?? 0)}%'.replaceAll(',00%', '%');

  // --- Datas ---
  static String date(DateTime? value) =>
      value == null ? '-' : _date.format(value);

  static String dateShort(DateTime? value) =>
      value == null ? '-' : _dateShort.format(value);

  static String dateTime(DateTime? value) =>
      value == null ? '-' : _dateTime.format(value);

  static String time(DateTime? value) =>
      value == null ? '-' : _time.format(value);

  static String weekday(DateTime value) => _capitalize(_weekday.format(value));

  static String monthYear(DateTime value) =>
      _capitalize(_monthYear.format(value));

  static String dayMonthLong(DateTime value) => _dayMonthLong.format(value);

  static String isoDate(DateTime value) => _iso.format(value);

  /// `HH:MM` a partir do formato `HH:MM:SS` devolvido pela API.
  static String clock(String? value) {
    if (value == null || value.isEmpty) return '-';
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  /// Rótulo relativo amigável: "Hoje", "Amanhã", "Ontem" ou a data.
  static String friendlyDate(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Amanhã';
    if (difference == -1) return 'Ontem';
    if (difference > 1 && difference < 7) return weekday(value);
    return date(value);
  }

  static String duration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0
        ? '${hours}h'
        : '${hours}h${rest.toString().padLeft(2, '0')}';
  }

  // --- Documentos e contatos ---
  static String phone(String? value) {
    final digits = _digits(value);
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return value ?? '';
  }

  static String cpf(String? value) {
    final digits = _digits(value);
    if (digits.length != 11) return value ?? '';
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
        '${digits.substring(6, 9)}-${digits.substring(9)}';
  }

  static String cnpj(String? value) {
    final digits = _digits(value);
    if (digits.length != 14) return value ?? '';
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
        '${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }

  static String zipCode(String? value) {
    final digits = _digits(value);
    if (digits.length != 8) return value ?? '';
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }

  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static String _digits(String? value) =>
      (value ?? '').replaceAll(RegExp(r'\D'), '');

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
