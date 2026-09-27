if GetLocale() ~= "ruRU" then
    return
end

local private = select(2, ...)
local L = private.L

--@localization(locale="ruRU", format="lua_additive_table")@

L["Custom group name (optional):"] = "Своё название группы (необязательно):"
L["Custom name is sent to the bot as listed_as."] = "Своё название передаётся боту в listed_as."
L["Refresh keys"] = "Обновить ключи"
L["Request keys in chat (!keys)"] = "Запросить ключи в чате (!keys)"
L["Send !keys to party chat."] = "Отправить !keys в чат пати."
L["Join a party before requesting keys in chat."] = "Для запроса ключей в чате нужно состоять в пати."
L["Cannot open group creation during combat."] = "Нельзя открыть создание группы в бою."
L["Only the party leader can create a dungeon group."] = "Только лидер пати может создать группу для подземелья."
L["No party keys available. Refresh or paste a keystone link with /dbh."] = "Нет доступных ключей. Обновите список или вставьте ссылку на ключ после /dbh."
