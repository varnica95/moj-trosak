import '../../data/models/enums.dart';
import 'text_normalize.dart';

/// Poznati izdavatelj s oznakama po kojima se prepoznaje na računu.
class KnownMerchant {
  const KnownMerchant({
    required this.name,
    required this.aliases,
    required this.type,
    required this.categoryKey,
  });

  /// Naziv pod kojim se sprema (isti kao u početnim podacima, ako postoji).
  final String name;

  /// Oznake u "presavijenom" obliku (velika slova, bez dijakritika).
  final List<String> aliases;
  final ExpenseType type;

  /// Ključ kategorije (vidi `SeedData` / `Ids.category`).
  final String categoryKey;
}

/// Prepoznaje trgovinu ili izdavatelja režija iz teksta.
abstract final class MerchantMatcher {
  static const List<KnownMerchant> known = [
    // Maloprodaja
    KnownMerchant(name: 'Konzum', aliases: ['KONZUM'], type: ExpenseType.retail, categoryKey: 'groceries'),
    KnownMerchant(name: 'Kaufland', aliases: ['KAUFLAND'], type: ExpenseType.retail, categoryKey: 'groceries'),
    KnownMerchant(name: 'Lidl', aliases: ['LIDL'], type: ExpenseType.retail, categoryKey: 'groceries'),
    KnownMerchant(name: 'Plodine', aliases: ['PLODINE'], type: ExpenseType.retail, categoryKey: 'groceries'),
    KnownMerchant(name: 'Spar', aliases: ['INTERSPAR', 'SPAR HRVATSKA', 'SPAR'], type: ExpenseType.retail, categoryKey: 'groceries'),
    KnownMerchant(name: 'Tommy', aliases: ['TOMMY'], type: ExpenseType.retail, categoryKey: 'groceries'),
    KnownMerchant(name: 'Studenac', aliases: ['STUDENAC'], type: ExpenseType.retail, categoryKey: 'groceries'),
    KnownMerchant(name: 'Eurospin', aliases: ['EUROSPIN'], type: ExpenseType.retail, categoryKey: 'groceries'),
    KnownMerchant(name: 'Ribola', aliases: ['RIBOLA'], type: ExpenseType.retail, categoryKey: 'groceries'),
    KnownMerchant(name: 'DM', aliases: ['DM-DROGERIE', 'DM DROGERIE', 'DROGERIE MARKT'], type: ExpenseType.retail, categoryKey: 'drugstore'),
    KnownMerchant(name: 'Müller', aliases: ['MULLER', 'MUELLER'], type: ExpenseType.retail, categoryKey: 'drugstore'),
    KnownMerchant(name: 'Bipa', aliases: ['BIPA'], type: ExpenseType.retail, categoryKey: 'drugstore'),
    // Režije
    KnownMerchant(name: 'HEP', aliases: ['HEP ELEKTRA', 'HEP-ELEKTRA', 'HEP OPSKRBA', 'HEP-OPSKRBA', 'HEP D.D', 'HEP-ODS', 'HEP ODS'], type: ExpenseType.utility, categoryKey: 'electricity'),
    KnownMerchant(name: 'Gradska plinara Zagreb', aliases: ['GRADSKA PLINARA'], type: ExpenseType.utility, categoryKey: 'gas'),
    KnownMerchant(name: 'Vodoopskrba i odvodnja', aliases: ['VODOOPSKRBA I ODVODNJA', 'VODOOPSKRBA'], type: ExpenseType.utility, categoryKey: 'water'),
    KnownMerchant(name: 'Zagrebački holding', aliases: ['ZAGREBACKI HOLDING', 'ZG HOLDING', 'CISTOCA'], type: ExpenseType.utility, categoryKey: 'communal'),
    KnownMerchant(name: 'Hrvatski Telekom', aliases: ['HRVATSKI TELEKOM', 'HT D.D', 'T-COM'], type: ExpenseType.utility, categoryKey: 'internet_phone'),
    KnownMerchant(name: 'A1', aliases: ['A1 HRVATSKA'], type: ExpenseType.utility, categoryKey: 'internet_phone'),
    KnownMerchant(name: 'Telemach', aliases: ['TELEMACH'], type: ExpenseType.utility, categoryKey: 'internet_phone'),
    KnownMerchant(name: 'Iskon', aliases: ['ISKON'], type: ExpenseType.utility, categoryKey: 'internet_phone'),
  ];

  /// Vraća prvog poznatog izdavatelja čija se oznaka pojavljuje kao
  /// zasebna riječ u nekom od redaka (redoslijed redaka je prioritet).
  static KnownMerchant? match(Iterable<String> lines) {
    for (final line in lines) {
      final folded = ' ${foldText(line)} ';
      for (final merchant in known) {
        for (final alias in merchant.aliases) {
          final pattern = RegExp(
            '(^|[^A-Z0-9])${RegExp.escape(alias)}(\$|[^A-Z0-9])',
          );
          if (pattern.hasMatch(folded)) return merchant;
        }
      }
    }
    return null;
  }
}
