# Architecture

The TOC loads namespace/locale/config/logger/format, then `Feature/AutoSell.lua` and `Feature/FasterLoot.lua`, then Settings/Bootstrap, and finally [`Init.lua`](Init.lua). `Init.lua` calls `TP.Bootstrap:Init()`; Bootstrap is the sole event/slash router.

`MERCHANT_SHOW` -> `TP.AutoSell:OnMerchantShow` -> `_BuildQueue` -> 0.06 s sell ticker (`_Tick`) -> money-stability wait -> `_Finalize` and `TP.Format:FormatAmount`. `LOOT_READY` is an independent optional FasterLoot path gated by `TrashPandaDB.fasterLoot`. Settings callbacks write the same shallow DB and update locale/logger where needed.

The TOC release version is 0.2.8, but `TP.version` in Namespace is 0.2.3; this is a documented metadata inconsistency, not a separate runtime module.
