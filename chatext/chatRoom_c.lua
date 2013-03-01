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
local g_ChatFonts = { [0] = "default", [1] = "clear", [2] = "default-bold", [3] = "arial" }

local BLACK = tocolor(0, 0, 0)

-------------------
-- Custom events --
-------------------

addEvent("chatext.onReady", true)
addEvent("chatext.onMsg", true)

---------------------------------
-- Local function declarations --
---------------------------------

ChatRoom = {}
ChatRoom.__mt = {__index = ChatRoom}
ChatRoom.keyToRoom = {}
ChatRoom.visibleRoom = false

--------------------------------
-- Local function definitions --
--------------------------------

function ChatRoom:openInput()
	if(ChatRoom.visibleRoom) then
		ChatRoom.visibleRoom:closeInput()
	end
	
	self.inputBox = guiCreateEdit(0, 0, 0, 0, "", false)
	guiSetAlpha(self.inputBox, 0)
	guiSetProperty(self.inputBox, "MaxTextLength", "128")
	guiEditSetReadOnly(self.inputBox, true)
	addEventHandler("onClientGUIAccepted", self.inputBox, ChatRoom.onAccept)
	guiBringToFront(self.inputBox)
	guiSetInputEnabled(true)
	addEventHandler("onClientRender", g_Root, ChatRoom.render)
	ChatRoom.visibleRoom = self
	
	triggerServerEvent("onPlayerChatting", g_Me, true)
end

function ChatRoom:closeInput()
	if(not self.inputBox) then return end
	assert(ChatRoom.visibleRoom == self)
	
	removeEventHandler("onClientRender", g_Root, ChatRoom.render)
	destroyElement(self.inputBox)
	self.inputBox = false
	ChatRoom.visibleRoom = false
	guiSetInputEnabled(false)
	
	triggerServerEvent("onPlayerChatting", g_Me, false)
end

function ChatRoom.onAccept()
	local self = ChatRoom.visibleRoom
	assert(self)
	
	local msg = tostring(guiGetText(self.inputBox))
	if(msg ~= "") then
		triggerServerEvent("chatext.onMsg", resourceRoot, self.id, msg)
	end
	self:closeInput()
end

function ChatRoom.render()
	local self = ChatRoom.visibleRoom
	assert(self)
	
	if(isMainMenuActive()) then
		self:closeInput()
		return
	end
	guiBringToFront(self.inputBox)
	guiSetInputEnabled(true)
	
	local chatbox_layout = getChatboxLayout()
	local font = g_ChatFonts[chatbox_layout.chat_font] or "default"
	local w = chatbox_layout.chat_width * 320 * chatbox_layout.chat_scale[1]
	local h = dxGetFontHeight(chatbox_layout.text_scale, font)
	local x = g_ScrW*0.013
	local y = g_ScrH*0.015 + (h * chatbox_layout.chat_lines + 8) * chatbox_layout.chat_scale[2]
	local prefix = self.info.inputPrefix
	if(type(prefix) == "function") then prefix = prefix(localPlayer) end
	
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
	local text = guiGetText(self.inputBox)
	if(transparentBg) then -- input field does not have background
		dxDrawText(text, x + 10 + p_w, y + 3, w + 18, y + h + 4, BLACK, chatbox_layout.text_scale, font, "left", "top", true)
	end
	local inputTextClr = tocolor(unpack(chatbox_layout.chat_input_text_color))
	dxDrawText(text, x + 9 + p_w, y + 2, w + 18, y + h + 4, inputTextClr, chatbox_layout.text_scale, font, "left", "top", true)
end

function ChatRoom.onKeyDown(key)
	local self = ChatRoom.keyToRoom[key]
	if(not ChatRoom.visibleRoom) then
		self:openInput()
	end
end

function ChatRoom.onKeyUp(key)
	local self = ChatRoom.keyToRoom[key]
	if(self.inputBox) then
		guiEditSetReadOnly(self.inputBox, false)
	end
end

function ChatRoom:bindKey()
	if(self.boundKey or not self.info.key) then return end
	
	bindKey(self.info.key, "down", ChatRoom.onKeyDown)
	bindKey(self.info.key, "up", ChatRoom.onKeyUp)
	ChatRoom.keyToRoom[self.info.key] = self
	self.boundKey = true
end

function ChatRoom:enable()
	self:bindKey()
	--outputDebugString("[chatext] Enabled chat: "..self.id, 3)
end

function ChatRoom.create(info)
	local self = setmetatable({}, ChatRoom.__mt)
	self.info = info
	self.id = info.id
	if(not info.disabled) then
		self:bindKey()
	end
	--outputDebugString("[chatext] Created chat: "..self.id, 3)
	return self
end

------------
-- Events --
------------

#VERIFY_SERVER_BEGIN("4D61E3FEBAC07FBBE5539F4C2E332743")
	triggerServerEvent("chatext.onReady", resourceRoot)
#VERIFY_SERVER_END()
