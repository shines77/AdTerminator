
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

-- ���ԵĿհ��ַ�
local ignoreSpaces = {
    " ", "��",
    --".", "`", "~",
}

-- ���Ե�β���������ַ�
local ignoreTailChars = {
    "`", "~", "@", "#", "^", "*", "=", "|", "��", "��", "��", "!", "��"
}

-- ���Եı�����
local ignoreSymbols = {
    "`", "~", "@", "#", "^", "*", "=", "|", " ", "��", "��", "��", "��", "��", "��", "��",
    "��", "��", "��", "��", "��", "��", "��", "��", "��", "��", "<", ">", "��", "��"
}

local blockedKeywordsStr = "�б�,�ֹ�,����,�ֶ�,�»�,�Ƽ�,ԤԼ,���,����,���,����,����,����,ľľ,վ׮,��Ӱ,��ѩ,�Ȳ�,��Ӱ,һ��һ��,һ��һ,����,���,���,�й�,����,���,����,����,����,��ҵ,R��,����,��,��װ,�ٸ�,��װ��,����,���,����,����,��R,Ѻ��,����,һվʽ,����,��V,����,��Ʒ,����,����,�ѿ�,����,���,˫��,���Ͽ���,���ڴ�,΢��,����,ޱ��,WCL�ɲ�,��ǿ��,��Ѻ,����,�����,���,�з,RO��,ro��,roll��,�ң�,i00,oo,����,һ����,W��,����,һ������,1%-%-1,1%-70%-80,55%-70%-80,�Ա�,᰷�С��,�����ĺ�,���Ƹ�,��ܿ��,���Ի͡�,���ഺ��"

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
