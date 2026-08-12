# Architecture

`Init.lua` enters through the namespace assembled in `Core/`. `Core/Bootstrap.lua` initializes configuration, registers the addon event frame and `/tp` aliases, then routes merchant and money events to features. `Feature/AutoSell.lua` builds and drains the sell queue; `Feature/FasterLoot.lua` separately handles its loot-ready path. `Util/Format.lua` formats user-facing amounts, while Locale, Logger, Config, and Settings provide shared services.

The TOC loads namespace and support modules before features, settings, bootstrap, and `Init.lua`. This establishes the shared `TP` table before feature registration.
