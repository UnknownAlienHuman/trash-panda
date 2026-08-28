-- TrashPanda
-- Shared addon namespace.
local ADDON_NAME, TP = ...

TP.name = ADDON_NAME

local function ReadVersion()
    if C_AddOns and type(C_AddOns.GetAddOnMetadata) == "function" then
        return C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "dev"
    end
    return "dev"
end

TP.version = ReadVersion()
