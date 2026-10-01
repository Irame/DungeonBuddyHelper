---@class DBH_Private
local private = select(2, ...)

local LibOpenRaid = LibStub:GetLibrary("LibOpenRaid-1.0")
local LibKeystone = LibStub("LibKeystone")

local partyKeystoneUpdateEvent = "PartyKeystoneUpdate"

local handlers = {}

-- #region KeyStore

---@class KeyStoreEntry
---@field challengeMapID integer
---@field level integer
---@field source string
---@field received time_t

---@type table<string, KeyStoreEntry>
local keys = {}
local lifetime = 1800

local function FindPartyKeyOwner(sender)
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) or IsInRaid(LE_PARTY_CATEGORY_HOME) then return end
    local owner = private:FullName(sender)
    if not owner then return end
    for unit in private:IterPartyMembers() do
        if unit ~= "player" and UnitExists(unit) and private:UnitFullName(unit) == owner then
            return owner, unit
        end
    end
end

---@param unit UnitId
---@return KeyStoreEntry?
---@return string? owner
local function GetSharedPartyKey(unit)
    local owner = private:UnitFullName(unit)
    if not owner then return end
    local entry = keys[owner]
    if entry and GetTime() - entry.received < lifetime then
        return entry, owner
    end
end

---@param palyerName string
---@param challengeMapID integer
---@param level integer
---@param source string
local function StorePartyKey(palyerName, challengeMapID, level, source)
    local owner = FindPartyKeyOwner(palyerName)
    if not owner or type(challengeMapID) ~= "number" or type(level) ~= "number"
        or challengeMapID < 0 or level < 0 or challengeMapID % 1 ~= 0 or level % 1 ~= 0 then
        return
    end

    keys[owner] = {
        challengeMapID = challengeMapID,
        level = level,
        source = source,
        received = GetTime()
    }

    handlers.callbacks:Fire(partyKeystoneUpdateEvent)
end

local function PrunePartyKeys()
    local removed = false
    for owner in pairs(keys) do
        if not FindPartyKeyOwner(owner) then
            keys[owner] = nil
            removed = true
        end
    end

    if removed then
        handlers.callbacks:Fire(partyKeystoneUpdateEvent)
    end
end

function private:InitializeKeyStore()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "GROUP_ROSTER_UPDATE" then
            PrunePartyKeys()
            self:RequestPartyKeys()
        end
    end);
end

-- #endregion KeyStore

-- #region Callbacks and Events

handlers.callbacks = LibStub("CallbackHandler-1.0"):New(handlers)

function handlers.callbacks:OnUsed(target, eventname)
    if eventname == partyKeystoneUpdateEvent then
        LibOpenRaid.RegisterCallback(handlers, "KeystoneUpdate", "OnLibOpenRaidUpdate")
        LibKeystone.Register(handlers, handlers.OnLibKeystoneUpdate)
    end
end

function handlers.callbacks:OnUnused(target, eventname)
    if eventname == partyKeystoneUpdateEvent then
        LibOpenRaid.UnregisterCallback(handlers, "KeystoneUpdate")
        LibKeystone.Unregister(handlers)
    end
end

function handlers:OnLibOpenRaidUpdate()
    handlers.callbacks:Fire(partyKeystoneUpdateEvent)
end

function handlers.OnLibKeystoneUpdate(keyLevel, challengeMapID, playerRating, playerName, channel)
    StorePartyKey(playerName, challengeMapID, keyLevel, "LibKeystone")
end

function private.RegisterKeystoneUpdate(target, func)
    handlers.RegisterCallback(target, partyKeystoneUpdateEvent, func)
end

function private.UnregisterKeystoneUpdate(target)
    handlers.UnregisterCallback(target, partyKeystoneUpdateEvent)
end

function private:RequestPartyKeys()
    LibOpenRaid.RequestKeystoneDataFromParty()
    LibKeystone.Request("PARTY")
end

-- #region Callbacks and Events

-- #region GetKeystoneInfoForUnit

---@param challengeMapID integer
---@param level integer
---@param owner? string
---@return OwnedKeystoneInfo?
local function GetKeystoneInfoFromChallengeMapID(challengeMapID, level, owner)
    if not challengeMapID or challengeMapID == 0 then
        return
    end

    local info = private:GetDungeonInfo(challengeMapID);
    if not info then return end

    return  {
        activityId = info.activityId,
        dungeonShorthand = info.dungeonShorthand,
        level = level,
        owner = owner,
    }
end

---@param unit UnitId
---@return OwnedKeystoneInfo?
local function GetKeystoneInfoFromLibOpenRaid(unit)
    local orlKLeyInfo = LibOpenRaid.GetKeystoneInfo(unit)

    if not orlKLeyInfo then return end

    return GetKeystoneInfoFromChallengeMapID(orlKLeyInfo.challengeMapID, orlKLeyInfo.level, private:UnitFullName(unit))
end

---@param unit UnitId
---@return OwnedKeystoneInfo?
local function GetKeystoneInfoFromKeyStore(unit)
    local keyStoreEntry, owner = GetSharedPartyKey(unit)

    if not keyStoreEntry then return end

    return GetKeystoneInfoFromChallengeMapID(keyStoreEntry.challengeMapID, keyStoreEntry.level, owner)
end

---@param unit UnitId The unit to get the keystone info for
---@return OwnedKeystoneInfo? keyInfo
function private:GetKeystoneInfoForUnit(unit)
    if not UnitExists(unit) then return end

    if unit == "player" then
        return GetKeystoneInfoFromChallengeMapID(C_MythicPlus.GetOwnedKeystoneChallengeMapID(), C_MythicPlus.GetOwnedKeystoneLevel(), private:UnitFullName(unit))
    end

    return GetKeystoneInfoFromLibOpenRaid(unit) or GetKeystoneInfoFromKeyStore(unit)
end

-- #endregion
