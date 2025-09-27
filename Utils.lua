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

--- Creates a simple RNG function based on a seed
--- The returned function generates pseudo-random numbers.
--- If min and max are provided, it returns a number in that range (inclusive).
--- Otherwise, it returns a number between 0 and 32767.
---@param seed number? Seed value for the RNG. If nil, defaults to time().
---@return fun(min: integer, max: integer): integer
function private:CreateRNG(seed)
    local state = seed or time()
    return function(min, max)
        -- LCG params (same as POSIX rand)
        state = (1103515245 * state + 12345) % 0x80000000
        local r = bit.rshift(state, 16) % 0x7FFF
        if min and max then
            return min + (r % (max - min + 1))
        end
        return r
    end
end

function private:GenerateRandomUppercaseString(length, seed)
    local rng = self:CreateRNG(seed)

    local result = ""
    for i = 1, length do
        -- ASCII range for 'A' to 'Z' is 65 to 90
        local charCode = rng(65, 90)
        result = result .. string.char(charCode)
    end
    return result
end

function private:GeneratePassphrase(wordCount, seed)
    local rng = self:CreateRNG(seed)

    wordCount = wordCount or 3 -- default to 3 if not provided

    local wordIndices = {}
    for i = 1, #self.WowWords do
        table.insert(wordIndices, i)
    end

    -- Shuffle the word list (Fisher-Yates shuffle)
    for i = #wordIndices, 2, -1 do
        local j = rng(1, i) -- random between 1 and i
        wordIndices[i], wordIndices[j] = wordIndices[j], wordIndices[i]
    end

    -- Concatenate the first wordCount words
    local passphrase = ""
    for i = 1, wordCount do
        passphrase = passphrase .. self.WowWords[wordIndices[i]]
    end

    return passphrase
end

