-- Core/Config.lua
local _, TP = ...

TP.Config = TP.Config or {}

local DEFAULTS = {
    enabled = true,
    printSummary = true,
    bypassShift = true, -- hold Shift while opening a merchant to skip once
    debug = false,
    fasterLoot = false,
}

local function ApplyDefaults(src, dst)
    for key, value in pairs(src) do
        if dst[key] == nil then
            dst[key] = value
        end
    end
end

function TP.Config:Load()
    if type(TrashPandaDB) ~= "table" then
        TrashPandaDB = {}
    end

    ApplyDefaults(DEFAULTS, TrashPandaDB)
    self.db = TrashPandaDB
end

function TP.Config:Get(key)
    return self.db and self.db[key]
end

function TP.Config:Set(key, value)
    if self.db then
        self.db[key] = value
    end
end
