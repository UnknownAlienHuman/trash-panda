# TrashPanda agent guide

## Start here

Read [`TrashPanda.toc`](TrashPanda.toc), then [`Core/Namespace.lua`](Core/Namespace.lua), [`Core/Bootstrap.lua`](Core/Bootstrap.lua), [`Core/Config.lua`](Core/Config.lua), and [`Feature/AutoSell.lua`](Feature/AutoSell.lua). The TOC order is the architecture: namespace/locale/config/logger/format -> features -> Settings/Bootstrap -> [`Init.lua`](Init.lua).

TOC release metadata is `0.2.8` (`TrashPanda.toc`, `## Version`); `Core/Namespace.lua` still exposes runtime constant `0.2.3` (see the uncertainty note below).

## Load order and execution path

Complete `loadedFiles` inventory (root `docs/addon-architecture.json`, in execution order):

```text
Core/Namespace.lua
Core/Locale.lua
Core/Config.lua
Core/Logger.lua
Util/Format.lua
Feature/AutoSell.lua
Feature/FasterLoot.lua
Core/Settings.lua
Core/Bootstrap.lua
Init.lua
```

`Init.lua` calls `TP.Bootstrap:Init()`. Bootstrap registers one frame for `ADDON_LOADED`, `MERCHANT_SHOW`, and `PLAYER_MONEY`. On the addon's `ADDON_LOADED`, it loads `TrashPandaDB` defaults, applies saved locale, initializes logger and AutoSell state, registers Settings and FasterLoot, and installs `/tp` and `/trashpanda`. `MERCHANT_SHOW` routes to `TP.AutoSell:OnMerchantShow`; `PLAYER_MONEY` feeds delayed finalization through `TP.AutoSell:OnPlayerMoney`. `FasterLoot` owns a separate `LOOT_READY` frame and only acts when `fasterLoot` is enabled.

AutoSell flow: `OnMerchantShow` (Shift bypass/re-entry/API checks) -> `_BuildQueue` scans bags 0 through reagent bag and selects poor items with value -> ticker `_Tick` sells unlocked entries with `UseContainerItem` -> `_StartWaitingForMoney` waits for money update/stability -> `_Finalize` records delta, formats chat summary and resets state.

## State and surfaces

- SavedVariables: `TrashPandaDB` with `printSummary`, `bypassShift`, `debug`, `fasterLoot`, and `locale`; AutoSell runtime state/log buffer are not persisted.
- Settings category: summary, Faster Looting, locale (`enUS`, `ruRU`, `deDE`, `esES`, `zhCN`, `zhTW`), and debug. `bypassShift` is currently a default/code path, not exposed by `Settings.lua`.
- Slash: `/tp` or `/trashpanda`; `status`, `debug on|off`, `log`, `help`. There is no implemented `/tp on|off` despite some locale/help text mentioning it.
- Localization: `TP.L` from [`Core/Locale.lua`](Core/Locale.lua); `esMX` inherits `esES`.

## Dependencies and relationships

No TOC external dependency. Uses Blizzard merchant/container/loot/money/settings APIs. `AutoSell` uses modern `C_Container` with fallback globals and `Enum.ItemQuality.Poor`; `FasterLoot` uses `LOOT_READY`, `GetCVarBool`, `IsModifiedClick`, `GetNumLootItems`, and `LootSlot`. No checked-in addon consumes TrashPanda globals.

Falsification notes: there is no `COMBAT_LOG_EVENT_UNFILTERED`, Masque, CDM, or addon-wide `OnUpdate` path. Timing is handled by the AutoSell/FasterLoot timer callbacks and event frames; do not document TrashPanda as a per-frame scanner.

## Change routing

- Namespace/version and shared TP table: [`Core/Namespace.lua`](Core/Namespace.lua).
- Defaults and DB reads/writes: [`Core/Config.lua`](Core/Config.lua), then Settings callbacks in [`Core/Settings.lua`](Core/Settings.lua).
- Event lifecycle/slash: [`Core/Bootstrap.lua`](Core/Bootstrap.lua), `TP.Bootstrap:Init`, local `OnSlash`.
- Sell criteria/queue/tickers/money reconciliation: [`Feature/AutoSell.lua`](Feature/AutoSell.lua), `IsSellablePoor`, `TP.AutoSell:OnMerchantShow`, `_BuildQueue`, `_Tick`, `_StartWaitingForMoney`, `_Finalize`.
- Optional loot behavior: [`Feature/FasterLoot.lua`](Feature/FasterLoot.lua), `OnLootReady`.
- User text and language: [`Core/Locale.lua`](Core/Locale.lua); logging: [`Core/Logger.lua`](Core/Logger.lua); output formatting: [`Util/Format.lua`](Util/Format.lua).

## Invariants and risks

- Only poor-quality, non-zero-value items are eligible. Preserve `info.quality == POOR_QUALITY` and `not info.hasNoValue` checks.
- AutoSell is re-entry protected and must not sell while a slot is locked; retain retry cap (`MAX_LOCK_RETRIES = 20`) and timer cancellation.
- Money finalization intentionally waits for a post-sale money change and 0.35 s stability, with a 20 s failsafe. Do not report the summary immediately after the last `UseContainerItem`.
- `UseContainerItem` is a protected/economic action surface. Verify merchant/combat/Shift behavior and never broaden target selection silently.
- `Settings.SetOnValueChangedCallback` updates Config and logger/locale but does not reinitialize active feature state; if adding settings, route effects explicitly.
- Logger is a 200-entry ring buffer; `SwingBarMidnightDebuggerDB`-style unbounded persisted logs must not be introduced.

## Verification

1. Verify TOC order and all file references; parse Lua.
2. In-game `/reload`; test `/tp help`, `status`, `debug on|off`, and `log`.
3. At a merchant, test gray item stacks, locked slots, empty queue, Shift bypass, merchant close, delayed `PLAYER_MONEY`, repair/buy delta mismatch, and 20 s failsafe.
4. Test Settings persistence for summary, Faster Looting, locale, and debug; confirm locale fallback and chat strings.
5. Enable Faster Looting and test `LOOT_READY` with auto-loot CVar/modifier combinations.
6. Check no unintended sale, Lua error, protected-action/taint error, or stale ticker after reload/merchant close.

## Uncertain or stale claims

`TrashPanda.toc` reports version `0.2.8`, while `Core/Namespace.lua` sets `TP.version = "0.2.3"`; treat the TOC as the release version and the namespace value as a stale runtime constant until reconciled. Locale help strings mention `/tp on|off`, but `Bootstrap.lua` implements only help/status/log/debug. `README.md` previously called Shift bypass configurable; the current Settings UI does not expose `bypassShift`. Reconciliation is tracked in [GitHub issue #2](https://github.com/UnknownAlienHuman/trash-panda/issues/2).
