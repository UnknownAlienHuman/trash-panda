-- Core/Logger.lua
local _, TP = ...

TP.Logger = TP.Logger or {}

local LEVELS = {
    ERROR = 1,
    WARN  = 2,
    INFO  = 3,
    DEBUG = 4,
}

local LEVEL_NAMES = { "ERROR", "WARN", "INFO", "DEBUG" }

local MAX_BUFFER = 200

local function Now()
    -- `date` is fine here (very low-frequency usage).
    return date("%H:%M:%S")
end

function TP.Logger:Init(enabledDebug)
    self.level = enabledDebug and LEVELS.DEBUG or LEVELS.INFO
    self.buffer = self.buffer or {}
    self.head = self.head or 0
end

function TP.Logger:SetDebug(enabled)
    self.level = enabled and LEVELS.DEBUG or LEVELS.INFO
end

function TP.Logger:IsDebug()
    return self.level >= LEVELS.DEBUG
end

local function Push(self, msg)
    local head = (self.head % MAX_BUFFER) + 1
    self.head = head
    self.buffer[head] = msg
end

function TP.Logger:Log(level, msg)
    if level > self.level then
        return
    end
    local line = ("[%s][%s] %s"):format(Now(), LEVEL_NAMES[level] or "LOG", msg)
    Push(self, line)
    -- Keep chat noise minimal: only WARN/ERROR to chat by default.
    if level <= LEVELS.WARN then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00TrashPanda|r " .. line)
    end
end

function TP.Logger:Debug(msg)
    self:Log(LEVELS.DEBUG, msg)
end

function TP.Logger:Info(msg)
    self:Log(LEVELS.INFO, msg)
end

function TP.Logger:Warn(msg)
    self:Log(LEVELS.WARN, msg)
end

function TP.Logger:Error(msg)
    self:Log(LEVELS.ERROR, msg)
end

function TP.Logger:DumpToChat(maxLines)
    maxLines = maxLines or 25
    local buf = self.buffer
    if not buf or #buf == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00TrashPanda|r <log empty>")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00TrashPanda|r log (latest first):")
    local head = self.head or 0
    for i = 0, maxLines - 1 do
        local idx = ((head - i - 1) % MAX_BUFFER) + 1
        local line = buf[idx]
        if line then
            DEFAULT_CHAT_FRAME:AddMessage(line)
        end
    end
end
