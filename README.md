# TrashPanda (AutoSell Gray)

**Version:** 0.2.8
**Interface:** 120001, 120005
**SavedVariables:** `TrashPandaDB`
**CurseForge:** [Trash Panda](https://www.curseforge.com/wow/addons/trash-panda)

Ultra-light addon: automatically sells **poor (gray)** items when you open a merchant.

## Behavior
- Triggers on `MERCHANT_SHOW`
- Sells items with `quality == Enum.ItemQuality.Poor` and `hasNoValue == false`
- Hold **Shift** while opening a merchant to skip once (configurable)
- Uses a tiny sell queue (ticker) to avoid edge-cases with temporarily locked slots
- Prints exact money delta (GetMoney before/after), then: "<amount>. <comment>"

## Commands
- `/tp status`
- `/tp debug on|off`
- `/tp log`

## Install

Copy `TrashPanda` to `World of Warcraft/_retail_/Interface/AddOns/`, enable it, and reload the UI.

## Settings and status

The Settings module registers options for print summary, Faster Looting, locale, and debug mode. The checked-in TODO records a completed diagnostic investigation of `Util/Format.lua`; it contains no remaining implementation checkbox. The current open verification item is an in-game smoke test of merchant selling, Shift skip, queue recovery, Faster Looting, and settings persistence.

## License

Licensed under the [MIT License](LICENSE). Bundled third-party components remain under their own notices.
