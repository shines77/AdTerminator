--
-- AdTerminator.lua
-- @Author : guoxionghui
-- @Link   : https://github.com/guoxionghui/AdTerminator
-- @Link   : https://gitee.com/guoxionghui/AdTerminator
-- @Create : $date_time$
-- @Date   : $date_time$
--

AdTerminator = LibStub("AceAddon-3.0"):NewAddon("AdTerminator", "AceConsole-3.0", "AceEvent-3.0" );

function AdTerminator:PrintCmd(input)
    input = input:trim():match("^(.-);*$")
    local func, err = loadstring("LibStub(\"AceConsole-3.0\"):Print(" .. input .. ")")
    if not func then
        LibStub("AceConsole-3.0"):Print("Error: " .. err)
    else
        func()
    end
end

function AdTerminator:OnInitialize()
	-- Called when the addon is loaded
    self:RegisterChatCommand("print", "PrintCmd")

	-- Print a message to the chat frame
	self:Print("OnInitialize Event Fired: Hello")
end

function AdTerminator:OnEnable()
	-- Called when the addon is enabled

	-- Print a message to the chat frame
	self:Print("OnEnable Event Fired: Hello, again :-)")
end

function AdTerminator:OnDisable()
	-- Called when the addon is disabled

    -- Print a message to the chat frame
    self:Print("OnDisable Event Fired: bye bye.")
end
