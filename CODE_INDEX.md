# Code index

| Area | Files | Exact anchors |
| --- | --- | --- |
| Namespace/startup | [`Core/Namespace.lua`](Core/Namespace.lua), [`Core/Bootstrap.lua`](Core/Bootstrap.lua), [`Init.lua`](Init.lua) | `ReadVersion`, `OnSlash`, `TP.Bootstrap:Init`, `MERCHANT_CLOSED` route |
| DB/settings | [`Core/Config.lua`](Core/Config.lua), [`Core/Settings.lua`](Core/Settings.lua) | `TP.Config:Load/Get/Set`, `SETTING_IDS`, `TP.Settings:Init/SetValue` |
| Localization/logging/format | [`Core/Locale.lua`](Core/Locale.lua), [`Core/Logger.lua`](Core/Logger.lua), [`Util/Format.lua`](Util/Format.lua) | `PickLocale`, `TP.Logger:Log`, `TP.Format:FormatAmount` |
| Auto-sell | [`Feature/AutoSell.lua`](Feature/AutoSell.lua) | `IsSellablePoor`, `_BuildQueue`, `_BeginPass`, `_Tick`, `_ScheduleNextPass`, `_StartWaitingForMoney`, `_Finalize` |
| Faster loot | [`Feature/FasterLoot.lua`](Feature/FasterLoot.lua) | `OnLootReady(autoloot)`, `TP.FasterLoot:Init` |

## Integration boundaries

- Container surface: `C_Container.GetContainerNumSlots`, `GetContainerItemInfo`, and `UseContainerItem`.
- Item-data surface: `C_Item.RequestLoadItemDataByID` for temporarily unknown quality.
- Merchant lifecycle: `MERCHANT_SHOW` and `MERCHANT_CLOSED`; default-frame visibility is not treated as interaction state.
- Native `C_MerchantFrame.SellAllJunkItems` is intentionally excluded while WoWUIBugs #488 remains unresolved/current-build unverified.
- Native loot signal: `LOOT_READY` and its `autoloot` payload.
- Settings identifiers are globally unique `TRASHPANDA_*` variables; SavedVariables keys remain short internal names.
- Runtime version comes from `C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")`.
