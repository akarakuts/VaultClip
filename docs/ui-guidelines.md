# VaultClip UI guidelines

Contact: [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

## Principles

1. Zero extra steps for find-and-paste: open → type → Return.
2. Keyboard and mouse parity; every action is in the palette and menus.
3. Native macOS materials, SF Symbols, system fonts (monospace only as a setting).
4. Reversible deletes; Esc peels one layer.
5. Privacy by default for passwords.

## Tokens

See `PanelTheme` (`Spacing`, `Radius`, `TypeSizes`, materials, motion). Row height is fixed per text-size preference.

## Focus model

Zones: `search`, `list`, `preview`, `editor`, `palette`, `filters`. Local `NSEvent` monitor routes chords via `PanelCommandRegistry`; Carbon only for the global toggle.

## Esc stack

Palette → editor discard/leave → preview → filters → close panel.

## Shortcut table (registry)

| ID | Chord | Zones |
|---|---|---|
| togglePanel | ⌘⇧V (global) | — |
| paste | ⏎ | list, preview |
| pastePlainText | ⇧⏎ | list, preview |
| quickPaste1…9 | ⌘1…⌘9 | list, search, preview |
| quickPaste0 | ⌘0 | list, search, preview |
| copy | ⌘C | list, preview |
| commandPalette | ⌘K | everywhere |
| focusSearch | ⌘F | everywhere |
| togglePreview | ⌘Y / Space | list, search |
| quickLook | ⌥Space | list, preview |
| editBeforePaste | ⌘E | list, preview |
| toggleFavorite | ⌘D | list, preview |
| delete | ⌘⌫ | list, preview |
| undoDelete | ⌘Z | everywhere |
| selectNext / Previous | ↓ / ↑ | search, list |
| pageUp / pageDown | PgUp / PgDn | list, search |
| selectFirst / Last | ⌘↑ / ⌘↓ | list, search |
| selectAll | ⌘A | list |
| nextTab / previousTab | ⌃] / ⌃[ | everywhere |
| filterType* | ⌥⌘1… | everywhere |
| textSizeIncrease / Decrease | ⌘= / ⌘− | everywhere |
| cheatSheet | ⌘/ | everywhere |
| openSettings | ⌘, | everywhere |
| closePanel | Esc / ⌘W | everywhere |

The authoritative source is `PanelCommandRegistry`; this table must stay in sync (see `UIGuidelinesRegistryTests`).

## Mouse parity

Row hover overlay, context menu, header buttons, status-item click modes, and palette rows expose the same commands as chords.

## Privacy invariants

Password secrets never appear in row title/subtitle, VoiceOver labels, search haystacks, menu Recents, drag-out, or multi-paste without an explicit gated reveal.

## Performance budgets

Presenter + date grouping for 5 000 items < 200 ms in CI (`PerformanceBudgetTests`). Target scroll frame ≤ 16 ms (manual Instruments).

## Registry command IDs

- `togglePanel`
- `paste`
- `pastePlainText`
- `quickPaste1`
- `quickPaste2`
- `quickPaste3`
- `quickPaste4`
- `quickPaste5`
- `quickPaste6`
- `quickPaste7`
- `quickPaste8`
- `quickPaste9`
- `quickPaste0`
- `copy`
- `commandPalette`
- `focusSearch`
- `togglePreview`
- `quickLook`
- `editBeforePaste`
- `pasteEdit`
- `saveEdit`
- `toggleFavorite`
- `delete`
- `undoDelete`
- `openLinkOrFile`
- `revealInFinder`
- `selectNext`
- `selectPrevious`
- `selectFirst`
- `selectLast`
- `pageUp`
- `pageDown`
- `extendSelectionUp`
- `extendSelectionDown`
- `selectAll`
- `nextTab`
- `previousTab`
- `filterTypeAll`
- `filterTypeText`
- `filterTypeLinks`
- `filterTypeImages`
- `filterTypeFiles`
- `filterTypeColors`
- `filterApp`
- `clearFilters`
- `textSizeIncrease`
- `textSizeDecrease`
- `cheatSheet`
- `openSettings`
- `panelPositionLeft`
- `panelPositionRight`
- `panelPositionUp`
- `panelPositionDown`
- `closePanel`
