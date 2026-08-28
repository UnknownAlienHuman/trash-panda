# Code graph

```mermaid
flowchart LR
  TOC[TrashPanda.toc] --> NS[Namespace / locale / config / logger / format]
  NS --> Features[AutoSell + FasterLoot]
  Features --> Settings[Settings]
  Settings --> Bootstrap[Bootstrap]
  Bootstrap --> Init[Init.lua]

  Init --> Loaded[ADDON_LOADED]
  Loaded --> DB[Normalize TrashPandaDB schema]
  Loaded --> Slash[/tp commands]

  Merchant[MERCHANT_SHOW] --> Gates[enabled + Shift gates]
  Gates -->|idle| Start[Start isolated transaction]
  Gates -->|old money wait| Restart[Queue fresh transaction]
  Start --> Scan[Current bag scan]
  Scan --> Filter[poor + hasNoValue false]
  Filter --> Queue[Paced queue]
  Queue --> Guards[generation + phase + enabled + merchant + caps]
  Guards --> Revalidate[itemID + quality + value + lock]
  Revalidate --> Use[C_Container.UseContainerItem]
  Use --> Rescan[Bounded delayed rescan]
  Rescan -->|remaining| Queue
  Rescan -->|clear/capped| Money[PLAYER_MONEY + bounded wait]
  Closed[MERCHANT_CLOSED] --> Cancel[Cancel sale/retry + clear restart]
  Off[enabled=false] --> Cancel
  Cancel --> Money
  Money --> Summary[Format + optional summary]
  Money --> Reset[Reset workers and generation]
  Reset -->|restart still current| Start

  Loot[LOOT_READY autoloot] --> LootAPI[API availability gate]
  LootAPI --> Faster[FasterLoot]
  Faster --> Slots[LootSlot]

  Tests[tests/run.lua] --> CI[Lua 5.1 CI]
  CI --> Package[scripts/package.sh]
  Package --> Artifact[Clean TrashPanda ZIP]
```
