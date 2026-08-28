# Architecture

## Target

- World of Warcraft Retail / Midnight 12.1.0
- Interface `120100`
- Addon version `0.3.0`, read at runtime from TOC metadata

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
     -> Config / locale / Logger / AutoSell / Settings / FasterLoot

MERCHANT_SHOW
  -> enabled and Shift gates
  -> snapshot GetMoney
  -> scan current bags
     -> queue poor items with hasNoValue == false
     -> request missing item data
     -> record no-value poor items without queuing them
  -> paced sale pass
     -> re-read current slot
     -> require same itemID + poor quality + value + unlocked
     -> C_Container.UseContainerItem
  -> bounded delayed rescan
     -> reset backoff when remaining candidates change
     -> stop after 12 passes or 3 unchanged scans
  -> money-stability wait
  -> TP.AutoSell:_Finalize()

MERCHANT_CLOSED
  -> stop sale/retry workers
  -> retain only the bounded money-stability wait

LOOT_READY(autoloot)
  -> configured + autoloot gates
  -> LootSlot for current loot slots
```

## Safety rationale

A bag/slot pair is a mutable location, not an item identity. Every queued entry therefore stores an `itemID`, and `_Tick` re-reads the slot and checks identity, quality, `hasNoValue`, and lock state immediately before `UseContainerItem`.

The addon intentionally retains this explicit path rather than calling `C_MerchantFrame.SellAllJunkItems()`: open WoWUIBugs issue #488 documents a mainline failure when a no-value poor item is present. The workaround is bounded and should be removed only after a current-build reproduction proves the native API skips those items safely.

The only periodic work is transaction-scoped:

- an 0.08-second sale ticker;
- one-shot retry timers with 0.40–1.60-second bounded backoff;
- an 0.10-second money reconciliation ticker with a 20-second failsafe.

All workers are cancelled on finalization or reinitialization.

## Persistent state

`TrashPandaDB` contains:

```text
enabled
printSummary
bypassShift
fasterLoot
locale
debug
```

AutoSell transaction state and the 200-entry diagnostic ring buffer are runtime-only.
