local TP = {}

_G.GetLocale = function()
    return "enUS"
end

assert(loadfile("Core/Locale.lua"))("TrashPanda", TP)
assert(loadfile("Util/Format.lua"))("TrashPanda", TP)

local requiredKeys = {
    "SETTINGS_CATEGORY",
    "AUTOSELL_LABEL",
    "AUTOSELL_TOOLTIP",
    "PRINT_SUMMARY_LABEL",
    "PRINT_SUMMARY_TOOLTIP",
    "SHIFT_BYPASS_LABEL",
    "SHIFT_BYPASS_TOOLTIP",
    "FAST_LOOT_LABEL",
    "FAST_LOOT_TOOLTIP",
    "LANGUAGE_LABEL",
    "DEBUG_LABEL",
    "DEBUG_TOOLTIP",
    "CMD_HELP",
    "AUTOSELL_ON",
    "AUTOSELL_OFF",
    "DEBUG_ON",
    "DEBUG_OFF",
    "UNKNOWN_CMD",
    "STATUS_FMT",
    "ON",
    "OFF",
    "HUMOR_POS",
    "HUMOR_NEG",
}

local locales = {
    "enUS",
    "ruRU",
    "deDE",
    "esES",
    "esMX",
    "zhCN",
    "zhTW",
}

for _, locale in ipairs(locales) do
    TP:SetLocale(locale)
    assert(type(TP.L) == "table", locale .. ": TP.L is missing")

    for _, key in ipairs(requiredKeys) do
        assert(TP.L[key] ~= nil, locale .. ": missing localization key " .. key)
    end

    assert(type(TP.L.HUMOR_POS) == "table" and #TP.L.HUMOR_POS > 0, locale .. ": HUMOR_POS is empty")
    assert(type(TP.L.HUMOR_NEG) == "table" and #TP.L.HUMOR_NEG > 0, locale .. ": HUMOR_NEG is empty")
end

for _, amount in ipairs({ 0, 1, 99, 100, 101, 9999, 10000, 123456789, -1, -123456789 }) do
    local ok, result = pcall(function()
        return TP.Format:FormatAmount(amount)
    end)

    assert(ok, "FormatAmount failed for " .. tostring(amount) .. ": " .. tostring(result))
    assert(type(result) == "string" and #result > 0, "FormatAmount returned an invalid value for " .. tostring(amount))
end

print("module contracts passed: 7 locales and signed money formatting")
