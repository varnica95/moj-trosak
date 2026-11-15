#!/usr/bin/env bash
# Generira Android i iOS platformske mape (android/, ios/) koje Flutter
# stvara sam, bez diranja postojećeg koda u lib/ i test/.
# Pokrenuti jednom iz korijena projekta: bash tool/setup_platforms.sh
set -euo pipefail

cd "$(dirname "$0")/.."

flutter create \
  --platforms=android,ios \
  --org hr.mojtrosak \
  --project-name moj_trosak \
  .

# Naziv aplikacije, minSdk (ML Kit / skener), iOS dopuštenja za kameru.
python3 tool/patch_platforms.py

# flutter create dodaje primjer testa koji ne odgovara ovoj aplikaciji.
rm -f test/widget_test.dart

flutter pub get
echo "Gotovo. Sljedeće: dart format . && flutter analyze && flutter test && flutter run"
