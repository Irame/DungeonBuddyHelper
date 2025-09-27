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

function private:GenerateRandomUppercaseString(length)
    local result = ""
    for i = 1, length do
        -- ASCII range for 'A' to 'Z' is 65 to 90
        local charCode = math.random(65, 90)
        result = result .. string.char(charCode)
    end
    return result
end

function private:GeneratePassphrase(wordCount)
    wordCount = wordCount or 3 -- default to 3 if not provided

    local wordList = self.WowWords

    -- Shuffle the word list (Fisher-Yates shuffle)
    for i = #wordList, 2, -1 do
        local j = math.random(i) -- random between 1 and i
        wordList[i], wordList[j] = wordList[j], wordList[i]
    end

    -- Concatenate the first wordCount words
    local passphrase = ""
    for i = 1, wordCount do
        passphrase = passphrase .. wordList[i]
    end

    return passphrase
end

