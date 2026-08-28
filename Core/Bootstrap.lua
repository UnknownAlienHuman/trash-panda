-- Core/Bootstrap.lua
local ADDON_NAME, TP = ...

TP.Bootstrap = TP.Bootstrap or {}

local frame

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00TrashPanda|r " .. message)
end

local function Trim(value)
    value = value or ""
    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function Lower(value)
    return string.lower(value or "")
end

local function SetOption(key, value)
    if TP.Settings and TP.Settings.SetValue then
        TP.Settings:SetValue(key, value)
    else
        TP.Config:Set(key, value)
    end
end

local function OnSlash(message)
    message = Lower(Trim(message))

    if message == "" or message == "help" then
        Print((TP.L and TP.L.CMD_HELP) or "Commands: /tp on | off | status | debug on|off | log")
        return
    end

    if message == "on" then
        SetOption("enabled", true)
        Print((TP.L and TP.L.AUTOSELL_ON) or "autosell ON")
        return
    end

    if message == "off" then
        SetOption("enabled", false)
        Print((TP.L and TP.L.AUTOSELL_OFF) or "autosell OFF")
        return
    end

    if message == "status" then
        local on = (TP.L and TP.L.ON) or "ON"
        local off = (TP.L and TP.L.OFF) or "OFF"
        local enabled = TP.Config:Get("enabled") and on or off
        local debug = TP.Config:Get("debug") and on or off
        local formatString = (TP.L and TP.L.STATUS_FMT) or "status: autosell=%s debug=%s"
        Print(formatString:format(enabled, debug))
        return
    end

    if message == "log" then
        TP.Logger:DumpToChat(30)
        return
    end

    local command, value = message:match("^(%S+)%s+(%S+)$")
    if command == "debug" then
        if value == "on" then
            SetOption("debug", true)
            Print((TP.L and TP.L.DEBUG_ON) or "debug ON")
            return
        elseif value == "off" then
            SetOption("debug", false)
            Print((TP.L and TP.L.DEBUG_OFF) or "debug OFF")
            return
        end
    end

    Print((TP.L and TP.L.UNKNOWN_CMD) or "Unknown command. /tp help")
end

function TP.Bootstrap:Init()
    if frame then
        return
    end

    frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_CLOSED")
    frame:RegisterEvent("PLAYER_MONEY")

    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "ADDON_LOADED" then
            if arg1 ~= ADDON_NAME then
                return
            end

            self:UnregisterEvent("ADDON_LOADED")
            TP.Config:Load()

            local savedLocale = TP.Config:Get("locale")
            if savedLocale then
                TP:SetLocale(savedLocale)
            end

            TP.Logger:Init(TP.Config:Get("debug"))
            TP.AutoSell:Init()

            if TP.Settings and TP.Settings.Init then
                TP.Settings:Init()
            end

            if TP.FasterLoot and TP.FasterLoot.Init then
                TP.FasterLoot:Init()
            end

            SLASH_TRASHPANDA1 = "/tp"
            SLASH_TRASHPANDA2 = "/trashpanda"
            SlashCmdList["TRASHPANDA"] = OnSlash

            if TP.Logger:IsDebug() then
                TP.Logger:Debug(("Addon loaded: version=%s"):format(TP.version or "dev"))
            end
        elseif event == "MERCHANT_SHOW" then
            TP.AutoSell:OnMerchantShow()
        elseif event == "MERCHANT_CLOSED" then
            TP.AutoSell:OnMerchantClosed()
        elseif event == "PLAYER_MONEY" then
            TP.AutoSell:OnPlayerMoney()
        end
    end)
end
