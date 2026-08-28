local now = 0
local money = 1000
local timers = {}
local item = {
    itemID = 77,
    quality = 0,
    hasNoValue = false,
    isLocked = false,
    stackCount = 3,
}
local TP

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

    while true do
        local selected
        for _, timer in ipairs(timers) do
            if not timer.cancelled
                and timer.due <= target
                and (not selected or timer.due < selected.due)
            then
                selected = timer
            end
        end

        if not selected then
            now = target
            return
        end

        now = selected.due
        if selected.interval then
            selected.due = selected.due + selected.interval
        else
            selected.cancelled = true
        end
        selected.callback()
    end
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
        return bag == 0 and 1 or 0
    end,
    GetContainerItemInfo = function(bag, slot)
        if bag ~= 0 or slot ~= 1 or not item then
            return nil
        end

        local result = {}
        for key, value in pairs(item) do
            result[key] = value
        end
        return result
    end,
    UseContainerItem = function()
        -- Model an external callback/hook that re-enters the addon before
        -- C_Container.UseContainerItem returns to AutoSell:_Tick().
        money = money + 30
        item = nil
        TP.AutoSell:OnMerchantClosed()
        TP.AutoSell:OnPlayerMoney()
    end,
}

local values = {
    enabled = true,
    bypassShift = false,
    printSummary = false,
}

TP = {
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
TP.AutoSell:OnMerchantShow()
advance(0.50)

assert(not TP.AutoSell.state.active, "transaction did not finalize")
assert(TP.AutoSell.state.phase == "idle", "state did not return to idle")
assert(TP.AutoSell.state.attemptedItems == 0, "reset attemptedItems was mutated after re-entry")
assert(TP.AutoSell.state.actionCount == 0, "reset actionCount was mutated after re-entry")
assert(TP.AutoSell.last.attemptedItems == 3, "attempted stack was lost across re-entry")
assert(TP.AutoSell.last.actionCount == 1, "action was lost across re-entry")
assert(TP.AutoSell.last.gainedCopper == 30, "money delta was lost across re-entry")

print("reentrant merchant-close test passed")
