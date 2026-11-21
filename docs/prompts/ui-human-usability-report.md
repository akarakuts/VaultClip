# Отчёт: UI human usability

Contact: [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

## Проход 2 — 2026-11-21 (вечер)

Промпт: [ui-human-usability.md](ui-human-usability.md). Список трения до правок: `/tmp/vc-friction-list.md`.

### Какие шаги человека исчезли

- Esc при грязной правке: тост через каталог (`toast.edit_discard_armed`), без `ru ? … : …`.
- ⌘S в редакторе реально сохраняет правку в буфер (раньше аккорд глотался зоной editor); после ⌘S текст на экране не откатывается к оригиналу.
- Кнопка «Вставить правку» совпадает с глаголом реестра (`command.pasteEdit`).
- Превью текста / ссылки / файла: приложение, время копирования и размер — можно узнать элемент без вставки.
- Активный фильтр виден в счётчике («… · Текст · Safari»); в подвале при фильтре — подсказка «Сбросить фильтры».
- Плейсхолдер поиска на «Паролях» говорит про комментарий/логин/URL; `PanelHeaderPresenter` без `ru ? … : …`.
- Мёртвые IB-лейблы шапки убираются из иерархии; chrome metrics больше не перетягивают констрейнты колонки (владелец — programmatic layout).
- VoiceOver: поиск с label; кнопки PanelHeaderView с именами; иконки контекстного меню с title; удаление из denylist с accessibilityLabel; зазор 4pt между кнопками строки.

### Файлы

- Edit: `EmbeddedPreviewView.swift`, `HistoryViewController+Actions.swift`, `HistoryViewController.swift` (маршрутизация ⌘S/⌘⏎ в editor)
- Layout: `HistoryViewController+Layout.swift`, `HistoryPanelChromeConfigurator.swift`
- Preview/filter/header: `EmbeddedPreviewView.swift`, `FilterState.swift`, `PanelStatusBarModel.swift`, `PanelHeaderModel.swift`
- A11y: `PanelHeaderView.swift`, `HistoryRowView.swift`, `HistoryTableView+ContextMenu.swift`, `SettingsSwiftUITabs.swift`, `Accessibility.swift`, `L10n.swift`, `Localizable.xcstrings`
- Тесты: `PanelStatusBarPresenterTests`, `FilterStateTests`

### Проверено

- `scripts/ui-preview.sh` (демо) и `EMPTY=1 SKIP_BUILD=1` — панель поднимается на XCTest storage.
- `./scripts/run-unit-tests.sh` — **337** зелёных, `UIGuidelinesRegistryTests` в комплекте.
- Computer Use / полный VoiceOver-проход / TextEdit↔Return руками — **не выполнены**: нет Accessibility + Screen Recording для Cursor Computer Use.

### Сознательно не менялось / осталось

- Полная замена storyboard-шапки на `PanelHeaderView` (класс готов с a11y, в `HistoryViewController` ещё IB outlets `searchBar` / `itemGroupScrollView`).
- Шифрование, Keychain, denylist менеджеров паролей, production Application Support.
- Реестр команд и раскладка шорткатов.
- Коммит / push / релиз.

---

## Проход 1 — 2026-11-21

### Какие шаги человека исчезли

- На узкой панели подвал больше не отрезает «⏎ Вставить» с начала — обрезание с конца + презентер и так оставляет ведущую подсказку.
- Тост undo не закрывает нижнюю строку списка и не перехватывает клики по списку (только кнопка «Отменить»).
- Первый запуск не открывает справку сам после Accessibility; тексты Welcome идут через outlets/каталог, а не сравнение английских строк из xib.
- Пустые состояния, подвал, настройки, шпаргалка, палитра, даты и относительное время больше не ветвятся `ru ? … : …` — язык системы через `Localizable.xcstrings`.
- Цвет в превью: swatch + HEX/RGB/HSL + приложение/время — можно узнать цвет без вставки.
- Drag наружу: пароли не отдают содержимое; цвет уходит как HEX plain text.
- Копирование пароля показывает, через сколько секунд очистится буфер (если включено).

### Файлы

- Layout/toast: `HistoryViewController+Layout.swift`, `PanelToastView.swift`
- L10n: `L10n.swift`, `Localizable.xcstrings`, `PanelEmptyStateModel.swift`, `PanelStatusBarModel.swift`, `SettingsSwiftUITabs.swift`, `SettingsTabViewController.swift`, `EmbeddedPreviewView.swift`, `CheatSheetOverlayView.swift`, `CommandPaletteOverlayView.swift`, `DateGrouping.swift`, `RowPresentation.swift`
- Welcome: `WelcomeViewController.swift`, `Main.storyboard`
- Drag/color: `HistoryItem.swift`, `HistoryViewController+Layout.swift`, `HistoryViewController+Actions.swift`
- A11y: `ClipStatusItem.swift`, `HistoryRowView.swift`
- Тесты: `PanelEmptyStatePresenterTests`, `PanelStatusBarPresenterTests`, `DateGroupingCoverageTests`, `RowPresentationFormattingTests`, `PanelPresenterTests`, `RowPresentationCoverageTests`

### Проверено

- `scripts/ui-preview.sh` (демо) и `EMPTY=1` — панель поднимается на XCTest storage.
- `./scripts/run-unit-tests.sh` — **334** зелёных (на момент прохода 1).
- Computer Use / VoiceOver / TextEdit↔Return — не выполнены (те же внешние ограничения).
