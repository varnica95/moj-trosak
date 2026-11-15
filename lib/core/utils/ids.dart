import 'package:uuid/uuid.dart';

/// Generiranje stabilnih UUID identifikatora.
abstract final class Ids {
  static const Uuid _uuid = Uuid();

  /// UUID v5 imenski prostor (RFC 4122, "URL" namespace).
  static const String _namespace = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  /// Nasumični UUID v4 za nove zapise (računi, stavke, privitci...).
  static String newId() => _uuid.v4();

  /// Deterministički UUID za ugrađene kategorije.
  ///
  /// Isti ključ daje isti UUID na svakom uređaju, pa se kod sinkronizacije
  /// (FAZA 5) kategorije ne dupliciraju.
  static String category(String key) =>
      _uuid.v5(_namespace, 'mojtrosak:category:$key');

  /// Deterministički UUID za izdavatelja/trgovinu prema normaliziranom nazivu.
  ///
  /// Isti naziv ("Konzum", "KONZUM ") uvijek daje isti zapis, čime se
  /// sprječava dupliciranje trgovina lokalno i kod sinkronizacije.
  static String merchant(String normalizedName) =>
      _uuid.v5(_namespace, 'mojtrosak:merchant:$normalizedName');
}

/// Normalizira naziv trgovine za usporedbu i deduplikaciju.
String normalizeName(String name) =>
    name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
