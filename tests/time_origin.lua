local now = 0
local money = 100000
local timers = {}
local useCalls = 0
local bags = { [0] = {} }

for slot = 1, 36 do
    bags[0][slot] = {
        itemID = 1000 + slot,
        quality = 0,
        hasNoValue = false,
        isLocked = true,
        stackCount = 1,
    }
end

local function copyInfo(info)
    if not info then
        return nil
    end

    local result = {}
    for key, value in pairs(info) do
        result[key] = value
    end
    return result
end

local function createTimer(delay, callback, interval)
    local timer = {
        due = now + delay,
        callback = callback,
        interval = interval,
        cancelled = false,
    }

    function timer:Cancel()
        self.cancelled = true
    end

    timers[#timers + 1] = timer
    return timer
end

local function advance(seconds)
    local target = now + seconds
    local iterations = 0

    while true do
        local nextTimer
        for _, timer in ipairs(timers) do
            if not timer.cancelled and timer.due <= target then
                if not nextTimer or timer.due < nextTimer.due then
                    nextTimer = timer
                end
            end
        end

        if not nextTimer then
            now = target
            return
        end

        iterations = iterations + 1
        assert(iterations < 100000, "timer scheduler exceeded safety limit")

        now = nextTimer.due
        if nextTimer.interval then
            nextTimer.due = nextTimer.due + nextTimer.interval
        else
            nextTimer.cancelled = true
        end
        nextTimer.callback()
    end
end

local function activeTimerCount()
    local count = 0
    for _, timer in ipairs(timers) do
        if not timer.cancelled then
            count = count + 1
        end
    end
    return count
end

_G.Enum = {
    BagIndex = { Backpack = 0, ReagentBag = 5 },
    ItemQuality = { Poor = 0 },
}
_G.BACKPACK_CONTAINER = 0
_G.NUM_BAG_SLOTS = 4
_G.GetTime = function()
    return now
end
_G.GetMoney = function()
    return money
end
_G.GetServerTime = function()
    return 1
end
_G.IsShiftKeyDown = function()
    return false
end
_G.fastrandom = function()
    return 1
end
_G.DEFAULT_CHAT_FRAME = { AddMessage = function() end }
_G.C_Timer = {
    NewTimer = function(delay, callback)
        return createTimer(delay, callback, nil)
    end,
    NewTicker = function(interval, callback)
        return createTimer(interval, callback, interval)
    end,
}
_G.C_Item = {
    RequestLoadItemDataByID = function() end,
}
_G.C_Container = {
    GetContainerNumSlots = function(bag)
        return bag == 0 and 36 or 0
    end,
    GetContainerItemInfo = function(bag, slot)
        return copyInfo(bags[bag] and bags[bag][slot])
    end,
    UseContainerItem = function()
        useCalls = useCalls + 1
    end,
}

local values = {
    enabled = true,
    bypassShift = false,
    printSummary = false,
}

local TP = {
    L = {
        HUMOR_POS = { "profit" },
        HUMOR_NEG = { "repair" },
    },
    Config = {
        Get = function(_, key)
            return values[key]
        end,
    },
    Logger = {
        IsDebug = function()
            return false
        end,
        Debug = function() end,
        Warn = function() end,
        Error = function() end,
    },
    Format = {
        FormatAmount = function(_, value)
            return tostring(value)
        end,
    },
}

assert(loadfile("Feature/AutoSell.lua"))("TrashPanda", TP)
TP.AutoSell:Init()

assert(now == 0, "test must start at the zero time origin")
TP.AutoSell:OnMerchantShow()
assert(TP.AutoSell.state.active, "session did not start")

advance(46.0)

assert(useCalls == 0, "locked items must not be used")
assert(not TP.AutoSell.state.active, "45-second session cap did not terminate the transaction")
assert(TP.AutoSell.last.completionReason == "session-timeout", "unexpected completion reason: " .. tostring(TP.AutoSell.last.completionReason))
assert(activeTimerCount() == 0, "session-timeout left an active worker")

print("time-origin session timeout test passed")
