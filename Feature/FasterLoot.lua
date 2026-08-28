-- Feature/FasterLoot.lua
local _, TP = ...

TP.FasterLoot = TP.FasterLoot or {}

local function OnLootReady(autoloot)
    if not TP.Config:Get("fasterLoot") or not autoloot then
        return
    end

    local numItems = GetNumLootItems()
    for index = numItems, 1, -1 do
        LootSlot(index)
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
