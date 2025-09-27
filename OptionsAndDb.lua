---@type string
local addonName = ...

---@class DBH_Private
local private = select(2, ...)

local L = private.L

local function GetDbDefaults()
    return {
        global = {
            general = {
                chatKeyLinks = true,
                lfgFrameButton = true,
                openLfgFrame = private.Enum.OpenLfgFrame.OnDialog,
            },
            boilerRoom = {
                specificRequirements = {
                    enabled = true,
                    keyCompletion = {
                        include = true,
                        keyOffset = 1,
                    },
                    bloodlust = {
                        include = true,
                        ignoreHunters = false,
                    },
                    combatRes = {
                        include = true,
                        ignoreHunters = true,
                    },
                },
            },
        },
    }
end

local function GenerateOptions(helpHeader, helpLines)
    local helpDesc = helpHeader
    for i, line in ipairs(helpLines) do
        helpDesc = helpDesc .. "\n" .. line
    end

    local function get(info)
        local db = private.db.global
        for i = 1, #info do
            if db then
                db = db[info[i]]
            else
                return nil
            end
        end
        return db
    end

    local function set(info, value)
        local db = private.db.global
        for i = 1, #info - 1 do
            if not db then
                return
            end

            local key = info[i]
            if not db[key] then
                db[key] = {}
            end

            db = db[key]
        end

        db[info[#info]] = value
    end

    ---@type AceConfig.OptionsTable
    local options = {
        type = "group",
        name = L["DungeonBuddy Helper (NoP)"],
        get = get,
        set = set,
        args = {
            commandHelp = {
                type = "description",
                name = helpDesc .. "\n ",
                fontSize = "medium",
                order = 1,
            },
            general = {
                type = "group",
                name = L["General"],
                order = 2,
                args = {
                    chatKeyLinks = {
                        type = "toggle",
                        name = L["Chat Key Links"],
                        desc = L["Enable links for DBH behind keystones in chat."],
                        order = 1,
                    },
                    lfgFrameButton = {
                        type = "toggle",
                        name = L["LFG Frame Button"],
                        desc = L["Show the button for DBH inside the LFG frame."],
                        order = 2,
                    },
                    openLfgFrame = {
                        type = "select",
                        name = L["Open LFG Frame"],
                        desc = L["Select when/if to open the LFG frame."],
                        values = {
                            [private.Enum.OpenLfgFrame.OnDialog] = L["On Dialog"],
                            [private.Enum.OpenLfgFrame.OnOkay] = L["On Okay"],
                            [private.Enum.OpenLfgFrame.Never] = L["Never"],
                        },
                        order = 3,
                    },
                },
            },
            boilerRoom = {
                type = "group",
                name = L["Boiler Room"],
                order = 3,
                args = {
                    specificRequirements = {
                        type = "group",
                        name = L["Specific Requirements"],
                        order = 1,
                        args = {
                            enabled = {
                                type = "toggle",
                                name = L["Enable"],
                                desc = L["Enable generation of specific requirements."],
                                order = 1,
                            },
                            keyCompletion = {
                                type = "group",
                                name = L["Key Completion"],
                                inline = true,
                                order = 2,
                                args = {
                                    include = {
                                        type = "toggle",
                                        name = L["Include"],
                                        desc = L["Include key completion requirement."],
                                        order = 1,
                                    },
                                    keyOffset = {
                                        type = "range",
                                        name = L["Offset"],
                                        desc = L["Offset used for key completion requirement."],
                                        min = 1, max = 5, step = 1,
                                        order = 2,
                                    },
                                },
                            },
                            bloodlust = {
                                type = "group",
                                name = L["Bloodlust"],
                                inline = true,
                                order = 3,
                                args = {
                                    include = {
                                        type = "toggle",
                                        name = L["Include"],
                                        desc = L["Include Bloodlust requirement."],
                                        order = 1,
                                    },
                                    ignoreHunters = {
                                        type = "toggle",
                                        name = L["Ignore Hunters"],
                                        desc = L["Ignore hunters when checking for Bloodlust."],
                                        order = 2,
                                    },
                                },
                            },
                            combatRes = {
                                type = "group",
                                name = L["Combat Res"],
                                inline = true,
                                order = 4,
                                args = {
                                    include = {
                                        type = "toggle",
                                        name = L["Include"],
                                        desc = L["Include Combat Res requirement."],
                                        order = 1,
                                    },
                                    ignoreHunters = {
                                        type = "toggle",
                                        name = L["Ignore Hunters"],
                                        desc = L["Ignore hunters when checking for Combat Res."],
                                        order = 2,
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }

    return options
end

local function MigrateDb()
    local db = private.db.global
    if not db then
        return
    end

    if db.chatKeyLinks ~= nil then
        db.general.chatKeyLinks = db.chatKeyLinks
        db.chatKeyLinks = nil
    end

    if db.lfgFrameButton ~= nil then
        db.general.lfgFrameButton = db.lfgFrameButton
        db.lfgFrameButton = nil
    end

    if db.openLfgFrame ~= nil then
        db.general.openLfgFrame = db.openLfgFrame
        db.openLfgFrame = nil
    end
end

function private:InitializeDb()
    private.db = LibStub("AceDB-3.0"):New("DungeonBuddyHelperDB", GetDbDefaults(), true)
    MigrateDb()
end

function private:InitializeOptions(helpHeader, helpLines)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, GenerateOptions(helpHeader, helpLines))

    local optionsFrame, optionsFrameId = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, "DungeonBuddy Helper (NoP)")
    return optionsFrame, optionsFrameId
end
