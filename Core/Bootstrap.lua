-- Core/Bootstrap.lua
local ADDON_NAME, TP = ...

TP.Bootstrap = TP.Bootstrap or {}

local frame

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00TrashPanda|r " .. msg)
end

local function Trim(s)
    s = s or ""
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

local function Lower(s)
    return string.lower(s or "")
end

local function OnSlash(msg)
    msg = Lower(Trim(msg))
    if msg == "" or msg == "help" then
        Print((TP.L and TP.L.CMD_HELP) or "Commands: /tp on | off | status | debug on|off | log")
        return
    end

    if msg == "status" then
        local on = (TP.L and TP.L.ON) or "ON"
        local off = (TP.L and TP.L.OFF) or "OFF"
        local dbg = TP.Config:Get("debug") and on or off
        local fmt = (TP.L and TP.L.STATUS_FMT) or "status: debug=%s"
        Print(fmt:format(dbg))
        return
    end

    if msg == "log" then
        TP.Logger:DumpToChat(30)
        return
    end

    local a, b = msg:match("^(%S+)%s+(%S+)$")
    if a == "debug" then
        if b == "on" then
            TP.Config:Set("debug", true)
            TP.Logger:SetDebug(true)
            Print((TP.L and TP.L.DEBUG_ON) or "debug ON")
            return
        elseif b == "off" then
            TP.Config:Set("debug", false)
            TP.Logger:SetDebug(false)
            Print((TP.L and TP.L.DEBUG_OFF) or "debug OFF")
            return
        end
    end

    Print((TP.L and TP.L.UNKNOWN_CMD) or "Unknown command. /tp help")
end

function TP.Bootstrap:Init()
    frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("PLAYER_MONEY")

    frame:SetScript("OnEvent", function(_, event, arg1)
        if event == "ADDON_LOADED" then
            if arg1 ~= ADDON_NAME then
                return
            end
            TP.Config:Load()
            
            -- Apply saved locale if it exists
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

            -- Slash commands
            SLASH_TRASHPANDA1 = "/tp"
            SLASH_TRASHPANDA2 = "/trashpanda"
            SlashCmdList["TRASHPANDA"] = OnSlash

            if TP.Logger:IsDebug() then
                TP.Logger:Debug("Addon loaded.")
            end
        elseif event == "MERCHANT_SHOW" then
            TP.AutoSell:OnMerchantShow()
        elseif event == "PLAYER_MONEY" then
            if TP.AutoSell and TP.AutoSell.OnPlayerMoney then
                TP.AutoSell:OnPlayerMoney()
            end
        end
    end)
end
