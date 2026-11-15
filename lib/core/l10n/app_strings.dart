import '../constants/app_constants.dart';

/// Svi tekstovi korisničkog sučelja (hrvatski).
///
/// Tekstovi su na jednom mjestu kako bi se u kasnijoj fazi mogli prebaciti
/// u ARB datoteke (`flutter gen-l10n`) i dodati engleski prijevod bez
/// mijenjanja ekrana.
abstract final class AppStrings {
  // Općenito
  static const String appName = AppConstants.appName;
  static const String save = 'Spremi';
  static const String cancel = 'Odustani';
  static const String delete = 'Obriši';
  static const String edit = 'Uredi';
  static const String total = 'Ukupno';
  static const String seeAll = 'Sve';
  static const String errorLoading = 'Podatke nije moguće učitati.';
  static const String saveFailed = 'Spremanje nije uspjelo. Pokušajte ponovno.';
  static const String uncategorized = 'Bez kategorije';

  // Navigacija
  static const String navHome = 'Početna';
  static const String navExpenses = 'Računi';
  static const String navScan = 'Skeniraj';
  static const String navStatistics = 'Statistika';
  static const String navSettings = 'Postavke';

  // Početna
  static const String totalExpenses = 'Ukupni troškovi';
  static const String paidThisMonth = 'Plaćeno ovaj mjesec';
  static const String unpaidOpen = 'Neplaćeno (svi otvoreni)';
  static const String byCategoryThisMonth = 'Potrošnja po kategorijama';
  static const String recentExpenses = 'Najnoviji računi';
  static const String manualEntry = 'Ručni unos';
  static const String scan = 'Skeniraj';
  static const String noExpensesThisMonth = 'Ovaj mjesec još nema troškova.';
  static const String noExpensesYet =
      'Još nema evidentiranih računa. Dodajte prvi ručnim unosom.';

  static String overdueBanner(int count) =>
      'Dospjeli, a neplaćeni računi: $count';

  /// "1 račun", "2 računa", "5 računa", "21 račun"...
  static String expenseCount(int count) => '$count ${_racunPlural(count)}';

  static String _racunPlural(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'račun';
    return 'računa';
  }

  // Računi
  static const String expensesTitle = 'Računi';
  static const String newExpense = 'Novi račun';
  static const String editExpense = 'Uredi račun';
  static const String expenseDetail = 'Račun';
  static const String searchHint = 'Pretraži trgovinu, kategoriju, broj...';
  static const String clearSearch = 'Očisti pretragu';
  static const String filterAll = 'Svi';
  static const String allMonths = 'Svi mjeseci';
  static const String previousMonth = 'Prethodni mjesec';
  static const String nextMonth = 'Sljedeći mjesec';
  static const String noExpensesForFilter = 'Nema računa za odabrane filtre.';
  static const String expenseNotFound = 'Račun nije pronađen.';
  static const String expenseSaved = 'Račun je spremljen.';
  static const String expenseDeleted = 'Račun je obrisan.';
  static const String deleteExpenseTitle = 'Obrisati račun?';
  static const String deleteExpenseMessage =
      'Račun će biti uklonjen iz evidencije.';
  static const String markPaid = 'Označi kao plaćeno';
  static const String markUnpaid = 'Označi kao neplaćeno';
  static const String createdAt = 'Kreirano';
  static const String updatedAt = 'Izmijenjeno';

  // Polja računa
  static const String merchant = 'Izdavatelj / trgovina';
  static const String merchantRequired = 'Unesite naziv izdavatelja.';
  static const String category = 'Kategorija';
  static const String categoryRequired = 'Odaberite kategoriju.';
  static const String expenseType = 'Vrsta računa';
  static const String totalAmount = 'Ukupan iznos';
  static const String amountHint = 'npr. 49,99';
  static const String amountInvalid = 'Unesite ispravan iznos (npr. 49,99).';
  static const String amountMustBePositive = 'Iznos mora biti veći od nule.';
  static const String issueDate = 'Datum izdavanja';
  static const String dueDate = 'Datum dospijeća';
  static const String paidDate = 'Datum plaćanja';
  static const String clearDate = 'Ukloni datum';
  static const String paymentStatus = 'Status plaćanja';
  static const String invoiceNumber = 'Broj računa';
  static const String invoiceNumberOptional = 'Broj računa (neobavezno)';
  static const String note = 'Napomena';
  static const String noteOptional = 'Napomena (neobavezno)';

  // Statusi i vrste
  static const String statusPaid = 'Plaćeno';
  static const String statusUnpaid = 'Neplaćeno';
  static const String statusPartiallyPaid = 'Djelomično plaćeno';
  static const String statusOverdue = 'Dospjelo';
  static const String typeUtility = 'Režije';
  static const String typeRetail = 'Maloprodaja';
  static const String typeOther = 'Ostalo';

  // Skeniranje
  static const String scanNotAvailableTitle = 'Skeniranje još nije dostupno';
  static const String scanNotAvailableBody =
      'Ova verzija aplikacije (Faza 1) još ne sadrži skener. '
      'Do tada račune možete unijeti ručno.';
  static const String scanPlannedQr = 'Skeniranje QR koda s računa';
  static const String scanPlannedQrPhase = 'Planirano u fazi 2';
  static const String scanPlannedOcr =
      'Fotografija ili PDF računa (OCR, prepoznavanje artikala)';
  static const String scanPlannedOcrPhase = 'Planirano u fazi 3';

  // Statistika
  static const String monthComparison = 'Usporedba s prethodnim mjesecom';
  static const String byCategory = 'Po kategorijama';
  static const String byMonth = 'Po mjesecima';
  static const String difference = 'Razlika';
  static const String yearTotal = 'Ukupno za godinu';
  static const String previousYear = 'Prethodna godina';
  static const String nextYear = 'Sljedeća godina';

  // Postavke
  static const String settingsGeneral = 'Općenito';
  static const String settingsStorage = 'Pohrana';
  static const String settingsData = 'Podaci';
  static const String currency = 'Valuta';
  static const String dateFormat = 'Format datuma';
  static const String language = 'Jezik';
  static const String languageCroatian = 'Hrvatski';
  static const String storageLocal = 'Lokalno na uređaju';
  static const String storageLocalDescription =
      'Svi podaci spremaju se u lokalnu bazu i rade bez interneta.';
  static const String cloudSync = 'Sinkronizacija u oblak';
  static const String cloudSyncNotYet =
      'Još nije uključena (planirano u fazi 5, Supabase).';
  static const String wipeDataTitle = 'Obriši sve podatke';
  static const String wipeDataSubtitle =
      'Trajno briše sve račune s ovog uređaja.';
  static const String wipeDataMessage =
      'Svi računi, trgovine i promjene koje čekaju sinkronizaciju bit će '
      'trajno obrisani s ovog uređaja. Ova radnja se ne može poništiti.';
  static const String wipeDataConfirm = 'Obriši sve';
  static const String wipeDataDone = 'Svi lokalni podaci su obrisani.';
  static const String about = 'O aplikaciji';
  static const String aboutLegalese =
      'Aplikacija za praćenje osobnih troškova. '
      'Podaci se ne šalju vanjskim servisima.';
}
