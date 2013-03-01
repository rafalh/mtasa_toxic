--------------
-- Includes --
--------------

#include "..\\include\\serv_verification.lua"

---------------------
-- Local variables --
---------------------

local g_Root = getRootElement()
local g_Me = getLocalPlayer()
local g_ScrW, g_ScrH = guiGetScreenSize()
local g_InputBox = false
local g_ChatFonts = { [0] = "default", [1] = "clear", [2] = "default-bold", [3] = "arial" }
local g_IsKeyBound = false

local BLACK = tocolor(0, 0, 0)

-------------------
-- Custom events --
-------------------

addEvent("onModChatStart", true)
addEvent("onClientSetMod", true)
addEvent("onModChat", true)

---------------------------------
-- Local function declarations --
---------------------------------

local McRender

--------------------------------
-- Local function definitions --
--------------------------------

local function McDisableInput()
	if(not isMainMenuActive()) then
		guiSetInputEnabled(false)
		removeEventHandler("onClientPreRender", g_Root, McDisableInput)
	end
end

local function McCloseInputBox()
	if(not g_InputBox) then
		return
	end
	removeEventHandler("onClientRender", g_Root, McRender)
	destroyElement(g_InputBox)
	g_InputBox = false
	addEventHandler("onClientPreRender", g_Root, McDisableInput)
	
	triggerServerEvent("onPlayerChatting", g_Me, false)
end

local function onChatSay(edit)
	local msg = tostring(guiGetText(edit))
	if(msg ~= "") then
		triggerServerEvent("onModChat", g_Me, msg)
	end
	McCloseInputBox()
end

McRender = function() -- used by McCloseInputBox
	if(isMainMenuActive()) then
		McCloseInputBox()
		return
	end
	guiBringToFront(g_InputBox)
	guiSetInputEnabled(true)
	
	local chatbox_layout = getChatboxLayout()
	local font = g_ChatFonts[chatbox_layout.chat_font] or "default"
	local w = chatbox_layout.chat_width * 320 * chatbox_layout.chat_scale[1]
	local h = dxGetFontHeight(chatbox_layout.text_scale, font)
	local x = g_ScrW*0.013
	local y = g_ScrH*0.015 + (h * chatbox_layout.chat_lines + 8) * chatbox_layout.chat_scale[2]
	local prefix = "Modsay:"
	
	chatbox_layout.chat_input_prefix_color = {255, 255, 255, 255} -- MTA does not use it
	
	local transparentBg = (chatbox_layout.chat_input_color[4] == 0)
	if(not transparentBg) then
		local bgClr = tocolor(unpack(chatbox_layout.chat_input_color))
		dxDrawRectangle(x, y, w, h + 4, bgClr)
	else -- input field does not have background
		dxDrawText(prefix, x + 6, y + 3, 0, 0, BLACK, chatbox_layout.text_scale, font)
	end
	local inputPrefixClr = tocolor(unpack(chatbox_layout.chat_input_prefix_color))
	dxDrawText(prefix, x + 5, y + 2, 0, 0, inputPrefixClr, chatbox_layout.text_scale, font)
	local p_w = dxGetTextWidth(prefix, chatbox_layout.text_scale, font)
	local text = guiGetText(g_InputBox)
	if(transparentBg) then -- input field does not have background
		dxDrawText(text, x + 10 + p_w, y + 3, w + 18, y + h + 4, BLACK, chatbox_layout.text_scale, font, "left", "top", true)
	end
	local inputTextClr = tocolor(unpack(chatbox_layout.chat_input_text_color))
	dxDrawText(text, x + 9 + p_w, y + 2, w + 18, y + h + 4, inputTextClr, chatbox_layout.text_scale, font, "left", "top", true)
end

local function McKeyDown()
	if(g_InputBox) then
		McCloseInputBox()
		return
	end
	
	g_InputBox = guiCreateEdit(0, 0, 0, 0, "", false)
	guiSetAlpha(g_InputBox, 0)
	guiSetProperty(g_InputBox, "MaxTextLength", "128")
	guiEditSetReadOnly(g_InputBox, true)
	addEventHandler("onClientGUIAccepted", g_InputBox, onChatSay)
	guiBringToFront(g_InputBox)
	guiSetInputEnabled(true)
	addEventHandler("onClientRender", g_Root, McRender)
	
	triggerServerEvent("onPlayerChatting", g_Me, true)
end

local function McKeyUp()
	if(g_InputBox) then
		guiEditSetReadOnly(g_InputBox, false)
	end
end

local function McClientSetMod()
	if(not g_IsKeyBound) then
		bindKey("u", "down", McKeyDown)
		bindKey("u", "up", McKeyUp)
		g_IsKeyBound = true
	end
end

------------
-- Events --
------------

#VERIFY_SERVER_BEGIN("910DC45D77CE0ED2A2B6DC1994F2ACD1" )
	addEventHandler("onClientSetMod", root, McClientSetMod)
	triggerServerEvent("onModChatStart", localPlayer)
#VERIFY_SERVER_END ()
