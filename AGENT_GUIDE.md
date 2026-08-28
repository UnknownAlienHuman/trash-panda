# TrashPanda agent guide

## Current contract

- Repository: `UnknownAlienHuman/trash-panda`, branch `main`
- Target: World of Warcraft Retail / Midnight 12.1.0
- Interface: `120100`
- Release: `0.3.0`
- Author: Neomorph
- External libraries: none
- Shared policy: [`UnknownAlienHuman/wow-addon-engineering-kb`](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)
- Platform snapshot used for the 0.3.0 migration: `Gethe/wow-ui-source@027d26c3406d3de2cbd2b1f67d468fe033a1bcd4`, build `12.1.0.69497`

Read `TrashPanda.toc`, then `ARCHITECTURE.md`, `Core/Bootstrap.lua`, `Feature/AutoSell.lua`, `Feature/FasterLoot.lua`, and `Core/Settings.lua` before changing behavior.

## Load order

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

The TOC order is the dependency graph. `Init.lua` only calls `TP.Bootstrap:Init()`.

## AutoSell path

```text
MERCHANT_SHOW
  -> enabled gate
  -> optional Shift bypass
  -> API/re-entry gates
  -> snapshot GetMoney
  -> _BeginPass
     -> _BuildQueue over player bags
     -> poor quality + hasNoValue == false
     -> request missing item data
     -> paced _Tick
        -> re-read current bag/slot
        -> require same itemID
        -> require poor + value + unlocked
        -> C_Container.UseContainerItem
     -> delayed bounded rescan/backoff
  -> _StartWaitingForMoney
  -> PLAYER_MONEY + stability window
  -> _Finalize / FormatAmount / optional summary

MERCHANT_CLOSED
  -> cancel sale/retry workers
  -> bounded money reconciliation only
```

A queued bag/slot is never trusted as identity. Any empty, changed, unknown, non-poor, no-value, or locked location is not used. A changed sellable item may be discovered only by a later fresh scan.

## Why the native sell-all API is not used

`C_MerchantFrame.SellAllJunkItems()` exists in the current generated API and Blizzard's merchant button calls it. It is nevertheless not the safe TrashPanda path while [WoWUIBugs #488](https://github.com/Stanzilla/WoWUIBugs/issues/488) remains unresolved/current-build unverified: the report states that one poor-quality item without vendor value can abort the operation with “The merchant doesn't want that item” instead of being skipped.

Current 12.1 field code also reports one-shot incompleteness from rate limiting or initially uncached item data. TrashPanda therefore uses explicit filtering, paced calls, fresh rescans, 0.40–1.60-second backoff, a 12-pass cap, and a 3-stall cap. This is a bounded workaround, not permission to create an unbounded bag worker.

Do not replace the manual path merely because the native symbol exists. Re-test the exact no-value and many-item cases on the named live build, update the engineering KB issue, then simplify only when the retirement gate is met.

## Faster Loot path

`Feature/FasterLoot.lua` registers `LOOT_READY`. It acts only when both `TrashPandaDB.fasterLoot` and the event's documented `autoloot` payload are true. Do not recompute this state from CVars/modifier keys unless a current platform regression is demonstrated.

## Configuration and commands

SavedVariables:

```text
enabled
printSummary
bypassShift
fasterLoot
locale
debug
```

Settings variables are globally unique `TRASHPANDA_*` identifiers. The second identifier supplied to `Settings.RegisterAddOnSetting` is the internal `TrashPandaDB` key.

Commands:

```text
/tp on
/tp off
/tp status
/tp debug on|off
/tp log
/tp help
```

`TP.version` must continue to come from TOC metadata through `C_AddOns.GetAddOnMetadata`; do not duplicate a handwritten runtime version constant.

## Invariants

- AutoSell is enabled by default and may be disabled without disabling the addon.
- Holding Shift skips only the current merchant opening when `bypassShift` is enabled.
- Target selection remains exactly poor quality plus `hasNoValue == false`.
- Bag/slot, item ID, quality, value flag, and lock state are re-read immediately before every `UseContainerItem` call.
- Merchant state comes from `MERCHANT_SHOW` / `MERCHANT_CLOSED`, not `MerchantFrame:IsShown()`.
- Sale passes, lock retries, item-data retries, backoff, and money reconciliation are all bounded.
- No addon-wide `OnUpdate`, global frame scan, bag-button hook, native sell-all call, or persisted raw log.
- Logger storage remains bounded to 200 runtime entries.
- Debug and the runtime locale selection apply immediately; already-rendered Settings labels refresh after reload. All other Settings values are read at the point of use.
- No in-game result may be claimed from source review or offline parsing alone.

## Verification

Offline:

1. Parse every TOC-loaded Lua file as Lua 5.1-compatible syntax.
2. Confirm every TOC path exists and load order matches this guide.
3. Confirm Interface `120100` and version `0.3.0`.
4. Confirm the exact point-of-use checks: `itemID`, poor quality, `hasNoValue == false`, and unlocked.
5. Confirm `C_MerchantFrame.SellAllJunkItems` and `MerchantFrame:IsShown()` are absent from the live AutoSell path.
6. Confirm pass/stall/lock/money workers have explicit caps and cancellation paths.
7. Confirm all Settings IDs are prefixed `TRASHPANDA_` and all localized status strings accept two values.

In client:

1. Fresh login and `/reload` with only TrashPanda enabled.
2. Test `/tp help`, `on`, `off`, `status`, `debug on|off`, and `log`.
3. Open a merchant with no junk, one junk stack, many junk entries, Shift held, and AutoSell disabled.
4. Put a known poor-quality no-value item beside sellable grays; confirm it remains and valued grays sell without a UI error.
5. Move, split, merge, or replace a queued gray while the sale is running; confirm no stale slot is used.
6. Test locked items, initially uncached item data, immediate merchant close, and rapid merchant reopen.
7. Buy or repair near a sale and inspect the debug delta/reason.
8. Verify Settings persistence across `/reload`, including Shift bypass and every bundled locale.
9. Enable Faster Looting and test both `LOOT_READY autoloot=true` and `false` paths.
10. Check for Lua errors, taint/protected-action errors, duplicate callbacks, repeated timers, and unintended item sales.

Runtime validation remains tracked in GitHub issue #1 until observed on the named client build.
