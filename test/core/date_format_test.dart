import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moj_trosak/core/l10n/app_strings.dart';
import 'package:moj_trosak/core/utils/date_format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('hr'));

  test('prikaz datuma DD.MM.YYYY.', () {
    expect(formatDate(DateTime(2026, 3, 7)), '07.03.2026.');
  });

  test('pretvorba datuma za bazu', () {
    expect(toDbDate(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
    expect(fromDbDate('2026-01-05'), DateTime(2026, 1, 5));
    expect(fromDbDateOrNull(null), isNull);
  });

  test('raspon mjeseca i prijelaz godine', () {
    final dec = monthRangeDb(DateTime(2026, 12, 15));
    expect(dec.start, '2026-12-01');
    expect(dec.end, '2027-01-01');
    expect(addMonths(DateTime(2026, 1), -1), DateTime(2025, 12));
    expect(monthKey(DateTime(2026, 3)), '2026-03');
  });

  test('naziv mjeseca na hrvatskom', () {
    expect(formatMonthYear(DateTime(2026, 11)), 'Studeni 2026.');
    expect(formatMonthName(DateTime(2026, 10)), 'Listopad');
  });

  test('množina riječi "račun"', () {
    expect(AppStrings.expenseCount(1), '1 račun');
    expect(AppStrings.expenseCount(2), '2 računa');
    expect(AppStrings.expenseCount(11), '11 računa');
    expect(AppStrings.expenseCount(21), '21 račun');
  });
}
