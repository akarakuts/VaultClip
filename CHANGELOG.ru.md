# История изменений

Здесь фиксируются все заметные изменения **VaultClip**.

Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/); версии следуют [семантическому версионированию](https://semver.org/lang/ru/).

При релизе переносите пункты из **Unreleased** в раздел с датой и номером версии.

**English:** [CHANGELOG.md](CHANGELOG.md)

---

## [Unreleased]

## [2.4.0] — 2026-11-22

[Релиз](https://github.com/akarakuts/VaultClip/releases/tag/v2.4.0)

### Интерфейс

- Ветка редизайна `ui-redesign-2026-11` (U00–U37): нативный chrome панели, фиксированная высота строк, фильтры по типу/приложению и токены в поиске, группы по дате, кнопки действий на строке, мультивыделение и мульти-вставка, обратимое удаление, встроенное превью, палитра ⌘K / шпаргалка ⌘/, режимы клика по значку меню, вкладки настроек на SwiftUI (`SettingsStore`), пустые состояния.
- Клавиши: ⌘1…⌘9 / ⌘0 (десятая), ⌘F поиск, ⌘Y/пробел превью (без ⌃Space), ⌘K палитра, ⌘/ шпаргалка.
- Оформление панели: системное, светлое, тёмное или Liquid Glass (на текущей macOS — HUD-материал, пока нет публичного стекла). «Уменьшить прозрачность» по-прежнему даёт сплошной фон.
- Запрос поиска сбрасывается крестиком в поле или кнопкой пустого результата; активные фильтры типа и приложения — кнопкой в подвале.
- Срок хранения (T34) учитывает `lastUsedAt`, когда поле заполнено.

### Добавлено

- **LogStorage** — при запуске выставляет режим **0600** для `error.log`/`warning.log` и ротирует их выше ~2 МБ (хвост сохраняется); опциональный диагностический лог ротируется только пока включён.
- **Диагностика pasteboard по запросу** — запуск с `--pasteboard-diagnostics` пишет счётчики изменений и метаданные (не содержимое буфера) в `pasteboard-debug.log`.
- **Обратимое percent-encoding имён файлов типов pasteboard** (`SecureStorageHelper.sanitizedPasteboardFileName` / `pasteboardType(fromStoredFileName:)`) — кодируются `%`, `/`, `:` и имена из одних точек; старые имена на диске по-прежнему декодируются в те же типы.
- **Проверка шифрования при запуске** (`HistoryEncryptionProbe`) — обнаруживает данные, которые текущий ключ не расшифровывает, и ведёт пользователя через сброс ключа вместо тихой потери истории.
- **Асинхронная загрузка истории** — `History.loadAsync` / `State.isHistoryLoaded`; панель открывается сразу, пока идёт сканирование шифрованных файлов, показывается локализованное «Загрузка истории…».
- **Затвор pasteboard на время загрузки** — `PasteboardMonitor.historyReady(liveChangeCount:)` догоняет копии, сделанные пока история грузилась.
- **Сгруппированная запись `order.xml`** — вставки/перемещения батчатся в одну запись на диск (~1 с); удаления, reduce и clear сбрасывают сразу; при `applicationWillTerminate` — синхронный drain (таймаут 1.5 с).
- **Флаг `pastesRichText` на элементе** — вставка/перемещение отдают RTF/HTML по настройке, зафиксированной в момент копирования.
- Unit-тесты выросли со **99 до 219+** — укрепление логов, encode/decode хранилища, контракт AES-GCM, шифрование `DataFileManager`, probe, семантика async load, coalescing порядка, затвор pasteboard, shared settings, матрица `KeyResolver`, round-trip Keychain, accessibility, каталог L10n, retention/dedup/hotkey.

### Безопасность

- **Скрытое копирование паролей** — copy/paste пароля использует `org.nspasteboard.ConcealedType` и `.currentHostOnly`, чтобы другие менеджеры буфера и Universal Clipboard не перехватывали секрет (`PasteboardWriter`).
- **Карантин нерасшифровываемой истории** — элементы с ошибкой AES-GCM переезжают в `quarantine/` вместо удаления; выбор ключа оценивает несколько образцов payload (T04).

### Изменено

- **Нумерация быстрой вставки** — ⌘1…⌘9 вставляют строки 1–9; ⌘0 — десятую (раньше была первой). Бейджи в `PanelPresenter` согласованы (U20).
- **Минимальная macOS** — **14.0**; автозапуск только через SMAppService; убран legacy `LSSharedFileList` / LoginServiceKit (U01).
- **Срок хранения истории** — по `lastUsedAt` (fallback на `copiedAt`); paste/promote обновляют `lastUsedAt` (U12).
- **I/O HistoryCache** — расшифровка вне lock кэша; пустой LRU больше не блокирует поток (T21).
- **Автозапуск** — SMAppService с алертом и переходом в Настройки (T20; путь macOS 12 убран в U01).
- **Вставка с учётом раскладки** — симуляция ⌘V берёт keycode «v» для текущей клавиатуры (T19).
- **Агрегация алертов** — не чаще одного модального окна за 30 с с счётчиком и действием «открыть папку логов» (T18).
- **Декод настроек** — отсутствующие поля → значения по умолчанию; битый JSON бэкапится в `settings.corrupt-backup` (T17).
- **Ротация логов** — error/warning всегда ротируются выше 2 МБ; новые файлы с 0600; запись Logger на serial queue (T16).
- **Очистка буфера при удалении** — pasteboard сбрасывается только если удалённый элемент сейчас в буфере (T15).
- **Гонка записи order** — снимки очереди обновляют pending state синхронно, чтобы поздний flush с main не затёр удаление/вставку (T14).
- **Потоки History** — `loadHistory` возвращает `[HistoryItem]`; кэш и мутации History на main; `_unsavedData` и кэш ключа под lock (T13).
- **zeroize в кэше** — убраны неэффективные CoW-вызовы из HistoryCache (T12).
- **URL-схемы паролей** — открываются только http/https (T11).
- **Миграция открытого plaintext** — при загрузке перешифровка; успешный merge legacy App Support уводит старую папку в Корзину (T10).
- **Изоляция Beta-хранилища** — свой Application Support / Keychain / instance.lock; первый запуск Beta с пустой историей (T09).
- **Library validation** — убран `disable-library-validation` из entitlements; SPM-зависимости статически (T08).
- **Временные файлы Quick Look** — PDF в 0700/0600 temp store, удаление при закрытии превью, clear-all, launch, quit (T07).
- **Закрытие панели при деактивации** — при уходе в другое приложение; модальные диалоги приостанавливают правило (T06).
- **Горячие клавиши панели** — ⌘\ и остальные сочетания регистрируются только пока открыта панель истории (T05).
- **Изоляция тестов** — XCTest host и UI tests используют временный `StorageRoot`, не боевой `~/Library/Application Support/com.karakuts.VaultClip`.
- **Минимальная macOS** поднята до **12.0**, затем **14.0** (U01); сняты лишние `#available`.
- **Порог покрытия** — min по файлам Security/History (55%); обоснование исключений в шапке `check-coverage.sh`.
- **CI** — SwiftLint **0.65.1** с релиз-артефакта; проверка `MARKETING_VERSION`.
- **Локализация** — PDF/картинки и «загрузка истории» в каталоге; accessibility id в настройках (T35).
- **Accessibility** — метки ячеек для VoiceOver; маска паролей (T36).
- **Cleanup** — удалены мёртвые хелперы; id у пункта меню Preferences (T37).
- **DI** — history/preview/settings через live providers вместо устаревших снимков (T38).
- **KeyResolver** — выбор ключа AES с unit-tested матрицей (T39).
- **CI** — job TSan; release workflow + lint; actions по SHA (T40).
- **Исключённые приложения** — denylist bundle id в Privacy (T33).
- **Retention** — автоудаление старше 1/7/30/90 дней (T34).
- **Вставка plain text** — ⇧Return (T32).
- **Пауза захвата** — меню + иконка (T31).
- **Автоочистка буфера после пароля** (T30).
- **Password access gate** — Touch ID / пароль системы + grace period (T29).
- **Подтверждение уменьшения лимита истории** (T28).
- **Валидация hot key** (T27).
- **Лимит размера элемента** (T26).
- **Отслеживание экрана панели** без опроса мыши 5 Гц (T25).
- **Кэш высоты ячеек** (T24).
- **Дедуп по digest** SHA-256 (T23).
- **SearchIndex** — поиск вне main thread (T22).
- `Settings.bootstrapOverride` → `Settings.shared`; `SettingsPersistence` без bootstrap в тестах.
- Активация приложения через `AppActivation` (macOS 14+ / legacy API).
- Атомарная запись метаданных; ошибка одного элемента не валит весь batch.
- Poll pasteboard 0.05→0.25 с после тишины; сброс при активности.
- Удалён мёртвый код; тип DnD `com.karakuts.VaultClip.history-item-id`.
- `docs/architecture.md`, `README.md`, `README.ru.md` — инварианты потоков, диагностика, coverage, тесты.

### Исправлено

- Действия панели (paste, move to top, delete) не перезаписывают буфер собственными записями (guard change count).
- Пароли не занимают string cache.
- Clear history / меню доходят до видимого `HistoryViewController`; превью с иконкой-предупреждением при битой картинке.
- Пустой список различает «ещё грузится» и «ещё ничего не копировали».

---

## [2.3.1] — 2026-06-19

### Добавлено

- **SettingsPersistence** — единый путь записи настроек.
- **AppRouting** — протокол навигации (popover, welcome/help).
- **PasteboardChangeTracking** — протокол для мониторов и моков.
- **VaultClipTestSupport** — восстановление `AppEnvironment` после тестов.
- **SettingsPersistenceTests**.
- **SwiftLint baseline** (`.swiftlint-baseline.yml`).

### Изменено

- **AppEnvironment.routing** — composition root вместо `State.main` / `Controller.main`.
- **HistoryViewController** — `configure(state:settings:)`; `appState`.
- **Settings** / **State** — записи через `SettingsPersistence.apply`.
- **check-coverage.sh** — исправлен парсинг xccov.
- **README.md** / **README.ru.md** — CI, `instance.lock`.
- Unit-тестов: **99** (стабильный прогон).

### Исправлено

- **HistoryFileManagerTests** — мок FS не течёт на реальные пути в CI.

---

## [2.2.0] — 2026-06-19

### Добавлено

- **ClipErrorCode** — стабильные коды NSError.
- **HistoryPasteboardPolicy** — denylist менеджеров паролей и фильтрация типов.
- **HistoryPanelChromeConfigurator** — вынесены layout/типографика панели.
- **docs/architecture.md**.
- **SwiftLint** и шаг в CI.
- **CI unit tests** — `scripts/run-unit-tests.sh`.
- Тесты error codes, pasteboard policy, single-instance lock.

### Изменено

- **AppEnvironment** вместо неявных синглтонов.
- **HistoryFileManaging** для `History`.
- **Coverage gate** 55% для Security + History.
- **HistoryViewController+Delegates.swift**.
- **ClipErrorCode** вместо `code: 0`.

---

## [2.1.2] — 2026-06-17

### Исправлено

- **Автозапуск** больше не завершает уже запущенное приложение; `SingleInstanceGuard`, SMAppService (13+), legacy login item на старых системах.

### Добавлено

- **CHANGELOG.md** — история версий; ссылки в README.

---

## [2.1.1] — 2026-06-17

[Релиз](https://github.com/akarakuts/VaultClip/releases/tag/v2.1.1)

### Изменено

- **CocoaPods** → **Swift Package Manager** (RxSwift 5.0.0, HotKey).
- Вендорные **Default** и **LoginServiceKit** в таргете приложения.
- Удалён `Pods/`; открывать `VaultClip.xcodeproj`.
- CI и `build-dmg.sh` — сборка через `-project`.

### Добавлено

- `Package.resolved` для SPM.

---

## [2.0.2] и ранее

Релиз **2.0.2** — последний тег до сброса истории репозитория к одному корневому коммиту (июнь 2026). Более ранняя работа — AES-GCM, вкладки «Избранное» и «Пароли», фильтрация менеджеров паролей, локализация, форк Yippy — в том снимке и в форках [Yippy](https://github.com/mattDavo/Yippy).

Старые теги и бинарники: [GitHub Releases](https://github.com/akarakuts/VaultClip/releases) или сборка до сброса по `git reflog`.

---

## Сопровождение

Обновляйте этот файл **вместе** с пользовательскими изменениями в `README.ru.md` / `README.md` (возможности, установка, безопасность, клавиши). README — путеводитель по продукту; **CHANGELOG** — дельта по версиям.

Парный файл на английском: [CHANGELOG.md](CHANGELOG.md).