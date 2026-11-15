import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

// Formatiranje i pretvorba datuma.
//
// Prikaz: `DD.MM.YYYY.`
// Baza:   `YYYY-MM-DD` za kalendarske datume, ISO 8601 UTC za vremenske oznake.

/// Datum u formatu `DD.MM.YYYY.`
String formatDate(DateTime date) => DateFormat('dd.MM.yyyy.').format(date);

String formatDateTime(DateTime dateTime) =>
    DateFormat('dd.MM.yyyy. HH:mm').format(dateTime);

/// Naziv mjeseca s godinom, npr. `Studeni 2026.`
/// Zahtijeva prethodni poziv `initializeDateFormatting('hr')`.
String formatMonthYear(DateTime month) =>
    _capitalize(DateFormat('LLLL yyyy.', AppConstants.localeCode).format(month));

/// Samo naziv mjeseca, npr. `Studeni`.
String formatMonthName(DateTime month) =>
    _capitalize(DateFormat('LLLL', AppConstants.localeCode).format(month));

/// Kratki naziv mjeseca, npr. `stu`.
String formatMonthShort(DateTime month) =>
    DateFormat('LLL', AppConstants.localeCode).format(month);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

DateTime addMonths(DateTime month, int delta) =>
    DateTime(month.year, month.month + delta);

String toDbDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime fromDbDate(String value) {
  final d = DateTime.parse(value);
  return DateTime(d.year, d.month, d.day);
}

DateTime? fromDbDateOrNull(Object? value) =>
    value is String && value.isNotEmpty ? fromDbDate(value) : null;

String toDbTimestamp(DateTime d) => d.toUtc().toIso8601String();

DateTime fromDbTimestamp(String value) => DateTime.parse(value).toLocal();

DateTime? fromDbTimestampOrNull(Object? value) =>
    value is String && value.isNotEmpty ? fromDbTimestamp(value) : null;

/// Raspon mjeseca za upite: `start` uključivo, `end` isključivo.
({String start, String end}) monthRangeDb(DateTime month) {
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  return (start: toDbDate(start), end: toDbDate(end));
}

/// Ključ mjeseca kakav vraća SQLite `substr(issue_date, 1, 7)`, npr. `2026-11`.
String monthKey(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-'
    '${month.month.toString().padLeft(2, '0')}';

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
