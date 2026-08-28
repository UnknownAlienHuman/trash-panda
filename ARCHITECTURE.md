# Architecture

## Target

- World of Warcraft Retail / Midnight 12.1.0
- Interface `120100`
- Addon version `0.3.1`, read at runtime from TOC metadata
- SavedVariables schema `1`

## Load order

The TOC establishes the shared namespace and services first, then feature modules, Settings, Bootstrap, and the final entry point:

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

## Runtime paths

```text
Init.lua
  -> TP.Bootstrap:Init()
  -> ADDON_LOADED
     -> normalize Config schema and known values
     -> apply locale / Logger / AutoSell / Settings / FasterLoot

MERCHANT_SHOW
  -> enabled and Shift gates
  -> idle: start a transaction
  -> waiting: queue a fresh transaction after old reconciliation
  -> selling/retrying: ignore duplicate event

transaction
  -> snapshot money and start time
  -> scan current bags
     -> queue poor items with hasNoValue == false
     -> request missing item data once per item ID per scan
     -> record no-value poor items without queuing them
  -> paced sale pass
     -> generation/phase/enabled/merchant/limit gates
     -> re-read current slot
     -> require same itemID + poor quality + value + unlocked
     -> C_Container.UseContainerItem
  -> bounded delayed rescan
     -> reset backoff when remaining candidates change
     -> stop after 12 passes or 3 unchanged scans
     -> stop after 500 actions or 45 seconds of sale work
  -> bounded money reconciliation
     -> changed money: wait for 0.35 seconds of stability
     -> unchanged money: exit after 2 seconds
     -> absolute hard cap: 20 seconds
  -> reset all workers and transaction state
  -> optionally start the queued fresh merchant transaction

MERCHANT_CLOSED
  -> clear queued reopen
  -> stop sale/retry workers
  -> retain only bounded money reconciliation

enabled=false
  -> clear queued reopen
  -> stop future sale/retry actions immediately
  -> reconcile only actions already attempted

enabled=true while merchant is open
  -> start immediately when idle
  -> queue a fresh transaction when waiting

LOOT_READY(autoloot)
  -> configured + autoloot gates
  -> required API availability gate
  -> LootSlot for current loot slots
```

## Safety rationale

A bag/slot pair is a mutable location, not an item identity. Every queued entry therefore stores an `itemID`, and `_Tick` re-reads the slot and checks identity, quality, `hasNoValue`, and lock state immediately before `UseContainerItem`.

Every delayed callback captures a transaction generation. Explicit cancellation plus generation and phase checks prevent a stale timer from acting on a later merchant transaction.

The addon intentionally retains this explicit path rather than calling `C_MerchantFrame.SellAllJunkItems()`: open WoWUIBugs issue #488 documents a mainline failure when a no-value poor item is present. The workaround is bounded and should be removed only after a current-build reproduction proves the native API skips those items safely.

The only periodic work is transaction-scoped:

- a 0.08-second sale ticker;
- one-shot retry timers with 0.40–1.60-second bounded backoff;
- a 0.10-second money reconciliation ticker with a 2-second no-change exit and 20-second hard failsafe.

No addon-wide `OnUpdate` runs while idle.

## Persistent state

`TrashPandaDB` contains:

```text
schema
enabled
printSummary
bypassShift
fasterLoot
locale
debug
```

Known booleans and locale values are normalized at load. AutoSell transaction state and the 200-entry diagnostic ring buffer are runtime-only.

## Verification architecture

- `.github/workflows/ci.yml` parses TOC-loaded files with Lua 5.1, runs `tests/run.lua`, builds a clean ZIP, and uploads it as an artifact.
- `tests/run.lua` provides deterministic WoW API, event, Settings, bag, money, timer, and loot stubs.
- `scripts/package.sh` derives the version from the TOC and includes only runtime addon files plus `LICENSE` beneath `TrashPanda/`.
- `.github/workflows/release.yml` publishes only a matching `v<TOC version>` tag after syntax, tests, and packaging pass.
