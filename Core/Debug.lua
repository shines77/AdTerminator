
local addonName, addonNS = ...

-- Indent chars define, default is 2 space char
local INDENTS = "  "

function table_len(tab)
    local length = 0
    for k, v in pairs(tab) do
        length = length + 1
    end
    return length
end

local function to_string(obj)
    local str
    if type(obj) == 'string' then
        str = '\"'..obj..'\"'
    elseif type(obj) == 'number' or type(obj) == 'boolean' or type(obj) == 'function' then
        str = tostring(obj)
    elseif type(obj) == 'nil' then
        str = '<nil>'
    elseif type(obj) == 'table' then
        -- Error
        str = "<table> ..."
    else
        -- number, boolean, function ....
        str = tostring(obj)
    end
    return str
end

local function dump_sub_table(obj, depth)
    depth = depth or 0
    if type(obj) == 'table' then
        local indent = string.rep(INDENTS, depth)
        local sb = {}
        table.insert(sb, "{\n")
        local key, value
        for k, v in pairs(obj) do
            if type(k) == 'string' then
                key = '"'..k..'"'
            elseif type(k) == 'table' then
                key = dump_sub_table(k, depth + 1)
            elseif type(k) == 'nil' then
                key = '<nil>'
            else
                -- number, boolean, function ....
                key = tostring(k)
            end
            value = dump_sub_table(v, depth + 1)
            table.insert(sb, indent .. INDENTS .. '['..key..'] = ' .. value .. ',\n')
        end
        table.insert(sb, indent .. "}")
        return table.concat(sb)
    else
        return to_string(obj)
    end
end

local function dump_table(obj)
    if type(obj) == 'table' then
        local sb = {}
        table.insert(sb, "."..INDENTS .. "{\n")
        local key, value
        for k, v in pairs(obj) do
            if type(k) == 'string' then
                key = '\"'..k..'\"'
            elseif type(k) == 'table' then
                key = dump_sub_table(k, 1)
            elseif type(k) == 'nil' then
                key = '<nil>'
            else
                -- number, boolean, function ....
                key = tostring(k)
            end
            value = dump_sub_table(v, 1)
            table.insert(sb, INDENTS .. '['..key..'] = ' .. value .. ',\n')
        end
        table.insert(sb, "}\n")
        return table.concat(sb)
    else
        return to_string(obj)
    end
end

--
-- See: http://lua-users.org/wiki/TableSerialization
--
local function dump_to_string(obj, addQuote)
    local str
    if type(obj) == 'string' then
        if addQuote == true then
            str = '\"'..obj..'\"'
        else
            str = obj
        end
    elseif type(obj) == 'number' or type(obj) == 'boolean' or type(obj) == 'function' then
        str = tostring(obj)
    elseif type(obj) == 'nil' then
        str = '<nil>'
    elseif type(obj) == 'table' then
        str = dump_table(obj)
    else
        str = tostring(obj)
    end
    return str
end

function ADT_ToString(var)
    return dump_to_string(var, true)
end

function ADT_DebugPrint(txt)
    if (addonNS.EnableDebug) then
        local text = dump_to_string(txt)
        if (DEFAULT_CHAT_FRAME) then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd200"..addonName.."|r: "..text)
        end
    end
end
