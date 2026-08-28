# Release verification — 0.3.0

Static migration work is complete. Runtime checks must be performed in the Retail 12.1.0 client and recorded in [GitHub issue #1](https://github.com/UnknownAlienHuman/trash-panda/issues/1).

## Offline

- [x] Parse every TOC-loaded Lua file as Lua 5.1-compatible syntax.
- [x] Validate TOC paths, Interface `120100`, and version `0.3.0`.
- [x] Verify point-of-use bag/slot identity, quality, value, and lock checks.
- [x] Verify bounded pass, stall, lock, retry, and money workers.
- [x] Verify `SellAllJunkItems` and `MerchantFrame:IsShown()` are absent from AutoSell.
- [x] Verify unique `TRASHPANDA_*` Settings identifiers.
- [x] Verify localized help/status format consistency.
- [x] Execute the offline WoW-stub harness for settings, slash commands, no-value filtering, stale-slot replacement, item-data retry, money reconciliation, and Faster Looting.

## In client

- [ ] Fresh login and `/reload`.
- [ ] `/tp on|off|status`, `debug on|off`, `log`, and help.
- [ ] No-junk, one-stack, many-junk, Shift-bypass, and disabled cases.
- [ ] Poor-quality no-value item beside valued grays.
- [ ] Move/split/merge/replace a queued gray during sale.
- [ ] Locked and initially uncached item cases.
- [ ] Merchant-close, rapid-reopen, and delayed-money cases.
- [ ] Settings persistence and locale switching.
- [ ] Faster Looting with `LOOT_READY` autoloot true/false.
- [ ] No Lua, taint, protected-action, duplicate-callback, repeated-worker, or unintended-sale errors.
