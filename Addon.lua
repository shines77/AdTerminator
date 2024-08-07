--
-- Addon.lua
-- @Author : GuoXH(gz_shines@msn.com)
-- @Link   : https://github.com/shines77/AdTerminator
-- @Link   : https://gitee.com/shines77/AdTerminator
-- @Create : $date_time$
-- @Date   : $date_time$
--

local addonName, addonNS = ...
addonNS.EnableDebug = true

--ADT_DebugPrint("addonName = "..ADT_ToString(addonName))
--ADT_DebugPrint("addonNS = "..ADT_Dump(addonNS))

local GetAddOnMetadata = GetAddOnMetadata or C_AddOns.GetAddOnMetadata
local addonVersion = GetAddOnMetadata(addonName, "Version") or "1.0.0"
local addonFlavor = GetAddOnMetadata(addonName, "X-Flavor") or "Wrath"

--ADT_DebugPrint("addonVersion = "..addonVersion)
--ADT_DebugPrint("addonFlavor = "..addonFlavor)

-- version, build, date, tocVersion = GetBuildInfo()
local clientVersionString, clientBuild = GetBuildInfo()
--ADT_DebugPrint("clientVersionString = "..clientVersionString)
--ADT_DebugPrint("clientBuild = "..clientBuild)

local _, _, clientVerMajor, clientVerMinor, clientVerPatch = string.find(clientVersionString, "^(%d+)%.?(%d+)%.?(%d+)%s*")

clientVerMajor = tonumber(clientVerMajor)
clientVerMinor = tonumber(clientVerMinor)
clientVerPatch = tonumber(clientVerPatch)

--ADT_DebugPrint("clientVerMajor = "..clientVerMajor)
--ADT_DebugPrint("clientVerMinor = "..clientVerMinor)
--ADT_DebugPrint("clientVerPatch = "..clientVerPatch)

local L = LibStub('AceLocale-3.0'):GetLocale(addonName)

addonNS.L = L
addonNS.UI = {}

addonNS.VersionText = addonVersion
addonNS.Version = tonumber((addonVersion:gsub('(%d+)%.?', function(x)
    return format('%02d', tonumber(x))
end))) or 0

---@class Addon: AceAddon-3.0, LibClass-2.0, AceConsole-3.0, AceEvent-3.0
local Addon = LibStub('AceAddon-3.0'):NewAddon(tostring(addonName), 'AceConsole-3.0', 'LibClass-2.0', 'AceEvent-3.0')
addonNS.addon = Addon
--_G[addonName] = Addon

Addon.IsRetail = function()
    return (clientVerMajor >= 10) or (addonFlavor == "Retail")
end
Addon.IsMop = function()
    return (clientVerMajor == 5)
end
Addon.IsCata = function()
    return (clientVerMajor == 4)
end
Addon.IsWrath = function()
    return (clientVerMajor == 3)
end
Addon.IsTBC = function()
    return (clientVerMajor == 2)
end
Addon.IsClassic = function()
    return (clientVerMajor == 1)
end
Addon.IsDragonflight = function()
    return (select(4, GetBuildInfo()) >= 100000)
end

Addon.Visibled = false

-- load only on classic/tbc/wotlk/cata/mop
if not(Addon.IsClassic() or Addon.IsTBC() or Addon.IsWrath() or Addon.IsCata() or Addon.IsMop()) then
    return
end

local CT_NewTicker = C_Timer.NewTicker
local CT_After = C_Timer.After

_G.BINDING_HEADER_AdTerminator = addonName
_G.BINDING_NAME_AdTerminator_SHOW_UI = addonNS.L["Show/Hide AdTerminator"]

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
    local profile = {
        global = {
            version = addonNS.Version,
            userCache = {},
        },
        profile = {
            showModel = true,
        },
    }

    ---@type AdTerminatorProfile
    self.db = LibStub("AceDB-3.0"):New("AdTerminator_DB", profile, true)

    if not self.db.global.version or self.db.global.version < 10000 then
        --wipe(self.db.global.userCache)
    end

    -- Called when the addon is loaded
    self:RegisterChatCommand("print", "PrintCmd")

    -- Print a message to the chat frame
    --self:Print("AdTerminator:OnInitialize() Fired.")

    --ADT_DebugPrint("profile = "..ADT_Dump(profile))
end

function Addon:OnEnable()
    -- Called when the addon is enabled

    self:RegisterEvent('ADDON_LOADED')
    --self:RegisterMessage('INSPECT_READY')

    -- Print a message to the chat frame
    --self:Print("AdTerminator:OnEnable() Fired.")
end

function Addon:OnDisable()
    -- Called when the addon is disabled

    -- Print a message to the chat frame
    --self:Print("AdTerminator:OnDisable() Fired.")
end

function Addon:OnModuleCreated(module)
    addonNS[module:GetName()] = module
end

function Addon:OnClassCreated(class, name)
    self:Print("AdTerminator:OnClassCreated() Fired.")
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

function AdTerminator_ShowUI()
    if Addon.Visibled then
        --Hidden
        print("Hidden AddFilter UI.")
        Addon.Visibled = false
    else
        --Show
        print("Show AddFilter UI.")
        Addon.Visibled = true
    end
end
