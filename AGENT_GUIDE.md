# TrashPanda agent guide

## Current contract

- Repository: `UnknownAlienHuman/trash-panda`, branch `main`
- Target: World of Warcraft Retail / Midnight 12.1.0
- Interface: `120100`
- Release: `0.3.1`
- Author: Neomorph
- External libraries: none
- SavedVariables schema: `1`
- Shared policy: [`UnknownAlienHuman/wow-addon-engineering-kb`](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)
- Platform snapshot: `Gethe/wow-ui-source@027d26c3406d3de2cbd2b1f67d468fe033a1bcd4`, build `12.1.0.69497`

Read `TrashPanda.toc`, then `ARCHITECTURE.md`, `Core/Bootstrap.lua`, `Feature/AutoSell.lua`, `Feature/FasterLoot.lua`, `Core/Config.lua`, and `Core/Settings.lua` before changing behavior.

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

## AutoSell transaction path

```text
MERCHANT_SHOW
  -> enabled gate
  -> optional Shift bypass
  -> idle: _StartSession
  -> waiting: mark restartRequested for this new interaction
  -> selling/retrying: ignore duplicate event

_StartSession
  -> verify container and timer APIs
  -> reset and increment generation
  -> snapshot GetMoney / start time
  -> _BeginPass
     -> _BuildQueue over carried bags
     -> poor quality + hasNoValue == false
     -> request missing item data once per item ID per scan
     -> paced _Tick
        -> generation/phase/merchant/enabled/limit gates
        -> re-read current bag/slot
        -> require same itemID
        -> require poor + value + unlocked
        -> C_Container.UseContainerItem
     -> delayed bounded rescan/backoff
  -> _StartWaitingForMoney
  -> changed money: 0.35-second stability window
  -> unchanged money: two-second bounded exit
  -> 20-second hard money failsafe
  -> _Finalize
  -> reset; optionally start the queued fresh merchant transaction

MERCHANT_CLOSED
  -> clear any queued reopen
  -> cancel sale/retry workers
  -> bounded money reconciliation only

enabled=false
  -> clear queued restart
  -> cancel the active sale/retry worker
  -> reconcile only already-attempted actions

enabled=true while merchant is open
  -> start immediately if idle
  -> queue a fresh transaction if the old transaction is reconciling
```

A queued bag/slot is never trusted as identity. Any empty, changed, unknown, non-poor, no-value, or locked location is not used. A changed sellable item may be discovered only by a later fresh scan.

Every timer callback captures the current transaction generation and checks active state plus phase before doing work. Cancellation is therefore both explicit and generation-guarded.

## Bounds

- sale interval: `0.08` seconds;
- lock retries per queued location: `20`;
- retry backoff: `0.40` to `1.60` seconds;
- pass cap: `12`;
- unchanged-scan stall cap: `3`;
- container-action cap: `500`;
- sale-phase cap: `45` seconds;
- changed-money stability: `0.35` seconds;
- no-money-change exit: `2` seconds;
- hard money-wait cap: `20` seconds.

Do not weaken, remove, or replace these bounds with an unbounded ticker or `pcall` retry loop.

## Why the native sell-all API is not used

`C_MerchantFrame.SellAllJunkItems()` exists in the current generated API and Blizzard's merchant button calls it. It is nevertheless not the safe TrashPanda path while [WoWUIBugs #488](https://github.com/Stanzilla/WoWUIBugs/issues/488) remains unresolved/current-build unverified: the report states that one poor-quality item without vendor value can abort the operation with “The merchant doesn't want that item” instead of being skipped.

Current 12.1 field code also reports one-shot incompleteness from rate limiting or initially uncached item data. TrashPanda therefore uses explicit filtering, paced calls, fresh rescans, and all bounds listed above.

Do not replace the manual path merely because the native symbol exists. Re-test the exact no-value and many-item cases on the named live build, update the engineering KB issue, then simplify only when the retirement gate is met.

