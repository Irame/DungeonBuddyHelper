---@class DBH_Private
local private = select(2, ...)

local LibOpenRaid = LibStub:GetLibrary("LibOpenRaid-1.0")

local partyKeystoneUpdateEvent = "PartyKeystoneUpdate"

local handlers = {}

handlers.callbacks = LibStub("CallbackHandler-1.0"):New(handlers)

function handlers.callbacks:OnUsed(target, eventname)
    if eventname == partyKeystoneUpdateEvent then
        LibOpenRaid.RegisterCallback(handlers, "KeystoneUpdate", "OnLibOpenRaidUpdate")
    end
end

function handlers.callbacks:OnUnused(target, eventname)
    if eventname == partyKeystoneUpdateEvent then
        LibOpenRaid.UnregisterCallback(handlers, "KeystoneUpdate")
    end
end

function handlers:OnLibOpenRaidUpdate()
    handlers.callbacks:Fire(partyKeystoneUpdateEvent)
end


function private.RegisterKeystoneUpdate(target, func)
    handlers.RegisterCallback(target, partyKeystoneUpdateEvent, func)
end

function private.UnregisterKeystoneUpdate(target)
    handlers.UnregisterCallback(target, partyKeystoneUpdateEvent)
end

function private:RequestPartyKeys()
    LibOpenRaid.RequestKeystoneDataFromParty()
end


local function GetKeystoneInfoFromChallengeMapID(challengeMapID, level, unit)
    if not challengeMapID or challengeMapID == 0 then
        return
    end

    local info = private:GetDungeonInfo(challengeMapID);
    if not info then return end

    return  {
        activityId = info.activityId,
        dungeonShorthand = info.dungeonShorthand,
        level = level,
        unit = unit,
    }
end

local function GetKeystoneInfoFromLibOpenRaid(unit)
    local orlKLeyInfo = LibOpenRaid.GetKeystoneInfo(unit)

    if not orlKLeyInfo then return end

    return GetKeystoneInfoFromChallengeMapID(orlKLeyInfo.challengeMapID, orlKLeyInfo.level, unit)
end

---@param unit string The unit to get the keystone info for
---@return UnitKeystoneInfo? keyInfo
function private:GetKeystoneInfoForUnit(unit)
    if not UnitExists(unit) then return end

    if unit == "player" then
        return GetKeystoneInfoFromChallengeMapID(C_MythicPlus.GetOwnedKeystoneChallengeMapID(), C_MythicPlus.GetOwnedKeystoneLevel(), unit)
    end

    return GetKeystoneInfoFromLibOpenRaid(unit);
end
