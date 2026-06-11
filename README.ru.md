# VaultClip

[![Release](https://img.shields.io/github/v/release/akarakuts/VaultClip)](https://github.com/akarakuts/VaultClip/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-10.15%2B-000000?logo=apple)](https://github.com/akarakuts/VaultClip)

**Ваш буфер обмена, наконец, под контролем.** VaultClip — менеджер истории копирования для macOS: мгновенный доступ к прошлым вставкам, избранное под рукой, пароли отдельно от общего потока — и всё это **зашифровано на диске**, без облака и без подписок.

Живёт в строке меню, открывается по **⌘⇧V**, не мешает работе. Скопировали сниппет, ссылку, скриншот или PDF — через секунду это уже в истории, с поиском и горячими клавишами **⌘0…⌘9**.

Форк open source проекта [Yippy](https://github.com/mattDavo/Yippy) (Matthew Davidson): сохранены лаконичный UX и идея «панель всегда рядом», а в VaultClip добавлены **AES-GCM**, фильтрация копий из менеджеров паролей, вкладки «Избранное» и «Пароли», актуальные тулчейны и открытая дорожная карта.

**Репозиторий:** [github.com/akarakuts/VaultClip](https://github.com/akarakuts/VaultClip) · **English:** [README.md](README.md)

<p align="center">
  <img src="images/screenshot-history.png" alt="VaultClip — вкладка «История»" width="78%">
</p>

<p align="center"><em>История, избранное и пароли — одна панель, три режима. Интерфейс на русском и английском.</em></p>

---

## Зачем VaultClip

| | |
|---|---|
| **Не терять контекст** | Код, цитата, URL, картинка — всё остаётся в локальной истории, пока вы не решите иначе. |
| **Не смешивать секреты с мусором** | Копии из 1Password, Bitwarden и других менеджеров **не попадают** в историю; свои пароли — во вкладку «Пароли». |
| **Не отдавать данные в облако** | История на вашем Mac, ключ в связке ключей macOS. Сеть приложение для хранения не использует. |

VaultClip не пытается заменить полноценный менеджер паролей — он **убирает хаос из буфера обмена** и даёт быстрый, предсказуемый доступ к тому, что вы реально копируете каждый день.

---

## Как это выглядит

### История — вся хронология под рукой

Текст, код, ссылки, цвета, изображения, PDF и файлы — в одном списке с иконкой приложения-источника и меткой времени. Повторное копирование того же содержимого не засоряет ленту.

<p align="center">
  <img src="images/screenshot-history.png" alt="Вкладка «История» — текст, код, ссылки, превью файлов" width="72%">
</p>

### Избранное — то, что нельзя потерять

Закрепите команды, SSH-строки, документацию, шаблоны. Избранное переживает обычную очистку истории и не вытесняется лимитом так же, как одноразовые копии.

<p align="center">
  <img src="images/screenshot-favorites.png" alt="Вкладка «Избранное» — закреплённые команды и ссылки" width="72%">
</p>

### Пароли — отдельно и аккуратно

Сохранённые записи: комментарий, логин и маскированный секрет. Поиск по комментарию и логину, копирование по ПКМ. В общей истории этих строк **нет**.

<p align="center">
  <img src="images/screenshot-passwords.png" alt="Вкладка «Пароли» — логин и маскированный пароль" width="72%">
</p>

---

## Возможности

### История буфера обмена

- **Фоновый мониторинг** системного pasteboard — каждая новая копия (кроме отфильтрованных источников) сохраняется локально.
- **До 5000 элементов** в модели; в настройках можно ограничить отображаемый размер (50–1500).
- **Типы данных:** текст, RTF, HTML, URL, цвета, растровые изображения, PDF, файлы с иконкой или превью.
- **Дедупликация** в пределах последних 20 элементов.
- **Иконка приложения-источника** и **метка времени** у каждой записи.

### Три вкладки

| Вкладка | Назначение |
|--------|------------|
| **История** | Полная хронология без избранного и сохранённых паролей. |
| **Избранное** | Закреплённые элементы; защищены от обычной очистки. |
| **Пароли** | Явно сохранённые секреты: комментарий, логин, `••••••••`. |

Избранное и сохранение в «Пароли» — через **контекстное меню** (ПКМ): добавить/убрать из избранного, сохранить в пароли, копировать логин/пароль, редактировать, удалить.

### Поиск, превью, вставка

- **Поиск** (⌘\\) — нечёткое сопоставление по тексту; для паролей — по комментарию и логину, не по секрету.
- **Превью** (Ctrl+Space) — текст, изображение или Quick Look; пароли маскируются вне вкладки «Пароли».
- **Return** — вставка в приложение, которое было активно до открытия панели.
- **⌘0 … ⌘9** — быстрая вставка по позиции в списке.
- **Перетаскивание** строк для сортировки; перенос наверх обновляет системный буфер.

### Панель и строка меню

Приложение **без иконки в Dock** — только в меню. Панель можно закрепить слева, справа, сверху, снизу, по центру или на весь экран; позиция запоминается. Переключение: меню **Position** или **Ctrl+Alt+⌘ + стрелки**.

В меню: **Показать/скрыть окно** (по умолчанию **⌘⇧V**), автозапуск, очистка истории, настройки, справка.

### Первый запуск и язык

При первом открытии — **Welcome** с запросом **Accessibility** (нужен для автоматической вставки ⌘V). Без него история работает, вставка по Return — нет.

Интерфейс на **русском** и **английском** (`Localizable.xcstrings`); язык следует системной локали.

---

## Безопасность и конфиденциальность

VaultClip проектируется как **локальное хранилище**, а не сервис с аккаунтом.

### Шифрование на диске

- Содержимое элементов — **AES-GCM** (CryptoKit, ключ 256 бит), формат `VC1` + sealed box.
- Ключ в **связке ключей macOS** (`com.karakuts.VaultClip` / `history-data-key`), `AfterFirstUnlockThisDeviceOnly`, без iCloud sync.
- Метаданные (избранное, флаги пароля, комментарий, логин, время, bundle id) шифруются тем же слоем.
- Старые незашифрованные файлы читаются и перешифровываются при записи; миграция с Yippy и ранних VaultClip — автоматически.

### Защита от утечек

- Каталог истории: `~/Library/Application Support/com.karakuts.VaultClip/history/` с правами **0700**.
- Проверка путей на symlink; санитизация имён типов pasteboard.
- **Denylist** bundle id менеджеров паролей (1Password, LastPass, Bitwarden, Dashlane, Keeper, Apple Passwords, Proton Pass и др.) и служебных типов pasteboard.
- **Hardened Runtime**; ATS без произвольных HTTP-загрузок. Приложение не обращается к сети за историей.

### Разрешения macOS

| Разрешение | Зачем |
|------------|--------|
| **Универсальный доступ** | Однократная симуляция ⌘V в активное приложение. Логирование нажатий не ведётся. |
| **Связка ключей** | Ключ AES при подписи Developer ID. Ad-hoc-сборки — fallback на `.history-encryption-key` (0600). |

Удаление записи `history-data-key` в Keychain **необратимо ломает** расшифровку существующей истории.

---

## Горячие клавиши

| Сочетание | Действие |
|-----------|----------|
| **⌘⇧V** (по умолчанию) | Открыть / закрыть панель |
| **↑ / ↓**, **Page Up / Down** | Навигация по списку |
| **Return** | Вставить выбранное |
| **Esc** | Закрыть панель |
| **⌘0 … ⌘9** | Вставить по индексу |
| **Ctrl+Delete** | Удалить выбранное |
| **Ctrl+Space** | Превью вкл/выкл |
| **⌘\\** | Фокус в поиск |
| **Ctrl+[** / **Ctrl+]** | Предыдущая / следующая вкладка |
| **Ctrl+Alt+⌘←→↑↓** | Позиция панели на экране |

Горячую клавишу открытия можно сменить в **Preferences → Hot Key**.

---

## Установка

### Как установить

| Способ | Стоимость | Кому подходит |
|--------|-----------|---------------|
| **Сборка из исходников** (ниже) | Бесплатно | Вам на своём Mac — рекомендуется без [Apple Developer Program](https://developer.apple.com/programs/) (99 USD/год) |
| **DMG из [релизов GitHub](https://github.com/akarakuts/VaultClip/releases)** | Бесплатно скачать | Быстрая проверка; при ad-hoc-подписи может понадобиться обход Gatekeeper |
| **Подписанный и нотаризованный DMG** | 99 USD/год программа Apple | Установка на любой Mac без предупреждений — нужен сертификат **Developer ID Application** |

Бесплатного аналога **Developer ID** у Apple нет; open source не отменяет плату. Без программы VaultClip всё равно можно пользоваться — **собрав локально** или приняв предупреждения macOS для неподписанного/ad-hoc DMG.

### Быстрая сборка (для себя, бесплатно)

Нужно: **Xcode**, **macOS 10.15+**, **CocoaPods** (`gem install cocoapods` или `brew install cocoapods`).

```bash
git clone https://github.com/akarakuts/VaultClip.git
cd VaultClip
pod install
VAULTCLIP_SIGN_RELEASE=1 ./build-dmg.sh
./install-app.sh VaultClip.app
open /Applications/VaultClip.app
```

`VAULTCLIP_SIGN_RELEASE=1` подписывает **Developer ID Application**, если он есть в связке ключей; иначе — **Apple Development** (Xcode создаёт его на вашем Mac). Оба варианта надёжнее ad-hoc для **Универсального доступа** (вставка в другие приложения).

Без подписи (быстрее, Accessibility часто нестабилен):

```bash
./build-dmg.sh
./install-app.sh VaultClip.app
```

### Установка в Программы

Всегда ставьте в **`/Applications`** — не с тома DMG и не перетаскиванием из папки репозитория (macOS сбрасывает Accessibility при смене пути).

```bash
./install-app.sh VaultClip.app
# или после build-dmg.sh:
./install-app.sh dmg-staging/VaultClip.app
```

Скрипт использует `ditto --norsrc` и по возможности сохраняет подпись.

### Первый запуск

1. **Welcome** может запросить **Универсальный доступ** — нужен для вставки по Return (симуляция ⌘V). История работает и без него; автоматическая вставка — нет.
2. **Системные настройки → Конфиденциальность и безопасность → Универсальный доступ** — включите **VaultClip** один раз. Удалите дубликаты/старые записи после переустановки с другого пути.
3. По желанию: **Запускать при входе** в меню строки состояния.

### Подпись кода

| Режим | Команда | Accessibility | Чужие Mac |
|-------|---------|---------------|-----------|
| **Ad-hoc** | `./build-dmg.sh` | Часто ломается | Gatekeeper блокирует |
| **Apple Development** | `VAULTCLIP_SIGN_RELEASE=1 ./build-dmg.sh` | Обычно ок на **вашем** Mac | Не для раздачи |
| **Developer ID** | То же + сертификат в Keychain / секреты CI | Ок | Ок после нотаризации |

Логика подписи: `codesign-app.sh` (Hardened Runtime; entitlements Keychain — только с Developer ID).

### Если macOS блокирует приложение (Gatekeeper)

Типично для ad-hoc или Apple Development DMG на Mac, где приложение не собирали:

```bash
xattr -cr /Applications/VaultClip.app
```

Или ПКМ по **VaultClip.app** → **Открыть** → подтвердить один раз. Надёжнее — **собрать из исходников** на этом же Mac.

### Сборка из исходников (пошагово)

1. **Клонировать** репозиторий (см. быструю сборку выше).
2. **Зависимости:** `pod install` — дальше работать с `VaultClip.xcworkspace`, не с `.xcodeproj`.
3. **Схемы Xcode:**
   - **VaultClip** — релизное приложение;
   - **VaultClip Beta** — бета-сборка;
   - **VaultClip XCTest** — unit- и UI-тесты.
4. **DMG одной командой:** `./build-dmg.sh` (см. таблицу подписи).
5. **Ручная сборка** (без скрипта DMG):

```bash
xcodebuild -workspace VaultClip.xcworkspace -scheme VaultClip -configuration Release \
  -destination 'platform=macOS' -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
COPYFILE_DISABLE=1 ditto --norsrc DerivedData/Build/Products/Release/VaultClip.app VaultClip.app
VAULTCLIP_SIGN_RELEASE=1 ./codesign-app.sh VaultClip.app
./install-app.sh VaultClip.app
```

6. **Тесты:**

```bash
xcodebuild -workspace VaultClip.xcworkspace -scheme VaultClip XCTest \
  -destination 'platform=macOS' -derivedDataPath DerivedData test
```

Для UI-тестов включите Универсальный доступ для процесса тестов в системных настройках.

### Публичные релизы (Developer ID, по желанию)

Чтобы DMG с GitHub ставился на **любой** Mac без предупреждений: оформите [Apple Developer Program](https://developer.apple.com/programs/), создайте **Developer ID Application**, экспортируйте `.p12` и добавьте секреты репозитория:

| Секрет | Содержимое |
|--------|------------|
| `MACOS_CERTIFICATE_P12` | Base64 экспорта **Developer ID Application** `.p12` |
| `MACOS_CERTIFICATE_PASSWORD` | Пароль от `.p12` |
| `APPLE_ID` | Email Apple ID (нотаризация, опционально, но рекомендуется) |
| `APPLE_APP_SPECIFIC_PASSWORD` | Пароль приложения с [appleid.apple.com](https://appleid.apple.com) |
| `APPLE_TEAM_ID` | Team ID из аккаунта разработчика |

```bash
# Связка ключей → Мои сертификаты → Developer ID Application → Экспорт → .p12
base64 -i DeveloperID.p12 | pbcopy   # вставить в MACOS_CERTIFICATE_P12
```

Workflow **Release** (тег `v*`) импортирует сертификат, подписывает с Hardened Runtime + Keychain entitlements и нотаризует DMG при заданных секретах Apple ID.

### После переустановки

Снова включите VaultClip в **Системные настройки → Конфиденциальность и безопасность → Универсальный доступ**. Используйте `./install-app.sh` или `ditto --norsrc` — не копируйте `.app` из дерева сборки перетаскиванием в Finder.

---

## Куда движется проект

VaultClip — **активный форк с открытым кодом** (GPLv3). База Yippy дала проверенный UX «панель у края экрана»; дальше — развитие как **безопасного локального слоя** между macOS и вашими данными в буфере.

**Уже сделано:** шифрование AES-GCM, вкладки «Избранное» и «Пароли», фильтрация менеджеров паролей, RU/EN локализация, миграции с Yippy, Hardened Runtime, CI с подписью Developer ID.

**В перспективе** (по приоритету сообщества и issues):

- синхронизация **только по вашему выбору** — локальная сеть или зашифрованный том, без обязательного облака;
- расширяемые правила фильтрации и теги для длинной истории;
- улучшения доступности и **App Sandbox** при сохранении вставки через Accessibility;
- виджеты и быстрые действия для частых сценариев (сниппеты, markdown, devops-команды).

Идеи, баги и pull request'ы приветствуются: [issues](https://github.com/akarakuts/VaultClip/issues) · [pull requests](https://github.com/akarakuts/VaultClip/pulls).

### Для разработчиков

- `VaultClip/Sources/` — код приложения;
- `VaultClip/Sources/Models/Security/` — Keychain, AES-GCM, миграции;
- `VaultClipTests/` — unit-тесты; `VaultClipUITests/` — UI-тесты.

---

## Лицензия

**GNU General Public License v3.0 или новее** (GPL-3.0-or-later). Текст — в [LICENSE](LICENSE).

Форк [Yippy](https://github.com/mattDavo/Yippy) (Matthew Davidson), изначально MIT. К VaultClip в целом применяется GPLv3. Зависимости CocoaPods — под своими лицензиями.

---

## Контакты

**Aleksey Karakuts** — [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

Copyright (C) 2019 Matthew Davidson; Copyright (C) 2026 Aleksey Karakuts &lt;aleksey@karakuts.com&gt;. Лицензия: GPLv3 или новее.
