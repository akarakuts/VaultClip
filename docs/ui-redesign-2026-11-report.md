# Отчёт: UI redesign VaultClip (U00–U37)

**Ветка:** `ui-redesign-2026-11`  
**Контакт:** Aleksey Karakuts — aleksey@karakuts.com  
**Дата:** 2026-11-20  
**Ветка на GitHub:** `ui-redesign-2026-11`. Релизный тег этой ветки не ставился.

## Гейты

| Проверка | Результат |
|---|---|
| Юнит-тесты Debug | **325** зелёных (`./scripts/run-unit-tests.sh`) |
| Покрытие (базовый ≥55%) | OK, min 57.39% (`HistoryItem+Image.swift`) |
| Покрытие strict Models/Panel ≥80% | OK, min 81.08% (`MenuBarModel.swift`) |
| Release build | **BUILD SUCCEEDED** |
| TSan (`VaultClip XCTest`, только VaultClipTests) | **TEST SUCCEEDED**, гонок в коде VaultClip не видно |
| SwiftLint `--lenient --baseline .swiftlint-baseline.yml` | 15 warnings, **0 errors** |

Production Application Support не трогался.

## Статус задач

| ID | Статус | Комментарий |
|---|---|---|
| U00 | DONE | Честный SwiftLint baseline |
| U01 | DONE | macOS 14.0 |
| U02 | DONE | PanelTheme / PanelChrome |
| U03 | DONE | PanelCommandRegistry + KeyChord |
| U04 | DONE | PanelKeyRouter / EscapeResolver / local monitor |
| U05 | DONE | ItemKind / PanelPresenter |
| U06 | DONE | Native chrome |
| U07 | DONE | Размер/позиция панели |
| U08 | требует ручной проверки | Модель/view шапки есть; IB search+tabs ещё в storyboard, filter bar вшит отдельно |
| U09 | требует ручной проверки | Presenter счётчика/подсказок есть; баннеры/тосты UI не полностью |
| U10 | DONE | ContentUnavailable-style host |
| U11 | DONE | HistoryRowView fixed height |
| U12 | DONE | lastUsedAt + группировка/retention |
| U13 | DONE | Type chips + токены |
| U14 | DONE | App filter + SourceAppDisplayName |
| U15 | DONE | Row action overlay на строке |
| U16 | DONE | SelectionModel + MultiPasteComposer в панели |
| U17 | DONE | Контекстное меню из реестра |
| U18 | DONE | PendingDeletionQueue + Esc flush |
| U19 | требует ручной проверки | DragOutPayload модель; drag UI не расширялся |
| U20 | DONE | ⌘0→10-й, политики открытия |
| U21 | DONE | Embedded preview, floating удалён |
| U22 | требует ручной проверки | ColorFormat/PreviewMetadata модели; richer preview UI частичный |
| U23 | требует ручной проверки | PasswordPrivacySurfaces + тест-инвариант; screen-capture hide в Settings |
| U24 | требует ручной проверки | EditBeforePaste модель; редактор в панели не вшит |
| U25 | DONE | ⌘K CommandPalette overlay |
| U26 | DONE | ⌘/ CheatSheet overlay |
| U27 | DONE | StatusItemClickMode |
| U28 | DONE | Pause icon / recents model |
| U29 | DONE | SettingsStore + programmatic toolbar tabs |
| U30 | DONE | SwiftUI Form вкладки (основные ключи) |
| U31 | DONE | Запись hotkey в Shortcuts tab |
| U32 | DONE | Excluded apps в Privacy tab |
| U33 | требует ручной проверки | Базовая a11y; полное VO-покрытие не аудитилось |
| U34 | требует ручной проверки | Новые строки en/ru; полный каталог языков — needs_review |
| U35 | DONE | 5k budget (+ ослабление под TSan runtime) |
| U36 | требует ручной проверки | `scripts/ui-preview.sh` есть; визуальный прогон не делался |
| U37 | DONE | docs/ui-guidelines.md + UIGuidelinesRegistryTests |

## Ручная проверка (осталось)

1. Визуально: шапка (U08), тосты/баннеры (U09), richer preview + edit-before-paste (U22–U24).
2. Сценарии панели: поиск и вставка, multi-paste, пароли, шпаргалка.
3. VoiceOver проход (U33).
4. Удаление legacy storyboard-сцен General/HotKey после полной уверенности в SwiftUI Settings.

## Заметки

- Срок хранения считается по `lastUsedAt` (отмечено в CHANGELOG).
- Старые AppKit Settings VC ещё в репозитории, но окно настроек создаётся программно на SwiftUI.
- Тесты: было ≥219, сейчас **325**.
