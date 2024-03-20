
local addonName, addonNS = ...
local ThisAddon = addonNS.addon

-- String functions
local table_concat, table_insert = table.concat, table.insert
local string_find, string_sub, string_gsub, string_match, string_gmatch = string.find, string.sub, string.gsub, string.match, string.gmatch
local string_format = string.format
local string_byte, string_char, string_len = string.byte, string.char, string.len

local ALA_PREFIX = 'ATEADD'
local ADT_PROTO_PREFIX = 'AdTerminator'
local ADT_PROTO_VERSION = 2

local Serializer = LibStub('AceSerializer-3.0')
local Encoder = addonNS.Encoder

---@class ChatFilter: AceAddon-3.0, AceEvent-3.0, AceComm-3.0
local ChatFilter = addonNS.addon:NewModule('ChatFilter', 'AceEvent-3.0', 'AceComm-3.0')
ChatFilter.realm = nil
ChatFilter.playerName = nil
ChatFilter.userCache = nil

local lastLineId = 0
local debug_cnt = 0

-- 忽略的空白字符
local ignoreSpaces = {
    " ", "　",
    --".", "`", "~",
}

-- 忽略的尾部无意义字符
local ignoreTailChars = {
    "`", "~", "@", "#", "^", "*", "=", "|", "，", "。", "、", "!", "！"
}

-- 忽略的标点符号
local ignoreSymbols = {
    "`", "~", "@", "#", "^", "*", "=", "|", " ", "，", "。", "、", "？", "！", "：", "；",
    "‘", "’", "“", "”", "【", "】", "『", "』", "《", "》", "<", ">", "（", "）"
}

local blockedKeywordsStr = "招兵,手工,纯手,手动,柯基,科技,预约,点菜,大米,大侎,玉米,出米,收米,木木,站桩,观影,看雪,喝茶,电影,一级一付,一付一,代肝,帮肝,帮打,托管,可托,解放,代练,代充,带冲,作业,R点,先练,后付,出装,再付,见装付,纯需,大哥,大佬,包过,先R,押金,陪玩,一站式,估号,加V,歪歪,成品,跟打,代上,脱坑,连体,曙光,双马,马上开打,现在打,微信,徽信,薇信,WCL可查,不强制,无押,可躺,灵魂兽,大角,螃蟹,RO点,ro点,roll点,ＲＯ,i00,oo,交流,一键宏,W鑫,收鑫,一律我先,1%-%-1,1%-70%-80,55%-70%-80,淘宝,岚风小筑,龙腾四海,流云阁,流芸阁,《辉煌》,《青春》,青 春"

ChatFilter.filters = {}
ChatFilter.filters["CHAT_MSG_CHANNEL"] = {
    enabled = false,
    lastLineId = 0,
    lastBlockedState = false
}
ChatFilter.filters["CHAT_MSG_YELL"] = {
    enabled = false,
    lastLineId = 0,
    lastBlockedState = false
}
ChatFilter.filters["CHAT_MSG_EMOTE"] = {
    enabled = false,
    lastLineId = 0,
    lastBlockedState = false
}
ChatFilter.filters["CHAT_MSG_WHISPER"] = {
    enabled = false,
    lastLineId = 0,
    lastBlockedState = false
}
ChatFilter.filters["CHAT_MSG_SAY"] = {
    enabled = false,
    lastLineId = 0,
    lastBlockedState = false
}
ChatFilter.filters["CHAT_MSG_GUILD"] = {
    enabled = false,
    lastLineId = 0,
    lastBlockedState = false
}

local blockedKeywords = {}

local function string_trim(input, first, last)
    if (last <= first) then
        return first, first
    end
    -- left trim
    local pos = first
    while (pos < last) do
        local c = string_byte(input, pos)
        if c ~= 0x20 then
            break
        else
            pos = pos + 1
        end
    end
    first = pos

    -- Right trim
    pos = last
    while (pos > first) do
        local c = string_byte(input, pos)
        if c ~= 0x20 then
            break
        else
            pos = pos - 1
        end
    end
    last = pos
    return first, last
