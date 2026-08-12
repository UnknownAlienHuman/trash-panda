-- Core/Config.lua
local _, TP = ...

TP.Config = TP.Config or {}

local DEFAULTS = {
    printSummary = true,
    bypassShift = true,  -- hold Shift to skip autosell for this vendor
    debug = false,
    fasterLoot = false,
    locale = nil,
}

local function ShallowCopy(src, dst)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = v
        end
    end
end

function TP.Config:Load()
    TrashPandaDB = TrashPandaDB or {}
    ShallowCopy(DEFAULTS, TrashPandaDB)
    self.db = TrashPandaDB
end

function TP.Config:Get(key)
    return self.db and self.db[key]
end

function TP.Config:Set(key, value)
    if not self.db then
        return
    end
    self.db[key] = value
end
