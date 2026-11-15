# Moj Trošak

Android aplikacija (Flutter, s pripremom za iOS) za praćenje osobnih troškova.
Trenutno stanje: **FAZA 1** (temelj, lokalna baza, ručni unos) i **FAZE 2–3** (QR skener, OCR računa).

## Pokretanje

Potrebno: Flutter **3.35+** (Dart 3.9+), Android SDK, Android uređaj ili emulator.

```bash
# 1. Jednom: generiraj android/ i ios/ mape (lib/ i test/ ostaju netaknuti)
bash tool/setup_platforms.sh

# 2. Provjere
dart format .
flutter analyze
flutter test          # testovi baze trebaju libsqlite3 na računalu (Linux: apt install libsqlite3-dev)

# 3. Pokretanje na uređaju
flutter run

# 4. APK za instalaciju
flutter build apk --release
```

Na Windowsu umjesto skripte pokrenite:
`flutter create --platforms=android,ios --org hr.mojtrosak --project-name moj_trosak .`,
zatim u `android/app/src/main/AndroidManifest.xml` postavite `android:label="Moj Trošak"`
i obrišite `test/widget_test.dart` koji `flutter create` doda.

## Izrada APK-a bez Fluttera (GitHub Actions)

Svaki push na `main` pokreće `.github/workflows/build-apk.yml`: generira Android
platformu, primjenjuje `tool/patch_platforms.py` (naziv, minSdk 24, R8 pravila za ML Kit),
pokreće analizu i testove te izrađuje APK. APK se preuzima pod **Actions → zadnji
build → Artifacts → moj-trosak-apk**.

## Arhitektura

Clean architecture po slojevima, organizirano po funkcionalnostima:

```
lib/
  main.dart                 inicijalizacija (lokalizacija, baza) + ProviderScope
  app.dart                  MaterialApp.router, tema, hr lokalizacija
  core/
    constants/              AppConstants
    l10n/                   AppStrings – svi tekstovi na hrvatskom na jednom mjestu
    router/                 GoRouter (StatefulShellRoute s 5 kartica)
    theme/                  Material 3 tema i paleta (#173C5A, #F6F8FA...)
    utils/                  novac (centi), datumi (DD.MM.YYYY.), UUID-ovi
  data/
    database/               SQLite shema, seed, sync_queue writer
    models/                 Expense, ExpenseCategory, Merchant, filtri, sažeci
    repositories/           ExpenseRepository, CategoryRepository, MerchantRepository
    providers.dart          Riverpod provideri baze i repozitorija
  features/
    dashboard/              početni ekran
    expenses/               popis, detalji, obrazac (ručni unos/izmjena)
    scanner/                kartica "Skeniraj" (skener dolazi u fazi 2)
    statistics/             osnovna statistika (grafovi u fazi 4)
    settings/               postavke, brisanje podataka
    <feature>/application/  Riverpod provideri i radnje
    <feature>/presentation/ ekrani i widgeti
  shared/widgets/           zajednički widgeti (kartice, status, datumi...)
```

**Tok podataka:** ekran → provider (`application/`) → repozitorij → SQLite.
Nakon svake izmjene `DataRevision` provider se poveća i svi povezani prikazi se
automatski ponovno učitavaju.

### Odluke i obrazloženja

| Odluka | Razlog |
|---|---|
| **sqflite** umjesto Drifta u fazi 1 | Nema generiranja koda (build_runner), pa se projekt pokreće odmah nakon `pub get`. Repozitoriji skrivaju bazu – prelazak na Drift kasnije ne mijenja ekrane. |
| Iznosi kao **cijeli broj centi** | Bez grešaka zaokruživanja (`double`). |
| **UUID** za sve zapise; v5 (deterministički) za kategorije i trgovine | Isti naziv trgovine = isti ID na svakom uređaju → nema duplikata ni lokalno ni pri sinkronizaciji. |
| `created_at`, `updated_at`, `deleted_at`, `sync_status`, `version` | Meko brisanje (tombstone) i predvidljivo rješavanje konflikata u fazi 5. |
| `sync_queue` – jedan zapis po entitetu, puni redak | Promjena se upisuje u istoj transakciji kao i podatak; novija promjena zamjenjuje stariju → nema višestrukog slanja. |
| Tekstualna pretraga u Dartu | SQLite `LIKE` ne razlikuje velika/mala slova za Č, Ć, Š, Ž, Đ. |
| Tekstovi u `AppStrings` | Kasnije se prebacuju u ARB (`gen-l10n`) za engleski bez izmjena ekrana. |

