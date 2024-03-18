
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
