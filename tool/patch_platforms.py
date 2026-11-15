#!/usr/bin/env python3
"""Prilagodba datoteka koje generira `flutter create` (android/, ios/).

Pokreće se iz korijena projekta nakon `flutter create` – lokalno
(tool/setup_platforms.sh) i u GitHub Actions buildu.
"""
import re
import shutil
from pathlib import Path

APP_NAME = "Moj Trošak"
MIN_SDK = 24  # ML Kit i mobile_scanner

CAMERA_TEXT = "Kamera se koristi za skeniranje QR kodova i fotografiranje računa."
PHOTOS_TEXT = "Pristup fotografijama koristi se za odabir fotografije računa."


def patch_android() -> None:
    manifest = Path("android/app/src/main/AndroidManifest.xml")
    if manifest.exists():
        s = manifest.read_text(encoding="utf-8")
        s = re.sub(r'android:label="[^"]*"', f'android:label="{APP_NAME}"', s)
        manifest.write_text(s, encoding="utf-8")
        print("AndroidManifest: label")

    for name in ("build.gradle.kts", "build.gradle"):
        gradle = Path("android/app") / name
        if not gradle.exists():
            continue
        s = gradle.read_text(encoding="utf-8")
        s = s.replace(
            "minSdk = flutter.minSdkVersion",
            f"minSdk = maxOf(flutter.minSdkVersion, {MIN_SDK})",
        )
        s = s.replace(
            "minSdkVersion flutter.minSdkVersion",
            f"minSdkVersion Math.max(flutter.minSdkVersion, {MIN_SDK})",
        )
        if "proguard-rules.pro" not in s:
            if name.endswith(".kts"):
                s += (
                    '\nandroid {\n    buildTypes {\n        getByName("release") {\n'
                    '            proguardFiles("proguard-rules.pro")\n        }\n    }\n'
                    # Android lint ponekad padne unutar tuđih paketa
                    # (npr. image_picker); ne utječe na rad aplikacije.
                    '    lint {\n        checkReleaseBuilds = false\n    }\n}\n'
                )
            else:
                s += (
                    "\nandroid {\n    buildTypes {\n        release {\n"
                    "            proguardFiles 'proguard-rules.pro'\n        }\n    }\n"
                    "    lint {\n        checkReleaseBuilds false\n    }\n}\n"
                )
        gradle.write_text(s, encoding="utf-8")
        print(f"{gradle}: minSdk >= {MIN_SDK}, proguard-rules.pro")

    rules = Path(__file__).parent / "android" / "proguard-rules.pro"
    if Path("android/app").exists() and rules.exists():
        shutil.copy(rules, Path("android/app/proguard-rules.pro"))
        print("android/app/proguard-rules.pro")


def patch_ios() -> None:
    plist = Path("ios/Runner/Info.plist")
    if not plist.exists():
        return
    s = plist.read_text(encoding="utf-8")
    s = re.sub(
        r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)",
        rf"\g<1>{APP_NAME}\g<2>",
        s,
    )
    additions = ""
    if "NSCameraUsageDescription" not in s:
        additions += f"\t<key>NSCameraUsageDescription</key>\n\t<string>{CAMERA_TEXT}</string>\n"
    if "NSPhotoLibraryUsageDescription" not in s:
        additions += f"\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>{PHOTOS_TEXT}</string>\n"
    if additions:
        idx = s.rfind("</dict>")
        s = s[:idx] + additions + s[idx:]
    plist.write_text(s, encoding="utf-8")
    print("Info.plist: naziv i dopuštenja")


if __name__ == "__main__":
    patch_android()
    patch_ios()
