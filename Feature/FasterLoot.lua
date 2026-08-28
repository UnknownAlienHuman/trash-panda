-- Feature/FasterLoot.lua
local _, TP = ...

TP.FasterLoot = TP.FasterLoot or {}

local GetNumLootItemsAPI = GetNumLootItems
local LootSlotAPI = LootSlot
local apiErrorLogged = false

local function OnLootReady(autoloot)
    if not TP.Config:Get("fasterLoot") or not autoloot then
        return
    end

    if type(GetNumLootItemsAPI) ~= "function" or type(LootSlotAPI) ~= "function" then
        if not apiErrorLogged and TP.Logger then
            apiErrorLogged = true
            TP.Logger:Error("Missing loot API required for Faster Looting.")
        end
        return
    end

    local numItems = GetNumLootItemsAPI()
    if type(numItems) ~= "number" or numItems <= 0 then
        return
    end

    for index = numItems, 1, -1 do
        LootSlotAPI(index)
    end
end

function TP.FasterLoot:Init()
    if self.frame then
        return
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("LOOT_READY")
    frame:SetScript("OnEvent", function(_, _, autoloot)
        OnLootReady(autoloot)
    end)

    self.frame = frame
end
