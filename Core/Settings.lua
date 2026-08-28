-- Core/Settings.lua
local ADDON_NAME, TP = ...

TP.Settings = TP.Settings or {}

local SETTING_IDS = {
    enabled = "TRASHPANDA_ENABLED",
    printSummary = "TRASHPANDA_PRINT_SUMMARY",
    bypassShift = "TRASHPANDA_BYPASS_SHIFT",
    fasterLoot = "TRASHPANDA_FASTER_LOOT",
    locale = "TRASHPANDA_LOCALE",
    debug = "TRASHPANDA_DEBUG",
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

local function ApplyChangedValue(key, value)
    TP.Config:Set(key, value)

    if key == "locale" then
        TP:SetLocale(value)
    elseif key == "debug" and TP.Logger then
        TP.Logger:SetDebug(value)
    end
end

function TP.Settings:SetValue(key, value)
    local setting = self.settings and self.settings[key]
    if setting then
        setting:SetValue(value)
    else
        ApplyChangedValue(key, value)
    end
end

function TP.Settings:Init()
    if self.category then
        return
    end

    local category = Settings.RegisterVerticalLayoutCategory(TP.L.SETTINGS_CATEGORY or ADDON_NAME)
    self.category = category
    self.settings = {}

    local function Register(key, variableType, label, defaultValue)
        local setting = Settings.RegisterAddOnSetting(
            category,
            SETTING_IDS[key],
            key,
            TrashPandaDB,
            variableType,
            label,
            defaultValue
        )
        setting:SetValueChangedCallback(function(_, value)
            ApplyChangedValue(key, value)
        end)
        self.settings[key] = setting
        return setting
    end

    local enabledSetting = Register(
        "enabled",
        Settings.VarType.Boolean,
        TP.L.AUTOSELL_LABEL or "Auto-sell gray items",
        Settings.Default.True
    )
    Settings.CreateCheckbox(category, enabledSetting, TP.L.AUTOSELL_TOOLTIP)

    local summarySetting = Register(
        "printSummary",
        Settings.VarType.Boolean,
        TP.L.PRINT_SUMMARY_LABEL or "Print sale summary",
        Settings.Default.True
    )
    Settings.CreateCheckbox(category, summarySetting, TP.L.PRINT_SUMMARY_TOOLTIP)

    local bypassSetting = Register(
        "bypassShift",
        Settings.VarType.Boolean,
        TP.L.SHIFT_BYPASS_LABEL or "Hold Shift to skip once",
        Settings.Default.True
    )
    Settings.CreateCheckbox(category, bypassSetting, TP.L.SHIFT_BYPASS_TOOLTIP)

    local fasterLootSetting = Register(
        "fasterLoot",
        Settings.VarType.Boolean,
        TP.L.FAST_LOOT_LABEL or "Faster Looting",
        Settings.Default.False
    )
    Settings.CreateCheckbox(category, fasterLootSetting, TP.L.FAST_LOOT_TOOLTIP)

    local function GetLanguageOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("enUS", "English")
        container:Add("ruRU", "Русский")
        container:Add("deDE", "Deutsch")
        container:Add("esES", "Español")
        container:Add("esMX", "Español (Latinoamérica)")
        container:Add("zhCN", "简体中文")
        container:Add("zhTW", "繁體中文")
        return container:GetData()
    end

    local localeSetting = Register(
        "locale",
        Settings.VarType.String,
        TP.L.LANGUAGE_LABEL or "Language",
        GetDefaultLocale()
    )
    Settings.CreateDropdown(category, localeSetting, GetLanguageOptions, nil)

    local debugSetting = Register(
        "debug",
        Settings.VarType.Boolean,
        TP.L.DEBUG_LABEL or "Debug mode",
        Settings.Default.False
    )
    Settings.CreateCheckbox(category, debugSetting, TP.L.DEBUG_TOOLTIP)

    Settings.RegisterAddOnCategory(category)
end
