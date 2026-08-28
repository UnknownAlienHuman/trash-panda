local total = 0
local passed = 0

local function fail(message)
    error(message, 2)
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        fail((message or "values differ") .. (": expected %s, got %s"):format(tostring(expected), tostring(actual)))
    end
end

local function assertTrue(value, message)
    if not value then
        fail(message or "expected true")
    end
end

local function test(name, callback)
    total = total + 1
    io.write(("[%02d] %s ... "):format(total, name))
    local ok, err = pcall(callback)
    if not ok then
        io.write("FAIL\n")
        error(err, 0)
    end
    passed = passed + 1
    io.write("ok\n")
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

local function newEnvironment(options)
    options = options or {}

    local env = {
        now = 0,
        money = options.money or 100000,
        timers = {},
        frames = {},
        messages = {},
        logs = {},
        errors = {},
        warnings = {},
        useCalls = 0,
        requestedItemData = {},
        lootCalls = {},
        lootCount = options.lootCount or 0,
        shiftDown = false,
        failSales = options.failSales or false,
        bags = options.bags or {},
        bagSizes = options.bagSizes or {},
        registeredSettings = {},
    }

    _G.TrashPandaDB = options.db or {}
    _G.SlashCmdList = {}
    _G.SLASH_TRASHPANDA1 = nil
    _G.SLASH_TRASHPANDA2 = nil
    _G.BACKPACK_CONTAINER = 0
    _G.NUM_BAG_SLOTS = 4
    _G.Enum = {
        BagIndex = { Backpack = 0, ReagentBag = 5 },
        ItemQuality = { Poor = 0 },
    }

    _G.GetLocale = function()
        return options.locale or "enUS"
    end
    _G.GetTime = function()
        return env.now
    end
    _G.GetServerTime = function()
        return 1
    end
    _G.GetMoney = function()
        return env.money
    end
    _G.IsShiftKeyDown = function()
        return env.shiftDown
    end
    _G.fastrandom = function()
        return 1
    end
    _G.date = function()
        return "00:00:00"
    end

    _G.DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, message)
            env.messages[#env.messages + 1] = message
        end,
    }

    local function createTimer(delay, callback, interval)
        local timer = {
            due = env.now + delay,
            callback = callback,
            interval = interval,
            cancelled = false,
        }
        function timer:Cancel()
            self.cancelled = true
        end
        env.timers[#env.timers + 1] = timer
        return timer
    end

    _G.C_Timer = {
        NewTimer = function(delay, callback)
            return createTimer(delay, callback, nil)
        end,
        NewTicker = function(interval, callback)
            return createTimer(interval, callback, interval)
        end,
    }

    function env:Advance(seconds)
        local target = self.now + seconds
        local iterations = 0

        while true do
            local nextTimer = nil
            for _, timer in ipairs(self.timers) do
                if not timer.cancelled and timer.due <= target then
                    if not nextTimer or timer.due < nextTimer.due then
                        nextTimer = timer
                    end
                end
            end

            if not nextTimer then
                self.now = target
                return
            end

            iterations = iterations + 1
            if iterations > 100000 then
                fail("timer scheduler exceeded safety limit")
            end

            self.now = nextTimer.due
            if nextTimer.interval then
                nextTimer.due = nextTimer.due + nextTimer.interval
            else
                nextTimer.cancelled = true
            end
            nextTimer.callback()
        end
    end

    function env:ActiveTimerCount()
        local count = 0
        for _, timer in ipairs(self.timers) do
            if not timer.cancelled then
                count = count + 1
            end
        end
        return count
    end

    local function createFrame()
        local frame = { events = {}, scripts = {} }
        function frame:RegisterEvent(event)
            self.events[event] = true
        end
        function frame:UnregisterEvent(event)
            self.events[event] = nil
        end
        function frame:SetScript(scriptName, callback)
            self.scripts[scriptName] = callback
        end
        env.frames[#env.frames + 1] = frame
        return frame
    end

    _G.CreateFrame = function()
        return createFrame()
    end

    function env:Fire(event, ...)
        local frames = {}
        for index, frame in ipairs(self.frames) do
            frames[index] = frame
        end

        for _, frame in ipairs(frames) do
            if frame.events[event] and frame.scripts.OnEvent then
                frame.scripts.OnEvent(frame, event, ...)
            end
        end
    end

    local function getBagSize(bag)
        if env.bagSizes[bag] then
            return env.bagSizes[bag]
        end

        local size = 0
        local contents = env.bags[bag]
        if contents then
            for slot in pairs(contents) do
                if type(slot) == "number" and slot > size then
                    size = slot
                end
            end
        end
        return size
    end

    _G.C_Container = {
        GetContainerNumSlots = function(bag)
            return getBagSize(bag)
        end,
        GetContainerItemInfo = function(bag, slot)
            return copyInfo(env.bags[bag] and env.bags[bag][slot])
        end,
        UseContainerItem = function(bag, slot)
            env.useCalls = env.useCalls + 1
            local info = env.bags[bag] and env.bags[bag][slot]
            if not info or env.failSales then
                return
            end

            env.bags[bag][slot] = nil
            local count = type(info.stackCount) == "number" and info.stackCount or 1
            local vendorValue = type(info.vendorValue) == "number" and info.vendorValue or 1
            env.money = env.money + vendorValue * count
            if env.TP and env.TP.AutoSell then
                env.TP.AutoSell:OnPlayerMoney()
            end
        end,
    }

    _G.C_Item = {
        RequestLoadItemDataByID = function(itemID)
            env.requestedItemData[itemID] = (env.requestedItemData[itemID] or 0) + 1
        end,
    }

    _G.C_AddOns = {
        GetAddOnMetadata = function(_, key)
            if key == "Version" then
                return "0.3.1"
            end
            return nil
        end,
    }

    if options.missingLootAPI then
        _G.GetNumLootItems = nil
        _G.LootSlot = nil
    else
        _G.GetNumLootItems = function()
            return env.lootCount
        end
        _G.LootSlot = function(index)
            env.lootCalls[#env.lootCalls + 1] = index
        end
    end

    _G.Settings = {
        VarType = { Boolean = "boolean", String = "string" },
        Default = { True = true, False = false },
    }

    function Settings.RegisterVerticalLayoutCategory(name)
        return { name = name }
    end

    function Settings.RegisterAddOnSetting(category, id, key, db, variableType, label, defaultValue)
        if db[key] == nil then
            db[key] = defaultValue
        end

        local setting = {
            category = category,
            id = id,
            key = key,
            db = db,
            variableType = variableType,
            label = label,
            callback = nil,
        }
        function setting:SetValueChangedCallback(callback)
            self.callback = callback
        end
        function setting:SetValue(value)
            self.db[self.key] = value
            if self.callback then
                self.callback(self, value)
            end
        end

        env.registeredSettings[#env.registeredSettings + 1] = setting
        return setting
    end

    function Settings.CreateCheckbox()
    end

    function Settings.CreateDropdown()
    end

    function Settings.RegisterAddOnCategory()
    end

    function Settings.CreateControlTextContainer()
        local container = { entries = {} }
        function container:Add(value, label)
            self.entries[#self.entries + 1] = { value = value, label = label }
        end
        function container:GetData()
            return self.entries
        end
        return container
    end

    local TP = {
        name = "TrashPanda",
        version = "0.3.1",
        L = {
            SETTINGS_CATEGORY = "TrashPanda",
            AUTOSELL_LABEL = "Auto-sell gray items",
            AUTOSELL_TOOLTIP = "tooltip",
            PRINT_SUMMARY_LABEL = "Print sale summary",
            PRINT_SUMMARY_TOOLTIP = "tooltip",
            SHIFT_BYPASS_LABEL = "Hold Shift to skip once",
            SHIFT_BYPASS_TOOLTIP = "tooltip",
            FAST_LOOT_LABEL = "Faster Looting",
            FAST_LOOT_TOOLTIP = "tooltip",
            LANGUAGE_LABEL = "Language",
            DEBUG_LABEL = "Debug mode",
            DEBUG_TOOLTIP = "tooltip",
            CMD_HELP = "Commands",
            AUTOSELL_ON = "autosell ON",
            AUTOSELL_OFF = "autosell OFF",
            DEBUG_ON = "debug ON",
            DEBUG_OFF = "debug OFF",
            UNKNOWN_CMD = "unknown",
            STATUS_FMT = "status: autosell=%s debug=%s",
            ON = "ON",
            OFF = "OFF",
            HUMOR_POS = { "profit" },
            HUMOR_NEG = { "repair" },
        },
    }
    env.TP = TP

    function TP:SetLocale(locale)
        self.selectedLocale = locale
    end

    TP.Logger = {
        debugEnabled = false,
        Init = function(self, enabled)
            self.debugEnabled = enabled and true or false
        end,
        SetDebug = function(self, enabled)
            self.debugEnabled = enabled and true or false
        end,
        IsDebug = function(self)
            return self.debugEnabled
        end,
        Debug = function(_, message)
            env.logs[#env.logs + 1] = message
        end,
        Info = function(_, message)
            env.logs[#env.logs + 1] = message
        end,
        Warn = function(_, message)
            env.warnings[#env.warnings + 1] = message
        end,
        Error = function(_, message)
            env.errors[#env.errors + 1] = message
        end,
        DumpToChat = function()
        end,
    }

    TP.Format = {
        FormatAmount = function(_, copper)
            return tostring(copper)
        end,
    }

    local function loadModule(path)
        local chunk, loadError = loadfile(path)
        if not chunk then
            fail(("cannot load %s: %s"):format(path, tostring(loadError)))
        end
        chunk("TrashPanda", TP)
    end

    loadModule("Core/Config.lua")
    loadModule("Feature/AutoSell.lua")
    loadModule("Feature/FasterLoot.lua")
    loadModule("Core/Settings.lua")
    loadModule("Core/Bootstrap.lua")

    TP.Bootstrap:Init()
    env:Fire("ADDON_LOADED", "TrashPanda")

    return env
end

local function poorItem(itemID, options)
    options = options or {}
    return {
        itemID = itemID,
        quality = options.quality == nil and 0 or options.quality,
        hasNoValue = options.hasNoValue == true,
        isLocked = options.isLocked == true,
        stackCount = options.stackCount or 1,
        vendorValue = options.vendorValue or 100,
    }
end

test("corrupt SavedVariables are normalized deterministically", function()
    local env = newEnvironment({
        locale = "ruRU",
        db = {
            enabled = "yes",
            printSummary = 1,
            bypassShift = {},
            fasterLoot = "false",
            debug = 0,
            locale = "invalid",
            schema = "old",
        },
    })

    assertEqual(TrashPandaDB.enabled, true, "enabled default")
    assertEqual(TrashPandaDB.printSummary, true, "summary default")
    assertEqual(TrashPandaDB.bypassShift, true, "shift default")
    assertEqual(TrashPandaDB.fasterLoot, false, "loot default")
    assertEqual(TrashPandaDB.debug, false, "debug default")
    assertEqual(TrashPandaDB.locale, "ruRU", "locale fallback")
    assertEqual(TrashPandaDB.schema, 1, "schema")
    assertEqual(env.TP.selectedLocale, "ruRU", "runtime locale")
end)

test("future SavedVariables schema is not downgraded", function()
    newEnvironment({ db = { schema = 9 } })
    assertEqual(TrashPandaDB.schema, 9, "future schema")
end)

test("all Settings identifiers are namespaced", function()
    local env = newEnvironment()
    assertEqual(#env.registeredSettings, 6, "setting count")
    for _, setting in ipairs(env.registeredSettings) do
        assertTrue(setting.id:match("^TRASHPANDA_") ~= nil, "unprefixed setting id")
    end
end)

test("/tp off cancels an active sale before the next queued item", function()
    local env = newEnvironment({
        bags = {
            [0] = {
                [1] = poorItem(101),
                [2] = poorItem(102),
                [3] = poorItem(103),
            },
        },
        bagSizes = { [0] = 3 },
    })

    env:Fire("MERCHANT_SHOW")
    env:Advance(0.09)
    assertEqual(env.useCalls, 1, "first sale")

    SlashCmdList.TRASHPANDA("off")
    env:Advance(3.0)

    assertEqual(env.useCalls, 1, "sale stopped")
    assertEqual(env.bags[0][2].itemID, 102, "second item remains")
    assertEqual(env.bags[0][3].itemID, 103, "third item remains")
    assertEqual(env.TP.AutoSell.state.active, false, "session reset")
    assertEqual(env:ActiveTimerCount(), 0, "no worker leak")
end)

test("/tp on starts a session when a merchant is already open", function()
    local env = newEnvironment({
        db = { enabled = false },
        bags = { [0] = { [1] = poorItem(201) } },
        bagSizes = { [0] = 1 },
    })

    env:Fire("MERCHANT_SHOW")
    env:Advance(0.5)
    assertEqual(env.useCalls, 0, "disabled merchant open")

    SlashCmdList.TRASHPANDA("on")
    env:Advance(2.0)

    assertEqual(env.useCalls, 1, "enabled in place")
    assertEqual(env.bags[0][1], nil, "item sold")
    assertEqual(env.TP.AutoSell.state.active, false, "session complete")
end)

test("rapid merchant close and reopen starts a fresh transaction", function()
    local env = newEnvironment({
        bags = { [0] = { [1] = poorItem(301) } },
        bagSizes = { [0] = 2 },
    })

    env:Fire("MERCHANT_SHOW")
    env:Advance(0.09)
    assertEqual(env.useCalls, 1, "first merchant sale")

    env:Fire("MERCHANT_CLOSED")
    env.bags[0][2] = poorItem(302)
    env:Fire("MERCHANT_SHOW")
    env:Advance(3.0)

    assertEqual(env.useCalls, 2, "fresh merchant session")
    assertEqual(env.bags[0][2], nil, "second item sold")
    assertEqual(env.TP.AutoSell.state.active, false, "reopened session complete")
    assertEqual(env:ActiveTimerCount(), 0, "no worker leak")
end)

test("rapid reopen recovers even when the previous action produced no money", function()
    local env = newEnvironment({
        failSales = true,
        bags = { [0] = { [1] = poorItem(401) } },
        bagSizes = { [0] = 1 },
    })

    env:Fire("MERCHANT_SHOW")
    env:Advance(0.09)
    assertEqual(env.useCalls, 1, "first attempted sale")

    env:Fire("MERCHANT_CLOSED")
    env:Fire("MERCHANT_SHOW")
    env:Advance(2.3)

    assertTrue(env.useCalls >= 2, "new session did not restart after no-money reconciliation")
end)

test("a second close cancels a queued rapid-reopen restart", function()
    local env = newEnvironment({
        bags = { [0] = { [1] = poorItem(501) } },
        bagSizes = { [0] = 2 },
    })

    env:Fire("MERCHANT_SHOW")
    env:Advance(0.09)
    env:Fire("MERCHANT_CLOSED")
    env.bags[0][2] = poorItem(502)
    env:Fire("MERCHANT_SHOW")
    env:Fire("MERCHANT_CLOSED")
    env:Advance(2.0)

    assertEqual(env.useCalls, 1, "unexpected restart after second close")
    assertEqual(env.bags[0][2].itemID, 502, "new item remains")
end)

test("Shift on a rapid reopen skips the new transaction", function()
    local env = newEnvironment({
        bags = { [0] = { [1] = poorItem(601) } },
        bagSizes = { [0] = 2 },
    })

    env:Fire("MERCHANT_SHOW")
    env:Advance(0.09)
    env:Fire("MERCHANT_CLOSED")
    env.bags[0][2] = poorItem(602)
    env.shiftDown = true
    env:Fire("MERCHANT_SHOW")
    env.shiftDown = false
    env:Advance(2.0)

    assertEqual(env.useCalls, 1, "Shift reopen should not restart")
    assertEqual(env.bags[0][2].itemID, 602, "Shift-skipped item remains")
end)

test("no-value poor items are skipped while valued poor items sell", function()
    local env = newEnvironment({
        bags = {
            [0] = {
                [1] = poorItem(701, { hasNoValue = true }),
                [2] = poorItem(702, { vendorValue = 250 }),
            },
        },
        bagSizes = { [0] = 2 },
    })

    env:Fire("MERCHANT_SHOW")
    env:Advance(2.0)

    assertEqual(env.useCalls, 1, "only valued junk action")
    assertEqual(env.bags[0][1].itemID, 701, "no-value item remains")
    assertEqual(env.bags[0][2], nil, "valued item sold")
end)

test("a stale queued slot is revalidated and never used", function()
    local env = newEnvironment({
        bags = { [0] = { [1] = poorItem(801) } },
        bagSizes = { [0] = 1 },
    })

    env:Fire("MERCHANT_SHOW")
    env.bags[0][1] = poorItem(802, { quality = 2 })
    env:Advance(2.0)

    assertEqual(env.useCalls, 0, "stale slot action")
    assertEqual(env.bags[0][1].itemID, 802, "replacement remains")
end)

test("unknown item data is requested once per scan and retried", function()
    local unknown = poorItem(901)
    unknown.quality = nil
    unknown.hasNoValue = nil

    local env = newEnvironment({
        bags = { [0] = { [1] = unknown } },
        bagSizes = { [0] = 1 },
    })

    env:Fire("MERCHANT_SHOW")
    assertEqual(env.requestedItemData[901], 1, "initial data request")

    env:Advance(0.2)
    env.bags[0][1].quality = 0
    env.bags[0][1].hasNoValue = false
    env:Advance(2.0)

    assertEqual(env.useCalls, 1, "loaded item sold")
    assertEqual(env.bags[0][1], nil, "loaded item removed")
end)

test("Faster Loot uses only LOOT_READY autoloot=true", function()
    local env = newEnvironment({
        db = { fasterLoot = true },
        lootCount = 3,
    })

    env:Fire("LOOT_READY", false)
    assertEqual(#env.lootCalls, 0, "autoloot false")

    env:Fire("LOOT_READY", true)
    assertEqual(#env.lootCalls, 3, "autoloot true count")
    assertEqual(env.lootCalls[1], 3, "reverse slot 3")
    assertEqual(env.lootCalls[2], 2, "reverse slot 2")
    assertEqual(env.lootCalls[3], 1, "reverse slot 1")
end)

test("missing Faster Loot APIs fail closed and log once", function()
    local env = newEnvironment({
        db = { fasterLoot = true },
        missingLootAPI = true,
    })

    env:Fire("LOOT_READY", true)
    env:Fire("LOOT_READY", true)

    assertEqual(#env.errors, 1, "single API error")
    assertEqual(#env.lootCalls, 0, "no loot action")
end)

test("unknown Config keys are rejected", function()
    local env = newEnvironment()
    local applied = env.TP.Config:Set("foreignKey", true)
    assertEqual(applied, false, "unknown key accepted")
    assertEqual(TrashPandaDB.foreignKey, nil, "unknown key persisted")
end)

io.write(("\n%d/%d tests passed\n"):format(passed, total))
