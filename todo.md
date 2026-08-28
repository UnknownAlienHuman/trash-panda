# Release verification — 0.3.1

Static migration and deterministic regression coverage are complete. Runtime checks must be performed in the Retail 12.1.0 client and recorded in [GitHub issue #1](https://github.com/UnknownAlienHuman/trash-panda/issues/1).

## Offline / CI

- [x] Parse every TOC-loaded Lua file as Lua 5.1-compatible syntax.
- [x] Validate TOC paths, Interface `120100`, and version `0.3.1`.
- [x] Verify point-of-use bag/slot identity, quality, value, and lock checks.
- [x] Verify bounded pass, stall, action, sale-phase, lock, retry, and money workers.
- [x] Verify transaction-generation guards on ticker, retry timer, and money ticker.
- [x] Verify disabling AutoSell cancels future actions in the active transaction.
- [x] Verify enabling AutoSell while a merchant is open starts a fresh transaction.
- [x] Verify rapid close/reopen, no-money prior action, second close, and Shift-reopen paths.
- [x] Verify `SellAllJunkItems` and `MerchantFrame:IsShown()` are absent from AutoSell.
- [x] Verify unique `TRASHPANDA_*` Settings identifiers.
- [x] Verify SavedVariables schema and corrupt-value normalization.
- [x] Verify no-value filtering, stale-slot replacement, and item-data retry.
- [x] Verify Faster Looting autoloot true/false and missing-API fail-closed paths.
- [x] Build and inspect a clean runtime-only ZIP through `scripts/package.sh`.
- [x] Add tag/version-gated GitHub release automation.

## In client

- [ ] Fresh login and `/reload`.
- [ ] `/tp on|off|status`, `debug on|off`, `log`, and help.
- [ ] No-junk, one-stack, many-junk, Shift-bypass, and disabled cases.
- [ ] Disable during a multi-item sale; confirm no later queued action. Re-enable at the same open merchant.
- [ ] Poor-quality no-value item beside valued grays.
- [ ] Move/split/merge/replace a queued gray during sale.
- [ ] Locked and initially uncached item cases.
- [ ] Merchant close, rapid reopen, reopen with Shift, second close, and delayed/no-money cases.
- [ ] Settings persistence, malformed SavedVariables recovery, and locale switching.
- [ ] Faster Looting with `LOOT_READY` autoloot true/false.
- [ ] No Lua, taint, protected-action, duplicate-callback, repeated-worker, or unintended-sale errors.
