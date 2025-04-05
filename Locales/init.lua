---@class DBH_Private
local private = select(2, ...)

---@type table<string, string>
private.L = {}

-- Make missing translations available
setmetatable(private.L, {__index = function(self, key)
    self[key] = (key or "")
    return key
end})

---@param fontString FontString
function MPLM_LocalizeFontString(fontString)
    fontString:SetText(private.L[fontString:GetText()])
end
