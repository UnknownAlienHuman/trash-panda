# Code graph

```mermaid
flowchart LR
  TOC[TrashPanda.toc] --> NS[Namespace / locale / config / logger / format]
  NS --> Features[AutoSell + FasterLoot]
  Features --> Settings[Settings]
  Settings --> Bootstrap[Bootstrap]
  Bootstrap --> Init[Init.lua]

  Init --> Loaded[ADDON_LOADED]
  Loaded --> DB[TrashPandaDB]
  Loaded --> Slash[/tp commands]

  Merchant[MERCHANT_SHOW] --> Gates[enabled + Shift gates]
  Gates --> Scan[Current bag scan]
  Scan --> Filter[poor + value filter]
  Filter --> Queue[Paced queue]
  Queue --> Revalidate[itemID + quality + value + lock]
  Revalidate --> Use[C_Container.UseContainerItem]
  Use --> Rescan[Bounded delayed rescan]
  Rescan -->|remaining| Queue
  Rescan -->|clear/capped| Money[PLAYER_MONEY + bounded wait]
  Closed[MERCHANT_CLOSED] --> Money
  Money --> Summary[Format + chat summary]

  Loot[LOOT_READY autoloot] --> Faster[FasterLoot]
  Faster --> Slots[LootSlot]
```
