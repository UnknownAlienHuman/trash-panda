-- Feature/FasterLoot.lua
local _, TP = ...

TP.FasterLoot = TP.FasterLoot or {}

local function OnLootReady()
    if not TP.Config:Get("fasterLoot") then return end
    
    -- Check if auto-loot is effectively active (either via CVar or modified click)
    -- Leatrix Plus logic: if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE")
    if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
        local numItems = GetNumLootItems()
        if numItems > 0 then
            for i = numItems, 1, -1 do
                LootSlot(i)
            end
        end
    end
end

function TP.FasterLoot:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("LOOT_READY")
    frame:SetScript("OnEvent", function(_, event)
        if event == "LOOT_READY" then
            OnLootReady()
        end
    end)
end
