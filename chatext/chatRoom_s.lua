---------------------
-- Local variables --
---------------------

local g_Root = getRootElement()

-------------------
-- Custom events --
-------------------

addEvent("chatext.onMsg", true)
addEvent("chatext.onPlayerChat")

ChatRoom = {}
ChatRoom.__mt = {__index = ChatRoom}
ChatRoom.idToRoom = {}

function ChatRoom:onPlayerMsg(player, msg)
	--outputDebugString("[chatext] Chat msg: "..self.id.." player "..getPlayerName(player), 3)
	
	msg = tostring(msg)
	if(msg == "") then return end
	if(self.info.checkAccess and not self.info.checkAccess(player)) then return end
	
	if(getElementType(player) == 'player' and isPlayerMuted(player)) then
		outputChatBox(self.info.cmd..": You are muted!", player, 255, 128, 0)
		return
	end
	
	msg = utfSub(msg, 1, 128)
	
	local recipients = self.info.getPlayers(player)
	local playerName = getPlayerName(player)
	local chatPrefix = self.info.chatPrefix
	if(type(chatPrefix) == "function") then chatPrefix = chatPrefix(player) end
	local logPrefix = self.info.logPrefix
	if(type(logPrefix) == "function") then logPrefix = logPrefix(player) end
	
	if(utfSub(msg, 1, 1) ~= "/") then
		triggerEvent('chatext.onPlayerChat', player, msg, logPrefix)
		if(wasEventCancelled()) then return end
		
		local str = chatPrefix..playerName..": #EBDDB2"..msg
		local r, g, b 
		if(getElementType(player) == 'player') then
			r, g, b = getPlayerNametagColor(player)
		else
			r, g, b = 255, 0, 255
		end
		--local foundSender = false
		for i, recipient in ipairs(recipients) do
			outputChatBox(str, recipient, r, g, b, true)
			--if(player == recipient) then foundSender = true end
		end
		--assert(foundSender)
		outputServerLog(logPrefix..playerName..": "..msg)
	end
	
	local rafalhRes = getResourceFromName("toxic")
	if(rafalhRes and getResourceState(rafalhRes) == "running") then
		call(rafalhRes, "parseCommand", msg, player, recipients, chatPrefix)
	end
end

function ChatRoom.create(info)
	local self = setmetatable({}, ChatRoom.__mt)
	self.info = info
	self.id = info.id
	ChatRoom.idToRoom[info.id] = self
	return self
end

--------------------------------
-- Local function definitions --
--------------------------------

local function onMsg(roomId, msg)
	local self = ChatRoom.idToRoom[roomId]
	assert(self)
	self:onPlayerMsg(client, msg)
end

local function onConsole(msg)
	for id, room in pairs(ChatRoom.idToRoom) do
		local cmdLen = room.info.cmd:len()
		if(msg:sub(1, cmdLen + 1) == room.info.cmd.." ") then
			room:onPlayerMsg(source, msg:sub(1 + cmdLen + 1))
		end
	end
end

------------
-- Events --
------------

addEventHandler("chatext.onMsg", resourceRoot, onMsg)
addEventHandler("onConsole", root, onConsole)
