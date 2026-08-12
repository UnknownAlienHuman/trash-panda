# Code index

| Area | Files | Responsibility |
| --- | --- | --- |
| Namespace and startup | `Core/Namespace.lua`, `Core/Bootstrap.lua`, `Init.lua` | shared `TP` namespace, event routing, slash commands, entry point |
| Configuration and UI | `Core/Config.lua`, `Core/Settings.lua` | defaults/SavedVariables and Settings registration |
| Shared services | `Core/Locale.lua`, `Core/Logger.lua`, `Util/Format.lua` | strings, logging, money/amount formatting |
| Features | `Feature/AutoSell.lua`, `Feature/FasterLoot.lua` | sell queue and optional faster-looting path |

Primary anchors: `TP.AutoSell:_BuildQueue`, `TP.AutoSell:_Tick`, `IsSellablePoor`, bootstrap event routing, and `SlashCmdList["TRASHPANDA"]`.
