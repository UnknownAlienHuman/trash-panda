-- Feature/AutoSell.lua
local _, TP = ...

TP.AutoSell = TP.AutoSell or {}

local C_Container = C_Container
local GetNumSlots = C_Container and C_Container.GetContainerNumSlots
local UseContainerItem = (C_Container and C_Container.UseContainerItem) or UseContainerItem

-- Enum.ItemQuality.Poor exists in modern clients; fallback to 0.
local POOR_QUALITY = (Enum and Enum.ItemQuality and Enum.ItemQuality.Poor) or 0

local MAX_LOCK_RETRIES = 20
local TICK_SECONDS = 0.06
local WAIT_TICK_SECONDS = 0.10
local WAIT_STABLE_SECONDS = 0.35
local WAIT_MAX_SECONDS = 20.0

local function GetReagentBagIndex()
    -- Retail reagent bag is Enum.BagIndex.ReagentBag (usually 5).
    if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
        return Enum.BagIndex.ReagentBag
    end
    -- Fallback: backpack(0) + NUM_BAG_SLOTS(4) + 1 = 5
    if BACKPACK_CONTAINER and NUM_BAG_SLOTS then
        return BACKPACK_CONTAINER + NUM_BAG_SLOTS + 1
    end
    return 4
end

local function GetLastBagIndex()
    local last = GetReagentBagIndex()
    if last < 4 then
        last = 4
    end
    return last
end

function TP.AutoSell:Init()
    self.state = {
        active = false,
        phase = "idle", -- idle | selling | waiting
        queue = {},
        idx = 1,
        ticker = nil,
        waitTicker = nil,
        startMoney = 0,
        lastMoney = 0,
        waitStartedAt = 0,
        lastMoneyChangeAt = 0,
        moneyChangedAfterDone = false,
        expectedCopper = 0,
        soldItems = 0,
        lockRetries = 0,
    }

    self.last = {
        soldItems = 0,
        gainedCopper = 0,
        expectedCopper = 0,
    }
    -- NOTE (WoW Lua): math.randomseed is not available; the client seeds RNG at startup.
    -- Keep this flag for future compatibility, but do not attempt to seed.
    self._rngSeeded = true
end

local function GetSellPriceFromLink(link)
    if not link then
        return 0
    end
    -- Global GetItemInfo returns (among other fields) sellPrice as the 11th return value.
    local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(link)
    if type(sellPrice) ~= "number" then
        return 0
    end
    return sellPrice
end

local function RandomIndex(high)
    -- Prefer Blizzard's RNG globals if available.
    if type(fastrandom) == "function" then
        return fastrandom(high)
    end
    if type(random) == "function" then
        return random(high)
    end
    if type(math.random) == "function" then
        return math.random(1, high)
    end
    local t = 0
    if type(GetServerTime) == "function" then
        t = GetServerTime()
    elseif type(time) == "function" then
        t = time()
    end
    return (t % high) + 1
end

