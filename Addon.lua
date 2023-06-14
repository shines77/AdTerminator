--
-- Addon.lua
-- @Author : guoxionghui
-- @Link   : https://github.com/guoxionghui/AdTerminator
-- @Link   : https://gitee.com/guoxionghui/AdTerminator
-- @Create : $date_time$
-- @Date   : $date_time$
--

local addonName, addonNS = ...
local addonVersion = GetAddOnMetadata(addonName, "Version") or "1.0.0"

local clientVersionString = GetBuildInfo()
local clientBuildMajor = string.byte(clientVersionString, 1)

-- load only on classic/tbc/wotlk
if (clientBuildMajor < 49 or clientBuildMajor > 51 or string.byte(clientVersionString, 2) ~= 46) then
    return
end

local ShowUIPanel = LibStub('LibShowUIPanel-1.0').ShowUIPanel

addonNS.UI = {}
addonNS.L = LibStub('AceLocale-3.0'):GetLocale(addonName)

addonNS.VERSION_TEXT = addonVersion
addonNS.VERSION = tonumber((addonVersion:gsub('(%d+)%.?', function(x)
    return format('%02d', tonumber(x))
end))) or 0

local L = AdTerminator_Locale
local ThisAddon = _G[addonName]

local CT_NewTicker = C_Timer.NewTicker
local CT_After = C_Timer.After

_G.BINDING_HEADER_AdTerminator = addonName
_G.BINDING_NAME_AdTerminator_SHOW_UI = addonNS.L["Show/Hide AdTerminator"]

---@class Addon: AceAddon-3.0, LibClass-2.0, AceConsole-3.0, AceEvent-3.0
local Addon = LibStub('AceAddon-3.0'):NewAddon(addonName, 'LibClass-2.0', 'AceConsole-3.0', 'AceEvent-3.0')
addonNS.Addon = Addon

function Addon:PrintCmd(input)
    input = input:trim():match("^(.-);*$")
    local func, err = loadstring("LibStub(\"AceConsole-3.0\"):Print(" .. input .. ")")
    if not func then
        LibStub("AceConsole-3.0"):Print("Error: " .. err)
    else
        func()
    end
end

function Addon:OnInitialize()
    ---@class AdTerminatorProfile
    local profile = { --
        global = { --
            userCache = {},
        },
        profile = { --
            showModel = true,
        },
    }

    ---@type AdTerminatorProfile
    self.db = LibStub('AceDB-3.0'):New('AdTerminator_Config', profile, true)

    if not self.db.global.version or self.db.global.version < 10000 then
        --wipe(self.db.global.userCache)
    end

    -- Called when the addon is loaded
    self:RegisterChatCommand("print", "PrintCmd")

    -- Print a message to the chat frame
    self:Print("OnInitialize Event Fired: Hello")
end

function Addon:OnEnable()
    -- Called when the addon is enabled

    self:RegisterEvent('ADDON_LOADED')
    --self:RegisterMessage('INSPECT_READY')

    -- Print a message to the chat frame
    self:Print("OnEnable Event Fired: Hello, again :-)")
end

function Addon:OnDisable()
    -- Called when the addon is disabled

    self:UnregisterEvent('ADDON_LOADED')

    -- Print a message to the chat frame
    self:Print("OnDisable Event Fired: bye bye.")
end

function Addon:OnModuleCreated(module)
    addonNS[module:GetName()] = module
end

function Addon:OnClassCreated(class, name)
    local uiName = name:match('^UI%.(.+)$')
    if uiName then
        addonNS.UI[uiName] = class
        LibStub('AceEvent-3.0'):Embed(class)
    else
        addonNS[name] = class
    end
end

function Addon:SetupUI()
    -- Setup something
end

function Addon:ADDON_LOADED(_, addon)
    if addon ~= 'Blizzard_InspectUI' then
        return
    end

    self:SetupUI()
    self:UnregisterEvent('ADDON_LOADED')
end
