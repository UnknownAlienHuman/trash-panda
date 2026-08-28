-- Feature/AutoSell.lua
local _, TP = ...

TP.AutoSell = TP.AutoSell or {}

local ContainerAPI = C_Container
local GetNumSlots = ContainerAPI and ContainerAPI.GetContainerNumSlots
local GetContainerItemInfo = ContainerAPI and ContainerAPI.GetContainerItemInfo
local UseContainerItem = ContainerAPI and ContainerAPI.UseContainerItem

local POOR_QUALITY = (Enum and Enum.ItemQuality and Enum.ItemQuality.Poor) or 0

local SELL_TICK_SECONDS = 0.08
local MAX_LOCK_RETRIES = 20

local RETRY_BASE_SECONDS = 0.40
local RETRY_MAX_SECONDS = 1.60
local MAX_PASSES = 12
local MAX_STALLS = 3

local WAIT_TICK_SECONDS = 0.10
local WAIT_STABLE_SECONDS = 0.35
local WAIT_MAX_SECONDS = 20.0

local function Now()
    return type(GetTime) == "function" and GetTime() or 0
end

local function CurrentMoney(fallback)
    local value = type(GetMoney) == "function" and GetMoney() or nil
    return type(value) == "number" and value or (fallback or 0)
end

local function GetFirstBagIndex()
    if Enum and Enum.BagIndex and Enum.BagIndex.Backpack then
        return Enum.BagIndex.Backpack
    end
    return BACKPACK_CONTAINER or 0
end

local function GetLastBagIndex()
    if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
        return Enum.BagIndex.ReagentBag
    end
    if BACKPACK_CONTAINER and NUM_BAG_SLOTS then
        return BACKPACK_CONTAINER + NUM_BAG_SLOTS + 1
    end
    return 5
end

local function RequestItemData(itemID)
    if itemID
        and C_Item
        and type(C_Item.RequestLoadItemDataByID) == "function"
    then
        C_Item.RequestLoadItemDataByID(itemID)
    end
end

local function IsSellablePoor(info)
    return info
        and info.itemID
        and info.quality == POOR_QUALITY
        and info.hasNoValue == false
end

local function RandomIndex(high)
    if type(fastrandom) == "function" then
        return fastrandom(high)
    end
    if type(random) == "function" then
        return random(high)
    end
    if type(math.random) == "function" then
        return math.random(1, high)
    end

    local timestamp = type(GetServerTime) == "function" and GetServerTime() or 0
    return (timestamp % high) + 1
end