### Baza podataka

Tablice: `categories`, `merchants`, `expenses`, `expense_items`, `attachments`, `sync_queue`.
`expense_items` i `attachments` su već u shemi (za fazu 3), ali ih UI još ne koristi.

## Status – FAZA 2–3 (skeniranje i OCR)

**Implementirano:**
- QR/2D skener (mobile_scanner): fiskalni QR (porezna.gov.hr – datum i iznos), HUB3 PDF417 s uplatnica (iznos, primatelj, IBAN, poziv na broj), EPC QR
- OCR fotografije ili slike iz galerije (Google ML Kit, isključivo na uređaju): trgovina, datum, broj računa, ukupno, PDV, artikli (naziv, količina, jedinična i ukupna cijena), automatska kategorija artikla
- Rekonstrukcija redova računa iz OCR blokova (lijevi stupac nazivi + desni stupac cijene)
- Obrazac za pregled: upozorenja o nesigurnim podacima, uređivanje/dodavanje/brisanje stavki, provjera zbroja stavki, fotografija uz račun
- Nakon QR koda moguće je dodati fotografiju – OCR popunjava samo prazna polja i stavke
- Ništa se ne sprema automatski – korisnik uvijek potvrđuje
- Baza v2 (`tax_cents`), stavke i privitci u `sync_queue`

**Još nije:** uvoz PDF računa, ručno uklanjanje već spremljenih fotografija.

## Status – FAZA 1

**Implementirano:**
- Projektna struktura, Material 3 tema, hrvatska lokalizacija (datumi, birač datuma)
- Navigacija s 5 kartica: Početna, Računi, Skeniraj, Statistika, Postavke
- Lokalna SQLite baza sa svih 6 tablica, početnim kategorijama i trgovinama (HEP, Zagrebački holding, Konzum, Kaufland, Lidl, Plodine, DM)
- Dashboard: ukupno ovaj mjesec, plaćeno, neplaćeno (svi otvoreni), upozorenje za dospjele, potrošnja po kategorijama, najnoviji računi, brzi gumbi
- Ručni unos i izmjena računa (izdavatelj s automatskim prijedlogom, kategorija, vrsta, iznos, datumi izdavanja/dospijeća/plaćanja, status, broj računa, napomena) s validacijom
- Popis računa: pretraga (trgovina, kategorija, broj, napomena), filtar po statusu i mjesecu
- Detalji računa: ručna promjena statusa, uređivanje, brisanje uz potvrdu
- Statistika (osnovna): usporedba s prethodnim mjesecom, po kategorijama, po mjesecima za godinu
- Postavke: trajno brisanje svih lokalnih podataka uz potvrdu
- Red za sinkronizaciju (`sync_queue`) puni se pri svakoj izmjeni
- Testovi: novac, datumi, repozitorij (stvarna SQLite baza u memoriji), dashboard widget

**Još nije implementirano (sljedeće faze):**
- Grafovi fl_chart (faza 4), uvoz PDF računa
- Supabase prijava, sinkronizacija, upload dokumenata (faza 5)
- Lokalne obavijesti, izvoz podataka, enkripcija baze (SQLCipher), tamna tema, engleski jezik
- Filtar po iznosu postoji u repozitoriju i testiran je, ali još nema UI
- Djelomično plaćanje: podržano u shemi (`paid_cents`), ne u UI-ju

## Supabase (faza 5) – što će trebati

Ništa od Supabasea još nije u aplikaciji. Za fazu 5 trebat ćete:
1. Supabase projekt → **Project URL** i **anon (public) key**.
2. Ključevi se prosljeđuju pri buildu (`--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`), ne u kodu.
3. **Service role ključ nikada ne ide u aplikaciju.**
4. Uključen Row Level Security na svim tablicama (`user_id = auth.uid()`).
