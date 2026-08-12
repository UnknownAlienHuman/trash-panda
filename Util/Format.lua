-- Util/Format.lua
---@class TrashPanda
local _, TP = ...

TP.Format = TP.Format or {}

local ICON_SIZE = 14
local ICON_GOLD = ("|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:2:0|t"):format(ICON_SIZE, ICON_SIZE)
local ICON_SILVER = ("|TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:2:0|t"):format(ICON_SIZE, ICON_SIZE)
local ICON_COPPER = ("|TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:2:0|t"):format(ICON_SIZE, ICON_SIZE)

-- Copper formatting without allocations beyond the final string.
---@param copper number|string
---@return string
function TP.Format:FormatMoney(copper)
    copper = tonumber(copper) or 0
    if copper <= 0 then
        return "0c"
    end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper - gold * 10000) / 100)
    local cop = copper - gold * 10000 - silver * 100

    if gold > 0 then
        return ("%dg %ds %dc"):format(gold, silver, cop)
    end
    if silver > 0 then
        return ("%ds %dc"):format(silver, cop)
    end
    return ("%dc"):format(cop)
end

-- Minimal output:
--  - If exact gold: "10 Gold" (localized)
--  - Else: "10g 36s 77c" (no zero parts)
---@param copper number|string
---@return string
function TP.Format:FormatAmount(copper)
    copper = tonumber(copper) or 0

    local sign = ""
    if copper < 0 then
        sign = "-"
        copper = -copper
    end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper - gold * 10000) / 100)
    local cop = copper - gold * 10000 - silver * 100

    local parts = {}
    if gold > 0 then parts[#parts + 1] = ("%d%s"):format(gold, ICON_GOLD) end
    if silver > 0 then parts[#parts + 1] = ("%d%s"):format(silver, ICON_SILVER) end
    if cop > 0 then parts[#parts + 1] = ("%d%s"):format(cop, ICON_COPPER) end

    if #parts == 0 then
        return sign .. ("0" .. ICON_COPPER)
    end

    -- Put sign only once, in front of the first number.
    if sign ~= "" then
        parts[1] = sign .. parts[1]
    end

    return table.concat(parts, " ")
end