local function PickHumorLine(delta)
    local positive = (TP.L and TP.L.HUMOR_POS) or {}
    local negative = (TP.L and TP.L.HUMOR_NEG) or {}
    local list = delta < 0 and #negative > 0 and negative or positive

    if #list == 0 then
        return "More coin, less junk"
    end
    return list[RandomIndex(#list)]
end

function TP.AutoSell:Init()
    if self.state then
        if self.state.ticker then
            self.state.ticker:Cancel()
        end
        if self.state.retryTimer then
            self.state.retryTimer:Cancel()
        end
        if self.state.waitTicker then
            self.state.waitTicker:Cancel()
        end
    end

    self.merchantOpen = false
    self.state = {
        active = false,
        phase = "idle", -- idle | selling | retrying | waiting
        queue = {},
        index = 1,
        ticker = nil,
        retryTimer = nil,
        waitTicker = nil,
        startMoney = 0,
        lastMoney = 0,
        waitStartedAt = 0,
        lastMoneyChangeAt = 0,
        moneyChangedAfterDone = false,
        attemptedItems = 0,
        lockRetries = 0,
        passCount = 0,
        stallCount = 0,
        lastRemaining = nil,
        retryDelay = RETRY_BASE_SECONDS,
        unknownItems = 0,
        skippedNoValue = 0,
        loggedNoValue = false,
    }

    self.last = {
        attemptedItems = 0,
        gainedCopper = 0,
        passCount = 0,
        completionReason = "none",
    }
end

function TP.AutoSell:_CancelWorkers()
    local state = self.state
    if state.ticker then
        state.ticker:Cancel()
        state.ticker = nil
    end
    if state.retryTimer then
        state.retryTimer:Cancel()
        state.retryTimer = nil
    end
    if state.waitTicker then
        state.waitTicker:Cancel()
        state.waitTicker = nil
    end
end

function TP.AutoSell:_ResetState()
    local state = self.state
    self:_CancelWorkers()

    state.active = false
    state.phase = "idle"
    state.queue = {}
    state.index = 1
    state.startMoney = 0
    state.lastMoney = 0
    state.waitStartedAt = 0
    state.lastMoneyChangeAt = 0
    state.moneyChangedAfterDone = false
    state.attemptedItems = 0
    state.lockRetries = 0
    state.passCount = 0
    state.stallCount = 0
    state.lastRemaining = nil
    state.retryDelay = RETRY_BASE_SECONDS
    state.unknownItems = 0
    state.skippedNoValue = 0
    state.loggedNoValue = false
end

function TP.AutoSell:_BuildQueue()
    local queue = {}
    local unknownItems = 0
    local skippedNoValue = 0

    for bag = GetFirstBagIndex(), GetLastBagIndex() do
        local numSlots = GetNumSlots(bag)
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local info = GetContainerItemInfo(bag, slot)
                if info and info.itemID then
                    if info.quality == nil then
                        unknownItems = unknownItems + 1
                        RequestItemData(info.itemID)
                    elseif info.quality == POOR_QUALITY then
                        if info.hasNoValue then
                            skippedNoValue = skippedNoValue + 1
                        elseif IsSellablePoor(info) then
                            queue[#queue + 1] = {
                                bag = bag,
                                slot = slot,
                                itemID = info.itemID,
                            }
                        end
                    end
                end
            end
        end
    end

    return queue, unknownItems, skippedNoValue
end

function TP.AutoSell:OnPlayerMoney()
    local state = self.state
    if not state or not state.active then
        return
    end

    local money = CurrentMoney(state.lastMoney)
    if money ~= state.lastMoney then
        state.lastMoney = money
        state.lastMoneyChangeAt = Now()
        if state.phase == "waiting" then
            state.moneyChangedAfterDone = true
        end
    end
end

function TP.AutoSell:_Finalize(reason)
    local state = self.state
    if not state.active then
        return
    end

    local delta = CurrentMoney(state.startMoney) - state.startMoney

    if delta < 0 and TP.Logger:IsDebug() then
        TP.Logger:Warn((
            "Money delta negative (%d). Possible repairs/buys during autosell."
        ):format(delta))
    end

    self.last.attemptedItems = state.attemptedItems
    self.last.gainedCopper = delta
    self.last.passCount = state.passCount
    self.last.completionReason = reason or "unknown"

    if TP.Config:Get("printSummary") and state.attemptedItems > 0 then
        local amount = TP.Format:FormatAmount(delta)
        local comment = PickHumorLine(delta)
        DEFAULT_CHAT_FRAME:AddMessage(
            "TrashPanda " .. amount .. ". |cffffd100" .. comment .. "|r"
        )
    end

    if TP.Logger:IsDebug() then
        TP.Logger:Debug((
            "Finalize: attempted=%d delta=%d passes=%d reason=%s"
        ):format(
            state.attemptedItems,
            delta,
            state.passCount,
            reason or "unknown"
        ))
    end

    self:_ResetState()
end

function TP.AutoSell:_StartWaitingForMoney(reason)
    local state = self.state
    self:_CancelWorkers()

    if state.attemptedItems <= 0 then
        if TP.Logger:IsDebug() and (state.unknownItems > 0 or state.skippedNoValue > 0) then
            TP.Logger:Debug((
                "Autosell ended without attempts: unknown=%d noValue=%d reason=%s"
            ):format(state.unknownItems, state.skippedNoValue, reason or "unknown"))
        end
        self:_ResetState()
        return
    end

    state.phase = "waiting"
    state.waitStartedAt = Now()
    state.lastMoney = CurrentMoney(state.startMoney)
    state.lastMoneyChangeAt = state.waitStartedAt
    state.moneyChangedAfterDone = state.lastMoney ~= state.startMoney

    state.waitTicker = C_Timer.NewTicker(WAIT_TICK_SECONDS, function()
        local now = Now()
        local money = CurrentMoney(state.lastMoney)
        if money ~= state.lastMoney then
            state.lastMoney = money
            state.lastMoneyChangeAt = now
            state.moneyChangedAfterDone = true
        end

        local waited = now - state.waitStartedAt
        local stableFor = now - state.lastMoneyChangeAt

        if state.moneyChangedAfterDone and stableFor >= WAIT_STABLE_SECONDS then
            self:_Finalize(reason or "money-stable")
            return
        end

        if waited >= WAIT_MAX_SECONDS then
            self:_Finalize("money-timeout")
        end
    end)
end

function TP.AutoSell:_ScheduleNextPass()
    local state = self.state
    if state.ticker then
        state.ticker:Cancel()
        state.ticker = nil
    end

    if not self.merchantOpen then
        self:_StartWaitingForMoney("merchant-closed")
        return
    end

    state.phase = "retrying"
    if state.retryTimer then
        state.retryTimer:Cancel()
    end

    local delay = state.retryDelay
    state.retryTimer = C_Timer.NewTimer(delay, function()
        state.retryTimer = nil
        self:_BeginPass()
    end)
end

function TP.AutoSell:_BeginPass()
    local state = self.state
    if not state.active then
        return
    end

    if not self.merchantOpen then
        self:_StartWaitingForMoney("merchant-closed")
        return
    end

    local queue, unknownItems, skippedNoValue = self:_BuildQueue()
    local remaining = #queue + unknownItems

    state.unknownItems = unknownItems
    state.skippedNoValue = skippedNoValue

    if skippedNoValue > 0 and not state.loggedNoValue and TP.Logger:IsDebug() then
        state.loggedNoValue = true
        TP.Logger:Debug((
            "Skipping %d poor-quality item(s) with no vendor value."
        ):format(skippedNoValue))
    end

    if remaining == 0 then
        self:_StartWaitingForMoney("bags-clear")
        return
    end

    if state.lastRemaining ~= nil then
        if remaining < state.lastRemaining then
            state.stallCount = 0
            state.retryDelay = RETRY_BASE_SECONDS
        elseif remaining > state.lastRemaining then
            state.stallCount = 0
            state.retryDelay = RETRY_BASE_SECONDS
        else
            state.stallCount = state.stallCount + 1
            state.retryDelay = math.min(state.retryDelay * 2, RETRY_MAX_SECONDS)
        end
    end
    state.lastRemaining = remaining

    if state.stallCount >= MAX_STALLS then
        local message = (
            "Stopped autosell after %d stalled pass(es); sellable=%d unknown=%d."
        ):format(state.stallCount, #queue, unknownItems)
        if #queue > 0 then
            TP.Logger:Warn(message)
        elseif TP.Logger:IsDebug() then
            TP.Logger:Debug(message)
        end
        self:_StartWaitingForMoney("stalled")
        return
    end

    if state.passCount >= MAX_PASSES then
        local message = (
            "Stopped autosell at the %d-pass safety cap; sellable=%d unknown=%d."
        ):format(MAX_PASSES, #queue, unknownItems)
        if #queue > 0 then
            TP.Logger:Warn(message)
        elseif TP.Logger:IsDebug() then
            TP.Logger:Debug(message)
        end
        self:_StartWaitingForMoney("pass-cap")
        return
    end

    state.passCount = state.passCount + 1

    if #queue == 0 then
        -- Item data is still loading. No worker is armed except this bounded retry.
        self:_ScheduleNextPass()
        return
    end

    state.phase = "selling"
    state.queue = queue
    state.index = 1
    state.lockRetries = 0

    if TP.Logger:IsDebug() then
        TP.Logger:Debug((
            "Autosell pass %d: sellable=%d unknown=%d noValue=%d"
        ):format(state.passCount, #queue, unknownItems, skippedNoValue))
    end

    state.ticker = C_Timer.NewTicker(SELL_TICK_SECONDS, function()
        self:_Tick()
    end)
end

function TP.AutoSell:_Tick()
    local state = self.state
    if not state.active then
        return
    end

    if not self.merchantOpen then
        self:_StartWaitingForMoney("merchant-closed")
        return
    end

    local entry = state.queue[state.index]
    if not entry then
        self:_ScheduleNextPass()
        return
    end

    local info = GetContainerItemInfo(entry.bag, entry.slot)
    if not info
        or info.itemID ~= entry.itemID
        or not IsSellablePoor(info)
    then
        -- The slot is a mutable location. A changed/empty/unsafe slot is never used.
        state.index = state.index + 1
        state.lockRetries = 0
        return
    end

    if info.isLocked then
        state.lockRetries = state.lockRetries + 1
        if state.lockRetries >= MAX_LOCK_RETRIES then
            if TP.Logger:IsDebug() then
                TP.Logger:Debug((
                    "Deferring locked item: bag=%d slot=%d itemID=%d"
                ):format(entry.bag, entry.slot, entry.itemID))
            end
            state.index = state.index + 1
            state.lockRetries = 0
        end
        return
    end

    UseContainerItem(entry.bag, entry.slot)
    state.attemptedItems = state.attemptedItems + (info.stackCount or 1)
    state.index = state.index + 1
    state.lockRetries = 0
end

function TP.AutoSell:OnMerchantShow()
    self.merchantOpen = true

    if not TP.Config:Get("enabled") then
        return
    end

    if TP.Config:Get("bypassShift") and IsShiftKeyDown() then
        if TP.Logger:IsDebug() then
            TP.Logger:Debug("Shift held: autosell skipped.")
        end
        return
    end

    if not (GetNumSlots and GetContainerItemInfo and UseContainerItem) then
        TP.Logger:Error("Missing C_Container API required for safe junk selling.")
        return
    end

    if self.state.active then
        if TP.Logger:IsDebug() then
            TP.Logger:Debug("Autosell already active; ignore MERCHANT_SHOW.")
        end
        return
    end

    local state = self.state
    state.active = true
    state.phase = "retrying"
    state.startMoney = CurrentMoney(0)
    state.lastMoney = state.startMoney

    self:_BeginPass()
end

function TP.AutoSell:OnMerchantClosed()
    self.merchantOpen = false

    local state = self.state
    if not state or not state.active or state.phase == "waiting" then
        return
    end

    self:_StartWaitingForMoney("merchant-closed")
end