end

--
-- See: https://blog.csdn.net/fightsyj/article/details/85057634
--
local function string_split(input, delimiter, trim)
    local arr = {}
    if type(delimiter) ~= "string" or #delimiter <= 0 then
        return arr
    end
    local start = 1
    local delim_len = string_len(delimiter)
    while true do
        local pos = string_find(input, delimiter, start, true)
        if not pos then
            break
        end
        if (not trim) then
            table_insert(arr, string_sub(input, start, pos - 1))
        else
            local first, last = string_trim(input, start, pos - 1)
            if (last > first) then
                table_insert(arr, string_sub(input, first, last))
            end
        end
        start = pos + delim_len
    end
    table_insert(arr, string_sub(input, start))
    return arr
end

function ChatFilter:OnInitialize()
    self.realm = nil
    self.playerName = nil
    self.waitingItems = {}
    self.userCache = addonNS.addon.db.global.userCache

    self.db = setmetatable({}, {
        __index = function(_, k)
            return self.userCache[self.realm] and self.userCache[self.realm][self.playerName] and self.userCache[self.realm][self.playerName][k]
        end,
        __newindex = function(_, k, v)
            self.userCache[self.realm] = self.userCache[self.realm] or {}
            self.userCache[self.realm][self.playerName] = self.userCache[self.realm][self.playerName] or {}
            self.userCache[self.realm][self.playerName][k] = v
        end,
    })

    blockedKeywords = string_split(blockedKeywordsStr, ",")
    --ADT_DebugPrint("blockedKeywords = ", blockedKeywords)

    -- Print a message to the chat frame
    ThisAddon:Print("ChatFilter:OnInitialize Event Fired.")
end

function ChatFilter:OnAlaCommand(_, msg, channel, sender)
    local data = addonNS.Ala:RecvComm(msg, channel, sender)
    if not data then
        return
    end

    self:UpdateCharacter(sender, data)
end

function ChatFilter:OnEnable()
    local function Deal(sender, ok, cmd, ...)
        if ok then
            return self:OnComm(cmd, addonNS.GetFullName(sender), ...)
        end
    end

    local function OnComm(_, msg, d, sender)
        return Deal(sender, Serializer:Deserialize(msg))
    end

    --self:RegisterEvent('GET_ITEM_INFO_RECEIVED')
    self:RegisterEvent('INSPECT_READY')
    --self:RegisterComm(ALA_PREFIX, 'OnAlaCommand')
    self:RegisterComm(ADT_PROTO_PREFIX, OnComm)

    self:RegisterFilters(true, true)

    -- Print a message to the chat frame
    ThisAddon:Print("ChatFilter:OnEnable Event Fired.")
end

function ChatFilter:INSPECT_READY(_, guid)
    if not self.unit then
        return
    end
end

function ChatFilter:BuildCharacterDb(name, realm)
    self.userCache[realm] = self.userCache[realm] or {}
    self.userCache[realm][name] = self.userCache[realm][name] or {}
    self.userCache[realm][name].timestamp = time()
    return self.userCache[realm][name]
end

function ChatFilter:UpdateCharacter(name, realm, data)
    local db = self:BuildCharacterDb(name, realm)
end

--
-- See: https://blog.csdn.net/DemonsLee/article/details/115075173
--
local function filterIgnoreSpaces(text)
    for _, spaceChar in ipairs(ignoreSpaces) do
        text = string_gsub(text, spaceChar, "")
    end
    return text
end

local function containsKeyWord(text, keywords)
    for _, keyword in ipairs(keywords) do
        if text:find(keyword) then
            return true
        end
    end
    return false
end

local function filterUserMessage(name, realm, message, lineId, guid, channelName, channelBaseName)
    local userCache = ThisAddon.db.global.userCache
    ChatFilter:UpdateCharacter(name, realm)
    return false
