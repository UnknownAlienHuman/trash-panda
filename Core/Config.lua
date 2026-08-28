-- Core/Config.lua
local _, TP = ...

TP.Config = TP.Config or {}

local CURRENT_SCHEMA = 1

local BOOLEAN_DEFAULTS = {
    enabled = true,
    printSummary = true,
    bypassShift = true, -- hold Shift while opening a merchant to skip once
    debug = false,
    fasterLoot = false,
}

local SUPPORTED_LOCALES = {
    enUS = true,
    ruRU = true,
    deDE = true,
    esES = true,
    esMX = true,
    zhCN = true,
    zhTW = true,
}

local function GetDefaultLocale()
    local locale = type(GetLocale) == "function" and GetLocale() or "enUS"
    return SUPPORTED_LOCALES[locale] and locale or "enUS"
end

local function NormalizeDB(db)
    for key, defaultValue in pairs(BOOLEAN_DEFAULTS) do
        if type(db[key]) ~= "boolean" then
            db[key] = defaultValue
        end
    end

    if type(db.locale) ~= "string" or not SUPPORTED_LOCALES[db.locale] then
        db.locale = GetDefaultLocale()
    end

    if type(db.schema) ~= "number" or db.schema <= CURRENT_SCHEMA then
        db.schema = CURRENT_SCHEMA
    end
end

function TP.Config:Load()
    if type(TrashPandaDB) ~= "table" then
        TrashPandaDB = {}
    end

    NormalizeDB(TrashPandaDB)
    self.db = TrashPandaDB
    return self.db
end

function TP.Config:Get(key)
    return self.db and self.db[key]
end

function TP.Config:Set(key, value)
    if not self.db then
        return false, nil
    end

    if BOOLEAN_DEFAULTS[key] ~= nil then
        local normalized
        if type(value) == "boolean" then
            normalized = value
        else
            normalized = BOOLEAN_DEFAULTS[key]
        end
        self.db[key] = normalized
        return true, normalized
    end

    if key == "locale" then
        local normalized = type(value) == "string" and SUPPORTED_LOCALES[value]
            and value or GetDefaultLocale()
        self.db.locale = normalized
        return true, normalized
    end

    return false, nil
end