## Faster Loot path

`Feature/FasterLoot.lua` registers `LOOT_READY`. It acts only when both `TrashPandaDB.fasterLoot` and the event's documented `autoloot` payload are true. The required legacy loot functions are captured once and checked before use; a missing API logs one error and fails closed.

Do not recompute autoloot from CVars/modifier keys unless a current platform regression is demonstrated.

## Configuration and commands

SavedVariables:

```text
schema
enabled
printSummary
bypassShift
fasterLoot
locale
debug
```

Schema `1` validates all known booleans and the supported locale at load. Unknown keys are not accepted through `TP.Config:Set`. A future numeric schema is preserved rather than silently downgraded.

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
- Disabling AutoSell stops all future sale actions in the current transaction.
- Re-enabling AutoSell while a merchant is open starts or queues a fresh isolated transaction.
- Holding Shift skips only the current merchant opening when `bypassShift` is enabled.
- Target selection remains exactly poor quality plus `hasNoValue == false`.
- Bag/slot, item ID, quality, value flag, and lock state are re-read immediately before every `UseContainerItem` call.
- Merchant state comes from `MERCHANT_SHOW` / `MERCHANT_CLOSED`, not `MerchantFrame:IsShown()`.
- Sale passes, actions, sale-phase duration, lock retries, item-data retries, backoff, and money reconciliation are all bounded.
- No addon-wide `OnUpdate`, global frame scan, bag-button hook, native sell-all call, or persisted raw log.
- Logger storage remains bounded to 200 runtime entries.
- Debug and runtime locale selection apply immediately; already-rendered Settings labels refresh after reload. All other Settings values are read at the point of use.
- No in-game result may be claimed from source review, CI, or an offline harness alone.

## Verification

Offline and CI:

1. Parse every TOC-loaded Lua file and `tests/run.lua` with Lua 5.1.
2. Confirm every TOC path exists and load order matches this guide.
3. Confirm Interface `120100`, version `0.3.1`, and SavedVariables schema `1`.
4. Run `lua5.1 tests/run.lua`.
5. Confirm the exact point-of-use checks: `itemID`, poor quality, `hasNoValue == false`, and unlocked.
6. Confirm `C_MerchantFrame.SellAllJunkItems` and `MerchantFrame:IsShown()` are absent from the live AutoSell path.
7. Confirm all Settings IDs are prefixed `TRASHPANDA_`.
8. Build through `scripts/package.sh`; confirm the ZIP contains only `TrashPanda.toc`, TOC-loaded Lua files, and `LICENSE` beneath one `TrashPanda/` directory.

In client:

1. Fresh login and `/reload` with only TrashPanda enabled.
2. Test `/tp help`, `on`, `off`, `status`, `debug on|off`, and `log`.
3. Open a merchant with no junk, one junk stack, many junk entries, Shift held, and AutoSell disabled.
4. Disable during an active multi-item sale; confirm no later queued slot is used. Re-enable before closing the merchant and confirm a fresh transaction starts.
5. Put a known poor-quality no-value item beside sellable grays; confirm it remains and valued grays sell without a UI error.
6. Move, split, merge, or replace a queued gray while the sale is running; confirm no stale slot is used.
7. Test locked items, initially uncached item data, immediate merchant close, rapid reopen, reopen with Shift, and a second close before reconciliation completes.
8. Test a rejected/failed sale and confirm the next merchant interaction is not blocked for 20 seconds.
9. Buy or repair near a sale and inspect the debug delta/reason.
10. Verify Settings persistence across `/reload`, including Shift bypass and every bundled locale.
11. Enable Faster Looting and test both `LOOT_READY autoloot=true` and `false` paths.
12. Check for Lua errors, taint/protected-action errors, duplicate callbacks, repeated timers, and unintended item sales.

Runtime validation remains tracked in GitHub issue #1 until observed on the named client build.
