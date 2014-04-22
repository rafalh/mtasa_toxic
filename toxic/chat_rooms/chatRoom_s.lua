-- Custom events
addEvent('chatext.onMsg', true)
addEvent('chatext.onPlayerChat')

-- ChatRoom class
ChatRoom = {}
ChatRoom.__mt = {__index = ChatRoom}
ChatRoom.idToRoom = {}

function ChatRoom:onPlayerMsg(player, msg)
	--Debug.info('[chatext] Chat msg: '..self.id..' player '..getPlayerName(player))
	
	msg = tostring(msg)
	if(msg == '') then return end
	if(self.info.right and not self.info.right:check(player)) then return end
	
	if(getElementType(player) == 'player' and isPlayerMuted(player)) then
		outputChatBox(self.info.cmd..': You are muted!', player, 255, 128, 0)
		return
	end
	
	msg = utfSub(msg, 1, 128)
	
	local recipients = self.info.getPlayers(player)
	local playerName = getPlayerName(player)
	local playerNamePlain = playerName:gsub('#%x%x%x%x%x%x', '')
	local chatPrefix = self.info.chatPrefix
	if(type(chatPrefix) == 'function') then chatPrefix = chatPrefix(player) end
	local logPrefix = self.info.logPrefix
	if(type(logPrefix) == 'function') then logPrefix = logPrefix(player) end
	
	if(utfSub(msg, 1, 1) ~= '/') then
		local pdata = Player.fromEl(player)
		local msgCensored = msg
		local punishment = false
		if(CsProcessMsg) then
			msgCensored, punishment = CsProcessMsg(msg)
			if(not msgCensored) then
				-- Message has been blocked
				CsPunish(pdata, punishment)
				return
			end
		end
		
		local r, g, b
		if(getElementType(player) == 'player') then
			r, g, b = getPlayerNametagColor(player)
		else
			r, g, b = 255, 0, 255
		end
		--local foundSender = false
		
		for i, recipient in ipairs(recipients) do
			local recipientPlayer = Player.fromEl(recipient)
			
			-- Decide whether use censored message or not
			local msg2
			if(not recipientPlayer or recipientPlayer.clientSettings.censorClient) then
				msg2 = msgCensored
			else
				msg2 = msg
			end
			
			if(not recipientPlayer or not recipientPlayer:isPlayerIgnored(pdata)) then
				outputChatBoxLong(chatPrefix..playerName..': #EBDDB2'..msg2, recipient, r, g, b, true)
			end
			--if(player == recipient) then foundSender = true end
		end
		--assert(foundSender)
		outputServerLog(logPrefix..playerName..': '..msg)
		
		if(punishment) then
			CsPunish(pdata, punishment)
		end
	end
	
	--[[local rafalhRes = getResourceFromName('toxic')
	if(rafalhRes and getResourceState(rafalhRes) == 'running') then
		call(rafalhRes, 'parseCommand', msg, player, recipients, chatPrefix)
	end]]
	if(parseCommand) then
		parseCommand(msg, player, recipients, chatPrefix)
	end
end

function ChatRoom.create(info)
	local self = setmetatable({}, ChatRoom.__mt)
	self.info = info
	self.id = info.id
	ChatRoom.idToRoom[info.id] = self
	return self
end

-- Local function definitions

local function onMsg(roomId, msg)
	local self = ChatRoom.idToRoom[roomId]
	assert(self)
	self:onPlayerMsg(client, msg)
end

local function onConsole(msg)
	for id, room in pairs(ChatRoom.idToRoom) do
		local cmdLen = room.info.cmd:len()
		if(msg:sub(1, cmdLen + 1) == room.info.cmd..' ') then
			room:onPlayerMsg(source, msg:sub(1 + cmdLen + 1))
		end
	end
end

-- Events
addInitFunc(function()
	addEventHandler('chatext.onMsg', resourceRoot, onMsg)
	addEventHandler('onConsole', root, onConsole)
end)
