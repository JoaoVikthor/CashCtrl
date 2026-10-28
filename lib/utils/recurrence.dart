const List<String> kRecurrenceFrequencies = ['semanal', 'mensal', 'anual'];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

DateTime _addMonths(DateTime d, int months) {
  var year = d.year + (d.month + months - 1) ~/ 12;
  var month = (d.month + months - 1) % 12 + 1;
  final day = d.day.clamp(1, _daysInMonth(year, month));
  return DateTime(year, month, day);
}

DateTime _addYears(DateTime d, int years) {
  final year = d.year + years;
  final day = d.day.clamp(1, _daysInMonth(year, d.month));
  return DateTime(year, d.month, day);
}

List<DateTime> computeDueOccurrences({
  required DateTime startDate,
  required String frequency,
  required DateTime now,
}) {
  final start = _dateOnly(startDate);
  final today = _dateOnly(now);
  if (!start.isBefore(today)) return [];

  final List<DateTime> result = [];
  DateTime current;

  switch (frequency) {
    case 'semanal':
      current = start.add(const Duration(days: 7));
      while (!current.isAfter(today)) {
        result.add(current);
        current = current.add(const Duration(days: 7));
      }
    case 'mensal':
      var months = 1;
      current = _addMonths(start, months);
      while (!current.isAfter(today)) {
        result.add(current);
        months++;
        current = _addMonths(start, months);
      }
    case 'anual':
      var years = 1;
      current = _addYears(start, years);
      while (!current.isAfter(today)) {
        result.add(current);
        years++;
        current = _addYears(start, years);
      }
  }

  return result;
}

DateTime? nextOccurrenceAfter({
  required DateTime startDate,
  required String frequency,
  required DateTime after,
}) {
  final start = _dateOnly(startDate);
  final reference = _dateOnly(after);

  switch (frequency) {
    case 'semanal':
      if (!start.isAfter(reference)) {
        final diff = reference.difference(start).inDays;
        final weeks = diff ~/ 7;
        var candidate = start.add(Duration(days: (weeks + 1) * 7));
        if (!candidate.isAfter(reference)) {
          candidate = candidate.add(const Duration(days: 7));
        }
        return candidate;
      }
      return start;
    case 'mensal':
      if (!start.isAfter(reference)) {
        var months = (reference.year - start.year) * 12 +
            (reference.month - start.month);
        var candidate = _addMonths(start, months);
        if (!candidate.isAfter(reference)) {
          candidate = _addMonths(start, months + 1);
        }
        return candidate;
      }
      return start;
    case 'anual':
      if (!start.isAfter(reference)) {
        var years = reference.year - start.year;
        var candidate = _addYears(start, years);
        if (!candidate.isAfter(reference)) {
          candidate = _addYears(start, years + 1);
        }
        return candidate;
      }
      return start;
    default:
      return null;
  }
}
