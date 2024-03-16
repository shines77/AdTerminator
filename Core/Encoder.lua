
local addonName, addonNS = ...

local bit_band, bit_rshift, bit_lshift = bit.band, bit.rshift, bit.lshift
local table_concat, table_insert = table.concat, table.insert
local table_sort = table.sort
local string_sub, string_byte, string_char, string_rep = string.sub, string.byte, string.char, string.rep
local math_floor = math.floor
local ripairs = ipairs_reverse

local R = 128

local NEG = '-'
local LINK_SEP = ':'
local MAJOR_SEP = '!'
local MINOR_SEP = LINK_SEP

local Encoder = {}
addonNS.Encoder = Encoder

function Encoder:EncodeInteger(v)
    local s = {}
    local n
    v = tonumber(v)
    if not v then
        return
    end
    if v < 0 then
        s[1] = NEG
        v = -v
    end
    while v > 0 do
        n = bit_band(v, 127)
        s[#s + 1] = string_char(n + R)
        v = bit_rshift(v, 7)
    end
    return table_concat(s)
end

function Encoder:DecodeInteger(code)
    if code == '' then
        return
    end
    local isNeg = (string_sub(code, 1, 1) == NEG)
    local v = 0
    local n
    for i = #code, isNeg and 2 or 1, -1 do
        n = string_byte(string_sub(code, i, i)) - R
        v = bit_lshift(v, 7) + n
    end
    return isNeg and -v or v
end
