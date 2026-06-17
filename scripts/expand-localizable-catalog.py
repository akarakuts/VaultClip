#!/usr/bin/env python3
# expand-localizable-catalog.py — fill Localizable.xcstrings for all macOS app locales.

from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "VaultClip/Resources/Localizable.xcstrings"
CACHE = ROOT / "scripts/.localization-cache.json"

# Locales Xcode offers for macOS apps (BCP-47); en + ru are source/manual.
MACOS_APP_LOCALES = [
    "ar", "bg", "bn", "ca", "cs", "da", "de", "el", "en", "en-AU", "en-GB", "en-IN",
    "es", "es-419", "es-US", "fi", "fr", "fr-CA", "he", "hi", "hr", "hu", "id", "it",
    "ja", "kk", "ko", "lt", "lv", "ms", "nb", "nl", "pl", "pt-BR", "pt-PT", "ro", "ru",
    "sk", "sl", "sv", "ta", "te", "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant", "zh-HK",
]

ENGLISH_VARIANTS = {"en", "en-AU", "en-GB", "en-IN"}

# deep-translator target codes
TRANSLATOR_LOCALE = {
    "he": "iw",  # Google Translate legacy Hebrew code
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
    "zh-HK": "zh-TW",
    "nb": "no",
    "es-419": "es",
    "es-US": "es",
    "pt-BR": "pt",
    "pt-PT": "pt",
    "fr-CA": "fr",
    "en-AU": "en",
    "en-GB": "en",
    "en-IN": "en",
}

PLACEHOLDER_RE = re.compile(
    r"(%[@\d]*(?:\.\d+)?[hlL]*|https?://[^\s]+|⌘[⇧⌥⌃\\]*|[⌘⇧⌥⌃]+|Ctrl\+[^\s]*|⌘\\)"
)


def protect_placeholders(text: str) -> tuple[str, list[str]]:
    tokens: list[str] = []

    def repl(match: re.Match[str]) -> str:
        tokens.append(match.group(0))
        return f"⟦{len(tokens) - 1}⟧"

    return PLACEHOLDER_RE.sub(repl, text), tokens


def restore_placeholders(text: str, tokens: list[str]) -> str:
    for index, token in enumerate(tokens):
        text = text.replace(f"⟦{index}⟧", token)
    return text


def load_cache() -> dict[str, str]:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict[str, str]) -> None:
    CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")


def translate(text: str, locale: str, cache: dict[str, str]) -> str:
    if locale in ENGLISH_VARIANTS:
        return text
    if locale == "ru":
        return text  # caller passes existing ru or en fallback

    key = f"{locale}\n{text}"
    if key in cache:
        return cache[key]

    protected, tokens = protect_placeholders(text)
    target = TRANSLATOR_LOCALE.get(locale, locale.split("-")[0])

    try:
        from deep_translator import GoogleTranslator

        translated = GoogleTranslator(source="en", target=target).translate(protected)
        if not translated:
            translated = protected
    except Exception as exc:  # noqa: BLE001
        print(f"translate failed {locale}: {exc}", file=sys.stderr)
        translated = protected

    result = restore_placeholders(translated, tokens)
    cache[key] = result
    time.sleep(0.05)
    return result


def main() -> int:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    cache = load_cache()
    strings = data["strings"]
    total_added = 0

    for key, entry in strings.items():
        localizations = entry.setdefault("localizations", {})
        en_value = localizations.get("en", {}).get("stringUnit", {}).get("value")
        if not en_value:
            continue
        ru_value = localizations.get("ru", {}).get("stringUnit", {}).get("value")

        for locale in MACOS_APP_LOCALES:
            if locale in localizations:
                continue

            if locale in ENGLISH_VARIANTS:
                value = en_value
            elif locale == "ru" and ru_value:
                value = ru_value
            else:
                value = translate(en_value, locale, cache)

            localizations[locale] = {
                "stringUnit": {
                    "state": "translated" if locale in ("en", "ru") else "needs_review",
                    "value": value,
                }
            }
            total_added += 1
            if total_added % 100 == 0:
                print(f"… {total_added} strings added", flush=True)
                save_cache(cache)

    save_cache(cache)
    CATALOG.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Done: {total_added} new locale entries in {len(strings)} keys")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
