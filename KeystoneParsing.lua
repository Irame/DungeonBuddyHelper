---@class DBH_Private
local private = select(2, ...)

---@class DungeonInfo
---@field activityId number the id of then activity
---@field dungeonShorthand string the showrthand of the dungeon (eg. "siege" for Siege of Boralus)

-- keys are taken from https://wago.tools/db2/MapChallengeMode
-- activityId taken from https://wago.tools/db2/GroupFinderActivity
---@type table<integer, DungeonInfo>
local dungeonInfo = {
    -- 11.0
    [507] = { -- Grim Batol
        activityId = 1290,
        dungeonShorthand = "gb",
    },
    [503] = { -- Ara-Kara, City of Echoes
        activityId = 1284,
        dungeonShorthand = "arak",
    },
    [505] = { -- The Dawnbreaker
        activityId = 1285,
        dungeonShorthand = "dawn",
    },
    [501] = { -- The Stonevault
        activityId = 1287,
        dungeonShorthand = "sv",
    },
    [502] = { -- City of Threads
        activityId = 1288,
        dungeonShorthand = "cot",
    },
    [375] = { -- Mists of Tirna Scithe
        activityId = 703,
        dungeonShorthand = "mists",
    },
    [376] = { -- The Necrotic Wake
        activityId = 713,
        dungeonShorthand = "nw",
    },
    [353] = { -- Siege of Boralus
        activityId = 534,
        dungeonShorthand = "siege",
    },

    -- 11.1
    [504] = { -- Darkflame Cleft
        activityId = 1282,
        dungeonShorthand = "dfc",
    },
    [499] = { -- Priory of the Sacred Flame
        activityId = 1281,
        dungeonShorthand = "psf",
    },
    [370] = { -- Operation: Mechagon - Workshop
        activityId = 683,
        dungeonShorthand = "work",
    },
    [506] = { -- Cinderbrew Meadery
        activityId = 1286,
        dungeonShorthand = "brew",
    },
    [500] = { -- The Rookery
        activityId = 1283,
        dungeonShorthand = "rook",
    },
    [525] = { -- Operation: Floodgate
        activityId = 1550,
        dungeonShorthand = "flood",
    },
    [247] = { -- The MOTHERLODE!!
        activityId = 510,
        dungeonShorthand = "ml",
    },
    [382] = { -- Theater of Pain
        activityId = 717,
        dungeonShorthand = "top",
    },
}

---@class KeystoneInfo : DungeonInfo
---@field level integer the level of the keystone

---@class UnitKeystoneInfo : KeystoneInfo
---@field unit string

local function ParseKeystoneLink(link)
    if not link then
        return
    end

    local dungeonID, level = string.match(link, "keystone:%d+:(%d+):(%d+)")
    if dungeonID and level then
        return tonumber(dungeonID), tonumber(level)
    end
end

---Gets the Info of the keystone from the link passed.
---If no link is passed we try to find a key in the players bags and use it
---@param keystoneLink? string The item link string of the key
---@return KeystoneInfo? keyInfo
function private:GetKeystoneInfoForLink(keystoneLink)
    local dungeonID, level = ParseKeystoneLink(keystoneLink)

    if not dungeonID then
        return
    end

    local info = dungeonInfo[dungeonID]
    if not info then
        self.addon:Printf("Missing support for dungeon with map id '%d'. Please open a issue on CurseForge or GitHub.", dungeonID)
        return
    end

    return {
        activityId = info.activityId,
        dungeonShorthand = info.dungeonShorthand,
        level = level,
    }
end

---Gets the Info for the dungeon from the challenge map id passed
---@param unit string The unit to get the keystone info for
---@return UnitKeystoneInfo? keyInfo
function private:GetKeystoneInfoForUnit(unit)
    local orlKLeyInfo = private.openRaidLib.GetKeystoneInfo(unit)

    if not orlKLeyInfo or orlKLeyInfo.challengeMapID == 0 then
        return
    end

    local info = dungeonInfo[orlKLeyInfo.challengeMapID]
    if not info then
        self.addon:Printf("Missing support for dungeon with map id '%d'. Please open a issue on CurseForge or GitHub.", orlKLeyInfo.challengeMapID)
        return
    end

    return  {
        activityId = info.activityId,
        dungeonShorthand = info.dungeonShorthand,
        level = orlKLeyInfo.level,
        unit = unit,
    }
end
