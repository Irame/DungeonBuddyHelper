---@class DBH_Private
local private = select(2, ...)

private.Enum = {}

function private:IterPartyMembers()
    local i = -1
    return function()
        i = i + 1

        if i == 0 then
            return "player"
        end

        if i >= GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) then
            return
        end

        return "party" .. i
    end
end

function private:IterPartyKeys()
    local partyIter = self:IterPartyMembers()
    return function()
        while true do
            local unit = partyIter()
            if not unit then
                return
            end

            local keyInfo = private:GetKeystoneInfoForUnit(unit)
            if keyInfo then
                return keyInfo
            end
        end
    end
end
