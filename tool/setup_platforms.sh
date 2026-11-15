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

# Naziv aplikacije prikazan na uređaju.
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  sed -i.bak 's/android:label="[^"]*"/android:label="Moj Trošak"/' "$MANIFEST"
  rm -f "$MANIFEST.bak"
fi

PLIST="ios/Runner/Info.plist"
if [ -f "$PLIST" ]; then
  # CFBundleDisplayName -> Moj Trošak
  /usr/bin/env python3 - "$PLIST" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)", r"\1Moj Trošak\2", s)
open(p, "w", encoding="utf-8").write(s)
PY
fi

# flutter create dodaje primjer testa koji ne odgovara ovoj aplikaciji.
rm -f test/widget_test.dart

flutter pub get
echo "Gotovo. Sljedeće: dart format . && flutter analyze && flutter test && flutter run"
