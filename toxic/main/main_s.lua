--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

--------------------------------
-- Local function definitions --
--------------------------------

Styles = {
	joinQuit = {'#00BB00', '#EEEEEE'},
	stats = {'#FF6464', '#EEEEEE'},
	maps = {'#80FFC0', '#EEEEEE'},
	red = {'#FF0000', '#EEEEEE'},
	green = {'#00FF00', '#80FF80'},
	poll = '#80FFC0',
	gambling = {'#FFC000', '#FFE080'},
	info = {'#FFC000', '#FFFFFF'},
	pm = {'#FF6464', '#EEEEEE'},
	pmSent = {'#D05050', '#CCCCCC'},
}

BlobsTable = Database.Table{
	name = 'blobs',
	{'id', 'INT UNSIGNED', pk = true},
	{'data', 'BLOB', default = ''},
}

SerialsTable = Database.Table{
	name = 'serials',
	{'id', 'INT UNSIGNED', pk = true},
	{'serial', 'VARCHAR(32)'},
	{'serials_idx', unique = {'serial'}},
}

addEvent('main.onPlayerReady', true)

-- Some custom rights
AccessRight('admin')

local function isNickChangeAllowed(player, name)
	local namePlain = name:gsub('#%x%x%x%x%x%x', '')
	if(namePlain == '') then
		privMsg(player, "Empty nick is not allowed!")
		return false
	end
	
	if(NbCheckName and NbCheckName(namePlain)) then
		privMsg(player, "This nickname is not allowed!")
		return false
	end
	
	if(AsCanPlayerChangeNick and not AsCanPlayerChangeNick(source, namePlain)) then
		return false
	end
	
	return true
end

local function onPlayerJoin()
	if(NbCheckPlayerAndFix) then
		NbCheckPlayerAndFix(source)
	end
	
	local player = Player.create(source) -- name can change here
	player.new = true
end

local function onPlayerJoin2()
	local player = Player.fromEl(source)
	local countryName
	if(g_Countries[player.country]) then
		countryName = g_Countries[player.country]
	else
		countryName = player.country
	end
	
	local nickname = player:getName(true)
	if(countryName) then
		outputMsg(g_Root, Styles.joinQuit, "* %s has joined the game (%s).", nickname, countryName)
	else
		outputMsg(g_Root, Styles.joinQuit, "* %s has joined the game.", nickname)
	end
end

local function onPlayerPMRequest(msg, recipientEl)
	local sender = Player.fromEl(client)
	local recipient = Player.fromEl(recipientEl)
	if(not sender or not recipient) then return end
	
	if(isPlayerMuted(sender.el)) then
		outputMsg(sender, Styles.red, "pm: You are muted")
	else
		local senderName = sender:getName(true)
		local recipientName = recipient:getName(true)
		if(not recipient:isPlayerIgnored(sender)) then
			outputMsg(sender, Styles.pmSent, "You have sent PM to %s: %s", recipientName, msg)
			outputMsg(recipient, Styles.pm, "PM from %s: %s", senderName, msg)
			triggerClientInternalEvent(recipient.el, $(EV_CLIENT_PLAYER_PM), client, msg)
		else
			outputMsg(client, Styles.red, "pm: You are being ignored by %s", recipientName)
		end
	end
end

local function onPlayerPrivateMessage(msg, recipient)
	triggerClientInternalEvent(recipient, $(EV_CLIENT_PLAYER_PM), source, msg)
end

local function onPlayerChangeNickFilter(oldNick, newNick)
	local pdata = Player.fromEl(source)
	if(not pdata) then return end
	
	local oldNickPlain = oldNick:gsub('#%x%x%x%x%x%x', '')
	local newNickPlain = newNick:gsub('#%x%x%x%x%x%x', '')
	local onlyColorChanged = (oldNickPlain == newNickPlain)
	
	if(not onlyColorChanged and not isNickChangeAllowed(source, newNickPlain)) then
		return false
	end
	
	return true
