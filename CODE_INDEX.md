# Code index

| Area | Files | Exact anchors |
| --- | --- | --- |
| Namespace/startup | [`Core/Namespace.lua`](Core/Namespace.lua), [`Core/Bootstrap.lua`](Core/Bootstrap.lua), [`Init.lua`](Init.lua) | `ReadVersion`, `ApplyRuntimeOption`, `OnSlash`, `TP.Bootstrap:Init`, merchant lifecycle routes |
| DB/settings | [`Core/Config.lua`](Core/Config.lua), [`Core/Settings.lua`](Core/Settings.lua) | `CURRENT_SCHEMA`, `NormalizeDB`, `TP.Config:Load/Get/Set`, `SETTING_IDS`, `ApplyChangedValue`, `TP.Settings:Init/SetValue` |
| Localization/logging/format | [`Core/Locale.lua`](Core/Locale.lua), [`Core/Logger.lua`](Core/Logger.lua), [`Util/Format.lua`](Util/Format.lua) | `PickLocale`, `TP.Logger:Log`, `TP.Format:FormatAmount` |
| Auto-sell | [`Feature/AutoSell.lua`](Feature/AutoSell.lua) | `HasRequiredAPIs`, `IsSellablePoor`, `_BuildQueue`, `_StartSession`, `OnEnabledChanged`, `_BeginPass`, `_Tick`, `_ScheduleNextPass`, `_StartWaitingForMoney`, `_Finalize` |
| Faster loot | [`Feature/FasterLoot.lua`](Feature/FasterLoot.lua) | captured loot APIs, `OnLootReady(autoloot)`, `TP.FasterLoot:Init` |
| Verification/package | [`tests/run.lua`](tests/run.lua), [`scripts/package.sh`](scripts/package.sh), [`.github/workflows/ci.yml`](.github/workflows/ci.yml), [`.github/workflows/release.yml`](.github/workflows/release.yml) | deterministic scheduler/events, lifecycle regression cases, TOC-derived clean ZIP, tag/version gate |

## Integration boundaries

- Container surface: `C_Container.GetContainerNumSlots`, `GetContainerItemInfo`, and `UseContainerItem`.
- Item-data surface: `C_Item.RequestLoadItemDataByID` for temporarily unknown quality/value metadata.
- Merchant lifecycle: `MERCHANT_SHOW` and `MERCHANT_CLOSED`; default-frame visibility is not treated as interaction state.
- Runtime option lifecycle: `TP.AutoSell:OnEnabledChanged` cancels or starts/queues a transaction after the persisted value changes.
- Timer isolation: transaction generation plus phase checks on every delayed callback.
- Native `C_MerchantFrame.SellAllJunkItems` is intentionally excluded while WoWUIBugs #488 remains unresolved/current-build unverified.
- Native loot signal: `LOOT_READY` and its `autoloot` payload; missing required functions fail closed.
- Settings identifiers are globally unique `TRASHPANDA_*` variables; SavedVariables keys remain short internal names.
- Runtime version comes from `C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")`.
