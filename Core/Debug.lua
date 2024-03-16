
local addonName, addonNS = ...

local table_concat, table_insert = table.concat, table.insert
local string_sub, string_byte, string_char, string_rep = string.sub, string.byte, string.char, string.rep

-- Indent chars define, default is 2 space char
local INDENTS = "  "
local TitleColor = "ffffd200"

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
        local indent = string_rep(INDENTS, depth)
        local sb = {}
        table_insert(sb, "{\n")
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
            table_insert(sb, indent .. INDENTS .. '['..key..'] = ' .. value .. ',\n')
        end
        table_insert(sb, indent .. "}")
        return table_concat(sb)
    else
        return to_string(obj)
    end
end

local function dump_table(obj)
    if type(obj) == 'table' then
        local sb = {}
        table_insert(sb, "."..INDENTS .. "{\n")
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
            table_insert(sb, INDENTS .. '['..key..'] = ' .. value .. ',\n')
        end
        table_insert(sb, "}\n")
        return table_concat(sb)
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

local function DefaultChatFrame_AddMessage(text)
    if (DEFAULT_CHAT_FRAME) then
        DEFAULT_CHAT_FRAME:AddMessage("|c"..TitleColor..addonName.."|r: "..text)
    end
end

function ADT_ToString(var)
    return dump_to_string(var, true)
end

function ADT_DebugPrint(txt)
    if (addonNS.EnableDebug) then
        local text = dump_to_string(txt)
        DefaultChatFrame_AddMessage(text)
    end
end

function ADT_DebugPrint(prefix, txt)
    if (addonNS.EnableDebug) then
        local text = dump_to_string(txt)
        DefaultChatFrame_AddMessage(tostring(prefix)..text)
    end
end

function ADT_DebugPrintv(...)
    if (addonNS.EnableDebug) then
        local argn = select('#', ...)
        local text = ""
        local i
        if argn == 0 then return end
        for i = 1, argn - 1 do
            text = text..dump_to_string(select(i, ...))
        end
        DefaultChatFrame_AddMessage(text)
    end
end

function ADT_DebugPrintf(fmt, ...)
    if (addonNS.EnableDebug) then
        local text = string_format(fmt, ...)
        DefaultChatFrame_AddMessage(text)
    end
end
