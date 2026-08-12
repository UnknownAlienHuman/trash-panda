-- Core/Settings.lua
local ADDON_NAME, TP = ...

TP.Settings = TP.Settings or {}

local function OnSettingChanged(_, setting, value)
    local variable = setting:GetVariable()
    TP.Config:Set(variable, value)

    if variable == "locale" then
        TP:SetLocale(value)
        -- We might need to notify other modules or just rely on them picking it up next time
    elseif variable == "debug" then
        if TP.Logger then TP.Logger:SetDebug(value) end
    end
end

function TP.Settings:Init()
    local category = Settings.RegisterVerticalLayoutCategory(TP.L.SETTINGS_CATEGORY or ADDON_NAME)
    self.category = category

    -- 1. Print Summary
    local summarySetting = Settings.RegisterAddOnSetting(category, "printSummary", "printSummary", TrashPandaDB, "boolean", "Print Summary", true)
    Settings.CreateCheckbox(category, summarySetting, nil)
    Settings.SetOnValueChangedCallback("printSummary", OnSettingChanged)

    -- 3. Faster Loot
    local fasterLootSetting = Settings.RegisterAddOnSetting(category, "fasterLoot", "fasterLoot", TrashPandaDB, "boolean", TP.L.FAST_LOOT_LABEL or "Faster Looting", false)
    Settings.CreateCheckbox(category, fasterLootSetting, nil)
    Settings.SetOnValueChangedCallback("fasterLoot", OnSettingChanged)

    -- 4. Language Dropdown
    local function GetLanguageOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("enUS", "English")
        container:Add("ruRU", "Русский")
        container:Add("deDE", "Deutsch")
        container:Add("esES", "Español")
        container:Add("zhCN", "简体中文")
        container:Add("zhTW", "繁體中文")
        return container:GetData()
    end

    local localeSetting = Settings.RegisterAddOnSetting(category, "locale", "locale", TrashPandaDB, "string", TP.L.LANGUAGE_LABEL or "Language", GetLocale())
    Settings.CreateDropdown(category, localeSetting, GetLanguageOptions, nil)
    Settings.SetOnValueChangedCallback("locale", OnSettingChanged)

    -- 5. Debug
    local debugSetting = Settings.RegisterAddOnSetting(category, "debug", "debug", TrashPandaDB, "boolean", "Debug Mode", false)
    Settings.CreateCheckbox(category, debugSetting, nil)
    Settings.SetOnValueChangedCallback("debug", OnSettingChanged)

    Settings.RegisterAddOnCategory(category)
end
