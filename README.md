# TrashPanda (AutoSell Gray)

**Version:** 0.3.1  
**Target:** World of Warcraft Retail / Midnight 12.1.0  
**Interface:** 120100  
**Author:** Neomorph  
**SavedVariables:** `TrashPandaDB`  
**CurseForge:** [Trash Panda](https://www.curseforge.com/wow/addons/trash-panda)

TrashPanda is a small addon that automatically sells poor-quality (gray) items when a merchant opens.

## Behavior

- Selects only `Enum.ItemQuality.Poor` items whose `hasNoValue` flag is false.
- Revalidates bag, slot, item ID, quality, vendor-value flag, and lock state immediately before every sale.
- Uses a paced, transaction-scoped queue with bounded rescans and exponential retry delay; no addon-wide `OnUpdate` runs while idle.
- Tracks the merchant interaction through `MERCHANT_SHOW` / `MERCHANT_CLOSED`, not default-frame visibility.
- Requests missing item data and gives up after explicit pass, stall, action, and sale-phase caps instead of running indefinitely.
- Cancels the active sale immediately when AutoSell is disabled. Re-enabling while a merchant is open starts a fresh transaction.
- Handles rapid merchant close/reopen by completing the old money reconciliation and then starting a new isolated transaction if the interaction is still current.
- Reconciles the final money change and optionally prints a compact chat summary. A failed action with no observed money change is bounded to a short two-second reconciliation rather than blocking the next merchant session for the full failsafe window.
- Hold **Shift** while opening a merchant to skip auto-selling once.
- Optional Faster Looting acts on `LOOT_READY` only when its documented `autoloot` payload is true and fails closed if the required loot API is unavailable.

TrashPanda deliberately does **not** call `C_MerchantFrame.SellAllJunkItems()`. The still-open upstream Mainline report [WoWUIBugs #488](https://github.com/Stanzilla/WoWUIBugs/issues/488) reports that a poor-quality item with no vendor value can abort that native operation instead of being skipped. The addon's explicit `hasNoValue == false` filter preserves the original safety boundary. The report still requires a clean 12.1 current-build retest before the workaround can be removed.

## Commands

- `/tp on`
- `/tp off`
- `/tp status`
- `/tp debug on|off`
- `/tp log`
- `/tp help`

## Settings

Open **Options → AddOns → TrashPanda** to configure:

- auto-sell enabled;
- sale summary;
- Shift bypass;
- Faster Looting;
- language;
- debug logging.

`TrashPandaDB` uses schema `1`. Known booleans and locale values are validated during load so malformed SavedVariables fail back to deterministic defaults.

## Install

Copy the `TrashPanda` folder to:

```text
World of Warcraft/_retail_/Interface/AddOns/
```

Enable the addon and reload the UI.

## 0.3.1 update

- Fixed `/tp off` and the Settings toggle so disabling AutoSell cancels an in-progress sale instead of allowing the queued items to continue selling.
- Fixed rapid merchant close/reopen so the new interaction cannot be lost behind the previous transaction's money wait.
- Added generation guards to every delayed callback so cancelled workers cannot act on a newer transaction.
- Added total action and sale-phase duration caps in addition to the existing pass, stall, lock, retry, and money caps.
- Reduced the no-money-change reconciliation path to two seconds while preserving the 20-second hard failsafe for changing money.
- Added deterministic SavedVariables validation and schema metadata.
- Added fail-closed Faster Loot API checks.
- Added a Lua 5.1 CI suite, deterministic WoW stub tests, clean ZIP packaging, and tag-driven GitHub releases.

## Verification

The repository CI parses every TOC-loaded file with Lua 5.1, runs the deterministic merchant/loot harness, and builds a clean archive containing only runtime addon files plus the license. Runtime validation in the live WoW client remains tracked in [issue #1](https://github.com/UnknownAlienHuman/trash-panda/issues/1).

## Development

Shared engineering policy and current platform references live in the
[WoW Addon Engineering KB](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb).

## License

Licensed under the [MIT License](LICENSE).