end

local function onPlayerChangeNick(oldNick, newNick)
	local pdata = Player.fromEl(source)
	if(not pdata) then return end
	
	local oldNickPlain = oldNick:gsub('#%x%x%x%x%x%x', '')
	local newNickPlain = newNick:gsub('#%x%x%x%x%x%x', '')
	local onlyColorChanged = (oldNickPlain == newNickPlain)
	
	if(AsNotifyOfNickChange) then
		AsNotifyOfNickChange(source)
	end
	
	-- Note: getPlayerName returns old nick
	local r, g, b = getPlayerNametagColor(pdata.el)
	local nametagClr = ''
	if(r ~= 255 or g ~= 255 or b ~= 255) then
		nametagClr = ('#%02X%02X%02X'):format(r, g, b)
	end
	
	pdata.accountData:set{
		name = nametagClr..newNick,
		namePlain = newNickPlain,
	}
	if(not onlyColorChanged) then
		outputMsg(g_Root, Styles.joinQuit, "* %s is now known as %s.", nametagClr..oldNick, nametagClr..newNick)
	end
end

local function onPlayerChat(msg, msgType)
	local player = Player.fromEl(source)
	if(not player) then return end
	
	local msgPlain = msg:gsub('#%x%x%x%x%x%x', '')
	if(msgPlain:gsub(' ', '') == '') then
		cancelEvent()
		return
	end
	
	local arg = split(msg, (' '):byte()) -- defined in other place
	local cmd = arg[1]:lower() -- defined in other place
	
	local str = cmd:match('[^%w]?(%w)')
	if((str == 'login' or str == 'register') and arg[2]) then -- never display someone's password
		privMsg(player, "DON'T USE \"%s\" any more!!! It could show your password to everybody. Type %s <password> instead.", arg[1], '/'..str)
		cancelEvent()
		return
	end
	
	local msgCensored, msgCensoredPlain = msg, msgPlain
	local punishment = false
	if(CsProcessMsg) then
		msgCensored, punishment = CsProcessMsg(msg)
		if(not msgCensored) then
			-- Message has been blocked
			CsPunish(player, punishment)
			cancelEvent()
			return
		else
			msgCensoredPlain = msgCensored:gsub('#%x%x%x%x%x%x', '')
		end
	end
	
	local recipients, typeStr, prefix
	local playerName = player:getName(true)
	local playerNamePlain = player:getName(false)
	local r, g, b = getPlayerNametagColor(player.el)
	
	-- Prepare recipients list and messsage prefix
	if(msgType == 0) then -- normal message
		recipients = getElementsByType('player')
		typeStr = ''
		prefix = ''
	elseif(msgType == 1) then -- /me message
		recipients = getElementsByType('player')
		typeStr = 'ME'
		--prefix = ''
		msg = playerNamePlain..' '..msg
		msgPlain = playerNamePlain..' '..msgPlain
	else -- team message
		recipients = getPlayersInTeam(getPlayerTeam(player.el))
		typeStr = 'TEAM'
		prefix = '(TEAM) '
	end
	
	-- Remove recipients which ignore sender
	for i, player in ipairs(recipients) do
		local ignored = getElementData(player, 'ignored_players')
		if(type(ignored) == 'table' and ignored[playerNamePlain]) then
			table.remove(recipients, i)
		end
	end
	
	-- Send message and show it above sender for recipients
	local x, y, z = getElementPosition(player.el)
	for i, recipient in ipairs(recipients) do
		local recipientPlayer = Player.fromEl(recipient)
		
		-- Decide whether use censored message or not
		local msg2, msgPlain2
		if(not recipientPlayer or recipientPlayer.clientSettings.censorClient) then
			msg2, msgPlain2 = msgCensored, msgCensoredPlain
		else
			msg2, msgPlain2 = msg, msgPlain
		end
		
		if(msgType ~= 1) then
			outputChatBoxLong(prefix..playerName..': #EBDDB2'..msg2, recipient, r, g, b, true)
		else
			outputChatBoxLong(msg2, recipient, 255, 0, 255, false)
		end
		if(Settings.msgs_above_players) then
			local x2, y2, z2 = getElementPosition(recipient)
			if(getDistanceBetweenPoints3D(x, y, z, x2, y2, z2) < 100 and recipientPlayer) then
				triggerClientInternalEvent(recipient, $(EV_CLIENT_PLAYER_CHAT), player.el, msgPlain2)
			end
		end
	end
	
	-- Output message to server log
	outputServerLog(typeStr..'CHAT: '..playerNamePlain..': '..msgPlain)
	
	-- Cancel event to disallow printing message twice
	cancelEvent()
	
	if(punishment) then
		CsPunish(player, punishment)
	end
	
	if(AsProcessMsg and AsProcessMsg(player.el)) then
		return -- if it is spam don't run commands
	end
	
	-- TODO: Add optional '!cmd' commands support
	--if(messageType ~= 1 and msg:sub(1, 1) == '!' and not CmdMgr.doesIgnoreChat(cmd:sub(2))) then
	--	parseCommand(msg, player.el, recipients, type_str_br)
	--end
