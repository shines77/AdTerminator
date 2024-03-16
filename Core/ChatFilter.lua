
local addonName, addonNS = ...

-- String functions
local table_concat, table_insert = table.concat, table.insert
local string_find, string_sub, string_gsub, string_match, string_gmatch = string.find, string.sub, string.gsub, string.match, string.gmatch
local string_byte, string_char, string_len = string.byte, string.char, string.len

local ALA_PREFIX = 'ATEADD'
local ADT_PROTO_PREFIX = 'AdTerminator'
local ADT_PROTO_VERSION = 2

local Serializer = LibStub('AceSerializer-3.0')
local Encoder = addonNS.Encoder

---@class ChatFilter: AceAddon-3.0, AceEvent-3.0, AceComm-3.0
local ChatFilter = addonNS.Addon:NewModule('ChatFilter', 'AceEvent-3.0', 'AceComm-3.0')

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

local blockedKeywordsStr = "招兵,手工,纯手,手动,柯基,科技,预约,点菜,大米,大侎,玉米,出米,收米,木木,站桩,观影,看雪,喝茶,电影,一级一付,一付一,代肝,帮肝,帮打,托管,可托,解放,代练,代充,带冲,作业,R点,先练,后付,出装,再付,见装付,纯需,大哥,大佬,包过,先R,押金,陪玩,一站式,估号,加V,歪歪,成品,跟打,代上,脱坑,连体,曙光,双马,马上开打,现在打,微信,徽信,薇信,WCL可查,不强制,无押,可躺,灵魂兽,大角,螃蟹,RO点,ro点,roll点,ＲＯ,i00,oo,交流,一键宏,W鑫,收鑫,一律我先,1%-%-1,1%-70%-80,55%-70%-80,淘宝,岚风小筑,龙腾四海,流云阁,流芸阁,《辉煌》,《青春》"

ChatFilter.filters = {}
ChatFilter.filters["CHAT_MSG_CHANNEL"] = {
    enable = false,
    lastLineId = 0,
    lastBlockedState = false
}
ChatFilter.filters["CHAT_MSG_YELL"] = {
    enable = false,
    lastLineId = 0,
    lastBlockedState = false
}
ChatFilter.filters["CHAT_MSG_EMOTE"] = {
    enable = false,
    lastLineId = 0,
    lastBlockedState = false
}
ChatFilter.filters["CHAT_MSG_WHISPER"] = {
    enable = false,
    lastLineId = 0,
    lastBlockedState = false
}
ChatFilter.filters["CHAT_MSG_SAY"] = {
    enable = false,
    lastLineId = 0,
    lastBlockedState = false
}
ChatFilter.filters["CHAT_MSG_GUILD"] = {
    enable = false,
    lastLineId = 0,
    lastBlockedState = false
}

function ChatFilter:OnInitialize()
    self.unitName = nil
    self.waitingItems = {}
    self.userCache = addonNS.Addon.db.global.userCache

    self.db = setmetatable({}, {
        __index = function(_, k)
            return self.userCache[self.unitName] and self.userCache[self.unitName][k]
        end,
        __newindex = function(_, k, v)
            self.userCache[self.unitName] = self.userCache[self.unitName] or {}
            self.userCache[self.unitName][k] = v
        end,
    })
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
end

function ChatFilter:BuildCharacterDb(name)
    self.userCache[name] = self.userCache[name] or {}
    self.userCache[name].timestamp = time()
    return self.userCache[name]
end

function ChatFilter:UpdateCharacter(name, data)
    local db = self:BuildCharacterDb(name)
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

function ChatFilter:DebugPrintMessage(event, message, author, languageName, channelName, target, specialFlags, zoneChannelId, channelIndex, channelBaseName, languageId, lineId, guid, bnSenderId, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    ADT_DebugPrint("message = ", message)
    ADT_DebugPrint("author = ", author)
    local text = string_format("[%d][%d.%s][%s]: [%s]", lineId, channelIndex, channelBaseName, author, message)
    ADT_DebugPrint(text)
end

function ChatFilter:ChannelFilter(self, event, message, author, languageName, channelName, target, specialFlags, zoneChannelId, channelIndex, channelBaseName, languageId, lineId, guid, bnSenderId, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    local filter = self.filters["CHAT_MSG_CHANNEL"]
    if filter.enable then
        if lineId ~= lastLineId then
            if debug_cnt < 100 then
                self:DebugPrintMessage(event, message, author, languageName, channelName, target, specialFlags, zoneChannelId, channelIndex, channelBaseName, languageId, lineId, guid, bnSenderId, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
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

function ChatFilter:YellFilter(self, event, message, author, languageName, channelName, target, specialFlags, zoneChannelId, channelIndex, channelBaseName, languageId, lineId, guid, bnSenderId, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    local filter = self.filters["CHAT_MSG_YELL"]
    if filter.enable then
        if lineId ~= lastLineId then
            if debug_cnt < 100 then
                self:DebugPrintMessage(event, message, author, languageName, channelName, target, specialFlags, zoneChannelId, channelIndex, channelBaseName, languageId, lineId, guid, bnSenderId, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
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

function ChatFilter:RegisterFilter(evnet, filter, enable, isInit)
    assert(evnet)
    if (self.filters[evnet]) then
        if (enable or isInit) then
            if (isInit or (not self.filters[evnet].enabled)) then
                assert(filter)
                ChatFrame_AddMessageEventFilter(evnet, filter)
                self.filters[evnet].enabled = true
            end
        else
            if (self.filters[evnet].enabled) then
                assert(filter)
                ChatFrame_RemoveMessageEventFilter(evnet, filter)
                self.filters[evnet].enabled = false
            end
        end
    end
end

function ChatFilter:RegisterFilters(enable, isInit)
    ChatFilter:RegisterFilter("CHAT_MSG_CHANNEL", ChatFilter:ChannelFilter, enable, isInit)
    ChatFilter:RegisterFilter("CHAT_MSG_YELL",    ChatFilter:YellFilter,    enable, isInit)
end
