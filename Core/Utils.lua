
local addonName, addonNS = ...

local string_format = string.format

function addonNS.FormatColor(str, r, g, b)
    return string_format('|cff%02x%02x%02x%s|r', r * 255, g * 255, b * 255, str)
end

function addonNS.GetFullName(name, realm)
    if not name then
        return
    end
    if name:find('-', nil, true) then
        return name
    end

    if (not realm) or (realm == '') then
        realm = GetNormalizedRealmName()
    end
    return name .. '-' .. realm
end

function addonNS.GetShortName(fullname)
    if not fullname then
        return
    end
    local first, last = fullname:find('-', nil, true)
    if not first then
        return fullname, GetNormalizedRealmName()
    end

    local name
    if (first > 1) then
        name = string.sub(fullname, 1, first - 1)
    else
        name = ""
    end
    local realm = string.sub(fullname, first + 1, string.len(fullname))
    return name, realm
end

function addonNS.UnitName(unit)
    return addonNS.GetFullName(UnitFullName(unit))
end

--
-- From: https://wowprogramming.com/snippets/UTF-8_aware_stringsub_7.html
--

-- UTF-8 Reference:
-- 0xxxxxxx - 1 byte UTF-8 codepoint (ASCII character)
-- 110yyyxx - First byte of a 2 byte UTF-8 codepoint
-- 1110yyyy - First byte of a 3 byte UTF-8 codepoint
-- 11110zzz - First byte of a 4 byte UTF-8 codepoint
-- 10xxxxxx - Inner byte of a multi-byte UTF-8 codepoint

local function utf8_size_slow(char)
    if not char then
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end

local function utf8_size(char)
    if char >= 224 then
        if char < 240 then
            return 3
        else
            return 4
        end
    elseif char < 192 then
        if char > 0 then
            return 1
        else
            return 0
        end
    else
        return 2
    end
end

-- This function can return a substring of a UTF-8 string, properly handling
-- UTF-8 codepoints.  Rather than taking a start index and optionally an end
-- index, it takes the string, the starting character, and the number of
-- characters to select from the string.

local function utf8_substr(str, startChar, numChars)
    local startIndex = 1
    while startChar > 1 do
        local char = string.byte(str, startIndex)
        startIndex = startIndex + utf8_size(char)
        startChar = startChar - 1
    end

    local totalChars = #str
    local currentIndex = startIndex
    while numChars > 0 and currentIndex <= totalChars do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + utf8_size(char)
        numChars = numChars - 1
    end
    return str:sub(startIndex, currentIndex - 1)
end