end

local function onPlayerReady(clientSharedSettings)
	local pdata = Player.fromEl(client)
	pdata.clientSettings = clientSharedSettings
	
	local localeId = pdata.clientSettings.locale
	if(not LocaleList.exists(localeId)) then
		localeId = pdata.country and pdata.country:lower()
		if(not LocaleList.exists(localeId)) then
			localeId = 'en'
		end
	end
	
	pdata.clientSettings.locale = localeId
	pdata:setLocale(localeId) -- set locale
	
	local globalSettings = Settings.getClient()
	
	pdata.sync = true -- set sync to true just before init event
	triggerClientInternalEvent(client, $(EV_CLIENT_INIT), g_Root, pdata.id, globalSettings, pdata.new, localeId)
	
	pdata.acl:send(pdata)
	
	if(MiSendMapInfo) then
		MiSendMapInfo(pdata)
		if(pdata.new) then
			MiShow(pdata)
		end
	end
	
	local account = getPlayerAccount(client)
	if(isGuestAccount(account) and pdata.new and Settings.loginWnd) then
		triggerClientEvent(client, 'main.onLoginReq', g_ResRoot)
	elseif(not isGuestAccount(account)) then
		local accountName = getAccountName(account)
		triggerClientEvent(pdata.el, 'main.onLoginStatus', g_ResRoot, true)
		triggerClientEvent(pdata.el, 'main.onAccountChange', g_ResRoot, accountName, pdata.id)
	end
	
	pdata.new = false
end

RPC.allow('getThisResourceVersion')
function getThisResourceVersion()
	return getResourceInfo(resource, 'version')
end

------------
-- Events --
------------

addInitFunc(function()
	addEventHandler('onPlayerJoin', g_Root, onPlayerJoin, true, 'high')
	addEventHandler('onPlayerJoin', g_Root, onPlayerJoin2, true, 'low')
	addEventHandler('onPlayerPrivateMessage', g_Root, onPlayerPrivateMessage)
	Event('onPlayerChangeNick'):addFilter(onPlayerChangeNickFilter)
	Event('onPlayerChangeNick'):addHandler(onPlayerChangeNick)
	addEventHandler('onPlayerChat', g_Root, onPlayerChat)
	addEventHandler('main.onPlayerReady', g_ResRoot, onPlayerReady)
	addInternalEventHandler($(EV_PLAYER_PM_REQUEST), onPlayerPMRequest)
end)

Settings.register
{
	name = 'version',
	type = 'INTEGER',
	default = 0,
}

Settings.register
{
	name = 'cleanup_done',
	type = 'BOOL',
	default = 0,
}
