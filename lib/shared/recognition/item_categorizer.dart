import 'text_normalize.dart';

/// Jednostavno pogađanje kategorije artikla prema ključnim riječima.
///
/// Vraća ključ kategorije artikla (npr. `item_food`) ili `null` ako nije
/// siguran. Korisnik kategoriju uvijek može promijeniti.
abstract final class ItemCategorizer {
  static const Map<String, List<String>> _keywords = {
    'item_drinks': [
      'VODA', 'SOK', 'PIVO', 'VINO', 'COLA', 'NAPITAK', 'KAVA', 'CAJ ',
      'JANA', 'CEDEVITA', 'RAKIJA', 'LIKER', 'ENERGY', 'NEKTAR',
    ],
    'item_hygiene': [
      'SAPUN', 'SAMPON', 'PASTA ZA ZUBE', 'ZUBNA', 'DEZODORANS', 'DEO ',
      'GEL ZA TUS', 'KREMA', 'ULOSCI', 'PELENE', 'BRIJA', 'MARAMICE',
      'BALZAM', 'TOALETNI PAPIR', 'WC PAPIR', 'HIGIJEN',
    ],
    'item_household': [
      'DETERDZENT', 'OMEKSIVAC', 'DOMESTOS', 'SREDSTVO ZA', 'SPUZV',
      'VRECICE', 'FOLIJA', 'UBRUS', 'PAPIRNATI', 'BATERIJ', 'ZARULJ',
      'TABLETE ZA', 'SVIJEC', 'KRPA',
    ],
    'item_food': [
      'MLIJEKO', 'KRUH', 'JOGURT', 'SIR ', 'MASLAC', 'JAJA', 'BRASNO',
      'SECER', 'SOL ', 'ULJE', 'TJESTEN', 'RIZA', 'MESO', 'PILE', 'PILEC',
      'SALAM', 'SUNKA', 'KOBASIC', 'BANAN', 'JABUK', 'KRUMPIR', 'LUK ',
      'RAJCIC', 'PAPRIK', 'VOCE', 'POVRCE', 'COKOLAD', 'KEKS',
      'CIPS', 'PECIVO', 'BUREK', 'KROASAN', 'VRHNJE', 'MARGARIN', 'MED ',
      'RIBA', 'TUNA', 'PASTETA', 'NAMAZ', 'JUHA', 'KECAP', 'MAJONEZ',
    ],
    'item_clothing': ['CARAPE', 'MAJICA', 'HLACE', 'JAKNA', 'TENISICE'],
    'item_electronics': ['PUNJAC', 'KABEL', 'SLUSALICE', 'USB'],
  };

  static String? categoryKeyFor(String itemName) {
    final folded = ' ${foldText(itemName)} ';
    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        if (folded.contains(keyword.toUpperCase())) return entry.key;
      }
    }
    return null;
  }
}
