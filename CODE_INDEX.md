# Code index

| Area | Files | Exact anchors |
| --- | --- | --- |
| Namespace/startup | [`Core/Namespace.lua`](Core/Namespace.lua), [`Core/Bootstrap.lua`](Core/Bootstrap.lua), [`Init.lua`](Init.lua) | `TP.Bootstrap:Init`, `OnSlash`, event-frame `OnEvent` |
| DB/settings | [`Core/Config.lua`](Core/Config.lua), [`Core/Settings.lua`](Core/Settings.lua) | `TP.Config:Load/Get/Set`, `TP.Settings:Init`, `OnSettingChanged` |
| Shared services | [`Core/Locale.lua`](Core/Locale.lua), [`Core/Logger.lua`](Core/Logger.lua), [`Util/Format.lua`](Util/Format.lua) | `PickLocale`, `TP.Logger:Log`, `TP.Format:FormatAmount` |
| Auto-sell | [`Feature/AutoSell.lua`](Feature/AutoSell.lua) | `IsSellablePoor`, `TP.AutoSell:OnMerchantShow`, `_BuildQueue`, `_Tick`, `_Finalize` |
| Faster loot | [`Feature/FasterLoot.lua`](Feature/FasterLoot.lua) | `OnLootReady`, `TP.FasterLoot:Init` |

The only persistent contract is `TrashPandaDB`; feature runtime state is rebuilt at addon load.