end

local function ChatFilter_DebugPrintMessage(self, event, message, author, languageName, channelName, target, specialFlags, zoneChannelId, channelIndex, channelBaseName, languageId, lineId, guid, bnSenderId, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    ADT_DebugPrint("message = ", message)
    ADT_DebugPrint("author = ", author)
    local text = string_format("[%d][%d.%s][%s]: [%s]", lineId, channelIndex, channelBaseName, author, message)
    ADT_DebugPrint(text)
end

local function ChatFilter_ChannelFilter(self, event, message, author, languageName, channelName, target, specialFlags, zoneChannelId, channelIndex, channelBaseName, languageId, lineId, guid, bnSenderId, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    local filter = ChatFilter.filters["CHAT_MSG_CHANNEL"]
    if filter.enabled then
        if lineId ~= lastLineId then
            if debug_cnt < 100 then
                --ChatFilter_DebugPrintMessage(self, event, message, author, languageName, channelName, target, specialFlags, zoneChannelId, channelIndex, channelBaseName, languageId, lineId, guid, bnSenderId, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
                debug_cnt = debug_cnt + 1
            end
            lastLineId = lineId
            --local name, realm = addonNS.GetShortName(author)
            --ADT_DebugPrint("name = ", name, ", realm = ", realm)
            local newBlocked = filterUserMessage(name, realm, message, lineId, guid, channelName, channelBaseName)
            local filterMessage = filterIgnoreSpaces(message)
            local blocked = containsKeyWord(filterMessage, blockedKeywords)
            filter.lastLineId = lineId
            filter.lastBlockedState = blocked
            return blocked
        else
            assert(lineId == filter.lastLineId)
            return filter.lastBlockedState
        end
    else
        return false
    end
end

local function ChatFilter_YellFilter(self, event, message, author, languageName, channelName, target, specialFlags, zoneChannelId, channelIndex, channelBaseName, languageId, lineId, guid, bnSenderId, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    local filter = ChatFilter.filters["CHAT_MSG_YELL"]
    if filter.enabled then
        if lineId ~= lastLineId then
            if debug_cnt < 100 then
                --ChatFilter_DebugPrintMessage(self, event, message, author, languageName, channelName, target, specialFlags, zoneChannelId, channelIndex, channelBaseName, languageId, lineId, guid, bnSenderId, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
                debug_cnt = debug_cnt + 1
            end
            lastLineId = lineId
            local filterMessage = filterIgnoreSpaces(message)
            local blocked = containsKeyWord(filterMessage, blockedKeywords)
            filter.lastLineId = lineId
            filter.lastBlockedState = blocked
            return blocked
        else
            assert(lineId == filter.lastLineId)
            return filter.lastBlockedState
        end
    else
        return false
    end
end

function ChatFilter:RegisterFilter(evnet, filterFunc, enable, isInit)
    assert(evnet)
    if (self.filters[evnet]) then
        if (enable or isInit) then
            if ((not self.filters[evnet].enabled) or isInit) then
                assert(filterFunc)
                ThisAddon:Print("ChatFrame_AddMessageEventFilter(): "..evnet)
                ChatFrame_AddMessageEventFilter(evnet, filterFunc)
                self.filters[evnet].enabled = true
            end
        else
            if (self.filters[evnet].enabled) then
                assert(filterFunc)
                ThisAddon:Print("ChatFrame_RemoveMessageEventFilter(): "..evnet)
                ChatFrame_RemoveMessageEventFilter(evnet, filterFunc)
                self.filters[evnet].enabled = false
            end
        end
    end
end

function ChatFilter:RegisterFilters(enable, isInit)
    ChatFilter:RegisterFilter("CHAT_MSG_CHANNEL", ChatFilter_ChannelFilter, enable, isInit)
    ChatFilter:RegisterFilter("CHAT_MSG_YELL",    ChatFilter_YellFilter,    enable, isInit)
end
