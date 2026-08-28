# TrashPanda (AutoSell Gray)

**Version:** 0.3.0  
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
- Requests missing item data and gives up after explicit pass/stall caps instead of running indefinitely.
- Reconciles the final money change and optionally prints a compact chat summary.
- Hold **Shift** while opening a merchant to skip auto-selling once.
- Optional Faster Looting acts on `LOOT_READY` only when its documented `autoloot` payload is true.

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

## Install

Copy the `TrashPanda` folder to:

```text
World of Warcraft/_retail_/Interface/AddOns/
```

Enable the addon and reload the UI.

## 0.3.0 update

- Migrated the addon to Retail 12.1.0 / Interface 120100.
- Added strict point-of-use identity and safety checks before every container action.
- Replaced frame-visibility gating with merchant lifecycle events.
- Added bounded multi-pass verification for locked, delayed, or initially uncached items.
- Added real `/tp on` and `/tp off` commands.
- Added the Shift-bypass option to Settings.
- Namespaced every Settings identifier as `TRASHPANDA_*`.
- Updated Faster Looting to consume the documented `LOOT_READY` payload.
- Synchronized runtime version, help text, status output, localization, and repository documentation.

## Development

Shared engineering policy and current platform references live in the
[WoW Addon Engineering KB](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb).

## License

Licensed under the [MIT License](LICENSE).
