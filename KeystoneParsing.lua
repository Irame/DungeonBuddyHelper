---@class DBH_Private
local private = select(2, ...)

local L = private.L

---@class DungeonInfo
---@field activityId number the id of then activity
---@field dungeonShorthand string the showrthand of the dungeon (eg. "siege" for Siege of Boralus)

-- keys are taken from https://wago.tools/db2/MapChallengeMode
-- activityId taken from https://wago.tools/db2/GroupFinderActivity
---@type table<integer, DungeonInfo>
local dungeonInfo = {
    -- Midnight
    [558] = { -- Magisters Terrace
        activityId = 1760,
        dungeonShorthand = "magi",
    },
    [560] = { -- Maisara Caverns
        activityId = 1764,
        dungeonShorthand = "cavns",
    },
    [559] = { -- Nexus Point Xenas
        activityId = 1768,
        dungeonShorthand = "xenas",
    },
    [557] = { -- Windrunner Spire
        activityId = 1542,
        dungeonShorthand = "wind",
    },

    -- The War Within
    [499] = { -- Priory of the Sacred Flame
        activityId = 1281,
        dungeonShorthand = "psf",
    },
    [500] = { -- The Rookery
        activityId = 1283,
        dungeonShorthand = "rook",
    },
    [501] = { -- The Stonevault
        activityId = 1287,
        dungeonShorthand = "sv",
    },
    [502] = { -- City of Threads
        activityId = 1288,
        dungeonShorthand = "cot",
    },
    [503] = { -- Ara-Kara, City of Echoes
        activityId = 1284,
        dungeonShorthand = "arak",
    },
    [504] = { -- Darkflame Cleft
        activityId = 1282,
        dungeonShorthand = "dfc",
    },
    [505] = { -- The Dawnbreaker
        activityId = 1285,
        dungeonShorthand = "dawn",
    },
    [506] = { -- Cinderbrew Meadery
        activityId = 1286,
        dungeonShorthand = "brew",
    },
    [525] = { -- Operation: Floodgate
        activityId = 1550,
        dungeonShorthand = "flood",
    },
    [542] = { -- Eco-Dome Al'dani
        activityId = 1694,
        dungeonShorthand = "eda",
    },

    -- Dragonflight
    [399] = { -- Ruby Life Pools
        activityId = 1176,
        dungeonShorthand = "rlp",
    },
    [400] = { -- The Nokhud Offensive
        activityId = 1184,
        dungeonShorthand = "no",
    },
    [401] = { -- The Azure Vault
        activityId = 1180,
        dungeonShorthand = "av",
    },
    [402] = { -- Algeth'ar Academy
        activityId = 1160,
        dungeonShorthand = "aa",
    },
    [403] = { -- Uldaman: Legacy of Tyr
        activityId = 1188,
        dungeonShorthand = "uld",
    },
    [404] = { -- Neltharus
        activityId = 1172,
        dungeonShorthand = "nelt",
    },
    [405] = { -- Brackenhide Hollow
        activityId = 1164,
        dungeonShorthand = "bh",
    },
    [406] = { -- Halls of Infusion
        activityId = 1168,
        dungeonShorthand = "hoi",
    },
    [463] = { -- Dawn of the Infinite: Galakrond's Fall
        activityId = 1247,
        dungeonShorthand = "fall",
    },
    [464] = { -- Dawn of the Infinite: Murozond's Rise
        activityId = 1248,
        dungeonShorthand = "rise",
    },

    -- Shadowlands
    [375] = { -- Mists of Tirna Scithe
        activityId = 703,
        dungeonShorthand = "mists",
    },
    [376] = { -- The Necrotic Wake
        activityId = 713,
        dungeonShorthand = "nw",
    },
    [377] = { -- De Other Side
        activityId = 695,
        dungeonShorthand = "dos",
    },
    [378] = { -- Halls of Atonement
        activityId = 699,
        dungeonShorthand = "hoa",
    },
    [379] = { -- Plaguefall
        activityId = 691,
        dungeonShorthand = "pf",
    },
    [380] = { -- Sanguine Depths
        activityId = 705,
        dungeonShorthand = "sd",
    },
    [381] = { -- Spires of Ascension
        activityId = 709,
        dungeonShorthand = "soa",
    },
    [382] = { -- Theater of Pain
        activityId = 717,
        dungeonShorthand = "top",
    },
    [391] = { -- Tazavesh: Streets of Wonder
        activityId = 1016,
        dungeonShorthand = "strt",
    },
    [392] = { -- Tazavesh: So'leah's Gambit
        activityId = 1017,
        dungeonShorthand = "gmbt",
    },

    -- BfA
    [244] = { -- Atal'Dazar
        activityId = 502,
        dungeonShorthand = "ad",
    },
    [245] = { -- Freehold
        activityId = 518,
        dungeonShorthand = "fh",
    },
    [246] = { -- Tol Dagor
        activityId = 526,
        dungeonShorthand = "td",
    },
    [247] = { -- The MOTHERLODE!!
        activityId = 510,
        dungeonShorthand = "ml",
    },
    [248] = { -- Waycrest Manor
        activityId = 530,
        dungeonShorthand = "wm",
    },
    [249] = { -- Kings' Rest
        activityId = 514,
        dungeonShorthand = "kr",
    },
    [250] = { -- Temple of Sethraliss
        activityId = 504,
        dungeonShorthand = "tos",
    },
    [251] = { -- The Underrot
        activityId = 507,
        dungeonShorthand = "undr",
    },
    [252] = { -- Shrine of the Storm
        activityId = 522,
        dungeonShorthand = "sots",
    },
    [353] = { -- Siege of Boralus
        activityId = 534,
        dungeonShorthand = "siege",
    },
    [369] = { -- Operation: Mechagon - Junkyard
        activityId = 679,
        dungeonShorthand = "yard",
    },
    [370] = { -- Operation: Mechagon - Workshop
        activityId = 683,
        dungeonShorthand = "work",
    },

    -- Legion
    [197] = { -- Eye of Azshara
        activityId = 459,
        dungeonShorthand = "eoa",
    },
    [198] = { -- Darkheart Thicket
        activityId = 460,
        dungeonShorthand = "dht",
    },
    [199] = { -- Black Rook Hold
        activityId = 463,
        dungeonShorthand = "brh",
    },
    [200] = { -- Halls of Valor
        activityId = 461,
        dungeonShorthand = "hov",
    },
    [206] = { -- Neltharion's Lair
        activityId = 462,
        dungeonShorthand = "nl",
    },
    [207] = { -- Vault of the Wardens
        activityId = 464,
        dungeonShorthand = "votw",
    },
    [208] = { -- Maw of Souls
        activityId = 465,
        dungeonShorthand = "mos",
    },
    [209] = { -- The Arcway
        activityId = 467,
        dungeonShorthand = "arc",
    },
    [210] = { -- Court of Stars
        activityId = 466,
        dungeonShorthand = "cos",
    },
    [227] = { -- Return to Karazhan: Lower
        activityId = 471,
        dungeonShorthand = "lowr",
    },
    [233] = { -- Cathedral of Eternal Night
        activityId = 476,
        dungeonShorthand = "coen",
    },
    [234] = { -- Return to Karazhan: Upper
        activityId = 473,
        dungeonShorthand = "uppr",
    },
    [239] = { -- Seat of the Triumvirate
        activityId = 486,
        dungeonShorthand = "seat",
    },

    -- Warlords of Draenor
    [165] = { -- Shadowmoon Burial Grounds
        activityId = 1193,
        dungeonShorthand = "sbg",
    },
    [166] = { -- Grimrail Depot
        activityId = 183,
        dungeonShorthand = "gd",
    },
    [168] = { -- The Everbloom
        activityId = 184,
        dungeonShorthand = "eb",
    },
    [169] = { -- Iron Docks
        activityId = 180,
        dungeonShorthand = "id",
    },
    [161] = { -- Skyreach
        activityId = 182,
        dungeonShorthand = "sky",
    },

    -- Other (Mists, Cataclysm, WOTLK, etc.)
    [2] = { -- Temple of the Jade Serpent
        activityId = 1192,
        dungeonShorthand = "tjs",
    },
    [438] = { -- The Vortex Pinnacle
        activityId = 1195,
        dungeonShorthand = "vp",
    },
    [456] = { -- Throne of the Tides
        activityId = 1274,
        dungeonShorthand = "tott",
    },
    [163] = { -- Bloodmaul Slag Mines
        activityId = 1695,
        dungeonShorthand = "bsm",
    },
    [541] = { -- The Stonecore
        activityId = 1702,
        dungeonShorthand = "stonecore",
    },
    [507] = { -- Grim Batol
        activityId = 1290,
        dungeonShorthand = "gb",
    },
    [556] = { -- Pit of Saron
        activityId = 1770,
        dungeonShorthand = "pit",
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
        self.addon:Printf(L["Missing support for dungeon with map id '%d'. Please open a issue on CurseForge or GitHub."], dungeonID)
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
        self.addon:Printf(L["Missing support for dungeon with map id '%d'. Please open a issue on CurseForge or GitHub."], orlKLeyInfo.challengeMapID)
        return
    end

    return  {
        activityId = info.activityId,
        dungeonShorthand = info.dungeonShorthand,
        level = orlKLeyInfo.level,
        unit = unit,
    }
end