local function PickHumorLine(delta)
    local pos = (TP.L and TP.L.HUMOR_POS) or {}
    local neg = (TP.L and TP.L.HUMOR_NEG) or {}

    local list
    if (tonumber(delta) or 0) < 0 and #neg > 0 then
        list = neg
    else
        list = pos
    end

    if not list or #list == 0 then
        return "More coin, less junk"
    end
    return list[RandomIndex(#list)]
end

local function HasMerchantOpen()
    return MerchantFrame and MerchantFrame:IsShown()
end

local function IsSellablePoor(info)
    return info
        and info.quality == POOR_QUALITY
        and not info.hasNoValue
end

function TP.AutoSell:_ResetState()
    local s = self.state
    if s.ticker then
        s.ticker:Cancel()
    end
    if s.waitTicker then
        s.waitTicker:Cancel()
    end
    s.active = false
    s.phase = "idle"
    s.queue = {}
    s.idx = 1
    s.ticker = nil
    s.waitTicker = nil
    s.startMoney = 0
    s.lastMoney = 0
    s.waitStartedAt = 0
    s.lastMoneyChangeAt = 0
    s.moneyChangedAfterDone = false
    s.expectedCopper = 0
    s.soldItems = 0
    s.lockRetries = 0
end

function TP.AutoSell:OnPlayerMoney()
    local s = self.state
    if not s.active then
        return
    end
    local now = (type(GetTime) == "function" and GetTime()) or 0
    local m = GetMoney() or s.lastMoney
    if m ~= s.lastMoney then
        s.lastMoney = m
        s.lastMoneyChangeAt = now
        if s.phase == "waiting" then
            s.moneyChangedAfterDone = true
        end
    end
end

function TP.AutoSell:_BuildQueue()
    local q = {}
    local expectedCopper = 0
    local lastBag = GetLastBagIndex()

    for bag = 0, lastBag do
        local numSlots = GetNumSlots(bag)
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if IsSellablePoor(info) then
                    local stack = info.stackCount or 1
                    local priceEach = GetSellPriceFromLink(info.hyperlink)
                    if priceEach > 0 then
                        expectedCopper = expectedCopper + (priceEach * stack)
                    end
                    q[#q + 1] = {
                        bag = bag,
                        slot = slot,
                        itemID = info.itemID,
                    }
                end
            end
        end
    end
    return q, expectedCopper
end

function TP.AutoSell:_Finalize()
    local s = self.state
    if not s.active then
        return
    end

    local endMoney = GetMoney() or s.startMoney
    local delta = endMoney - s.startMoney
    if delta < 0 and TP.Logger:IsDebug() then
        TP.Logger:Warn(("Money delta negative (%d). Possible repairs/buys during autosell."):format(delta))
    end

    self.last.soldItems = s.soldItems
    self.last.gainedCopper = delta
    self.last.expectedCopper = s.expectedCopper

    if TP.Config:Get("printSummary") and s.soldItems > 0 then
        local amount = TP.Format:FormatAmount(delta)
        local comment = PickHumorLine(delta)
        local yellow = "|cffffd100" -- warm yellow (WoW gold-ish)
        DEFAULT_CHAT_FRAME:AddMessage("TrashPanda " .. amount .. ". " .. yellow .. comment .. "|r")

        if TP.Logger:IsDebug() and s.expectedCopper > 0 and math.abs(delta - s.expectedCopper) > 0 then
            TP.Logger:Debug(("Money mismatch: delta=%d expected=%d (repairs/buys/other addons?)"):format(delta, s.expectedCopper))
        end
    end

    if TP.Logger:IsDebug() then
        TP.Logger:Debug(("Finalize: soldItems=%d delta=%d expected=%d"):format(s.soldItems, delta, s.expectedCopper))
    end

    self:_ResetState()
end

function TP.AutoSell:_StartWaitingForMoney()
    local s = self.state
    s.phase = "waiting"
    local now = (type(GetTime) == "function" and GetTime()) or 0
    s.waitStartedAt = now
    s.lastMoney = GetMoney() or s.startMoney
    s.lastMoneyChangeAt = now

    -- If the final money update arrived before we entered the waiting phase,
    -- we still want to finalize quickly after a short stability window.
    s.moneyChangedAfterDone = (s.lastMoney ~= s.startMoney)

    if s.waitTicker then
        s.waitTicker:Cancel()
    end

    s.waitTicker = C_Timer.NewTicker(WAIT_TICK_SECONDS, function()
        local now = (type(GetTime) == "function" and GetTime()) or 0
        local m = GetMoney() or s.lastMoney
        if m ~= s.lastMoney then
            s.lastMoney = m
            s.lastMoneyChangeAt = now
            s.moneyChangedAfterDone = true
        end

        local waited = now - (s.waitStartedAt or 0)
        local stableFor = now - (s.lastMoneyChangeAt or 0)

        -- Finalize only after we observed at least one money change post-sale,
        -- and money has been stable for a short window.
        if s.moneyChangedAfterDone and stableFor >= WAIT_STABLE_SECONDS then
            self:_Finalize()
            return
        end

        -- Failsafe: don't wait forever.
        if waited >= WAIT_MAX_SECONDS then
            self:_Finalize()
        end
    end)
end

function TP.AutoSell:_Tick()
    local s = self.state
    if not s.active then
        return
    end
    if not HasMerchantOpen() then
        if TP.Logger:IsDebug() then
            TP.Logger:Debug("Merchant closed while selling; finalize.")
        end
        -- Money from the last sale can arrive slightly later.
        if s.phase == "selling" then
            if s.ticker then
                s.ticker:Cancel()
                s.ticker = nil
            end
            self:_StartWaitingForMoney()
        else
            self:_Finalize()
        end
        return
    end

    local item = s.queue[s.idx]
    if not item then
        if s.ticker then
            s.ticker:Cancel()
            s.ticker = nil
        end
        self:_StartWaitingForMoney()
        return
    end

    local info = C_Container.GetContainerItemInfo(item.bag, item.slot)
    if not IsSellablePoor(info) then
        -- Slot changed / already sold / became unsellable.
        s.idx = s.idx + 1
        s.lockRetries = 0
        return
    end

    if info.isLocked then
        s.lockRetries = s.lockRetries + 1
        if s.lockRetries >= MAX_LOCK_RETRIES then
            TP.Logger:Warn(("Skip locked item (bag=%d slot=%d) after %d retries"):format(item.bag, item.slot, s.lockRetries))
            s.idx = s.idx + 1
            s.lockRetries = 0
        end
        return
    end

    -- Attempt sale.
    UseContainerItem(item.bag, item.slot)
    s.soldItems = s.soldItems + (info.stackCount or 1)

    s.idx = s.idx + 1
    s.lockRetries = 0
end

function TP.AutoSell:OnMerchantShow()
    if TP.Config:Get("bypassShift") and IsShiftKeyDown() then
        if TP.Logger:IsDebug() then
            TP.Logger:Debug("Shift held: autosell skipped.")
        end
        return
    end
    if not (GetNumSlots and UseContainerItem) then
        TP.Logger:Error("Missing container API (C_Container).")
        return
    end

    -- Prevent re-entrancy (some UIs can re-fire MERCHANT_SHOW).
    if self.state.active then
        if TP.Logger:IsDebug() then
            TP.Logger:Debug("Autosell already active; ignore MERCHANT_SHOW.")
        end
        return
    end

    local queue, expectedCopper = self:_BuildQueue()
    if #queue == 0 then
        if TP.Logger:IsDebug() then
            TP.Logger:Debug("No gray items found to sell.")
        end
        return
    end

    local s = self.state
    s.active = true
    s.phase = "selling"
    s.queue = queue
    s.idx = 1
    s.startMoney = GetMoney() or 0
    s.lastMoney = s.startMoney
    s.expectedCopper = expectedCopper
    s.soldItems = 0
    s.lockRetries = 0

    if TP.Logger:IsDebug() then
        TP.Logger:Debug(("Start autosell: items=%d expected=%d startMoney=%d"):format(#queue, expectedCopper, s.startMoney))
    end

    s.ticker = C_Timer.NewTicker(TICK_SECONDS, function()
        self:_Tick()
    end)
end
