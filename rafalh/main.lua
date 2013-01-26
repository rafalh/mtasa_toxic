--------------
-- Includes --
--------------

#include "include/internal_events.lua"

--------------------------------
-- Local function definitions --
--------------------------------

local function onPlayerJoin ()
	local player = Player.create(source) -- name can change here
	player.new = true
	
	local country = getElementData ( source, "country" )
	if ( g_Countries[country] ) then
		country = g_Countries[country]
	end
	
	local countryStr = country and " ("..country..")" or ""
	customMsg ( 255, 100, 100, "* %s has joined the game%s.", getPlayerName ( source ), countryStr )
	
	local rows = DbQuery ( "SELECT joinmsg, pmuted FROM rafalh_players WHERE player=? LIMIT 1", player.id )
	
	if ( rows[1].joinmsg and rows[1].joinmsg ~= "" ) then
		setTimer ( JmPlayerJoin, 100, 1, source ) -- show joinmsg after auto-login
	end
	
	if ( rows[1].pmuted == 1 ) then
		customMsg ( 255, 0, 0, "%s has got permanent mute!", getPlayerName ( source ) )
		mutePlayer ( source, 0, false, true )
	end
end

local function onPlayerPMRequest ( msg, recipient )
	if ( isPlayerMuted ( source ) ) then
		outputChatBox ( "pm: You are muted", source, 255, 128, 0 )
	else
		outputChatBox ( "PM from "..getPlayerName ( source ):gsub ( "#%x%x%x%x%x%x", "" )..": "..msg, recipient, 255, 96, 96 )
		triggerClientInternalEvent ( recipient, $(EV_CLIENT_PLAYER_PM), source, msg )
	end
end

local function onPlayerPrivateMessage ( msg, recipient )
	triggerClientInternalEvent ( recipient, $(EV_CLIENT_PLAYER_PM), source, msg )
end

local function onPlayerChangeNick ( oldNick, newNick )
	local pdata = g_Players[source]
	if(wasEventCancelled () or not pdata) then
		return
	end
	
	local oldNickPlain = oldNick:gsub("#%x%x%x%x%x%x", "")
	local newNickPlain = newNick:gsub("#%x%x%x%x%x%x", "")
	
	if(newNickPlain == "") then
		privMsg(source, "Empty nick is not allowed!")
		cancelEvent()
		return
	end
	
	if(oldNickPlain ~= newNickPlain) then -- not only color changed
		if(NlCheckPlayer and NlCheckPlayer(source, newNickPlain)) then
			cancelEvent ()
			return
		end
		
		if(AsCanPlayerChangeNick(source, oldNickPlain, newNickPlain)) then
			-- Note: getPlayerName returns old nick
			local fullNick = newNick
			local r, g, b = getPlayerNametagColor(pdata.el)
			if(r ~= 255 or g ~= 255 or b ~= 255) then
				fullNick = ("#%02X%02X%02X"):format(r, g, b)..fullNick
			end
			
			DbQuery("UPDATE rafalh_players SET name=? WHERE player=?", fullNick, pdata.id)
			customMsg(255, 96, 96, "* %s is now known as %s.", oldNickPlain, newNickPlain)
		else
			cancelEvent()
		end
	end
end

local function onPlayerChat ( message, messageType )
	if ( wasEventCancelled () ) then return end
	
	local message2 = message:gsub ( "#%x%x%x%x%x%x", "" )
	if ( message2:gsub ( " ", "" ) == "" ) then
		cancelEvent ()
		return
	end
	
	local arg = split ( message, ( " " ):byte () ) -- defined in other place
	local cmd = arg[1]:lower () -- defined in other place
	
	local str = cmd:match ( "[^%w]?(%w)" )
	if ( ( str == "login" or str == "register" ) and arg[2] ) then -- never display someone's password
		privMsg ( source, "DON'T USE \""..arg[1].."\" anymore!!! It could show your password to everybody. Type /"..str.." <password> instead." )
		cancelEvent ()
		return
	end
	
	local fine = 0
	fine, message = CsProcessMsg ( message )
	
	local recipients, type_str, prefix
	local source_name = getPlayerName ( source )
	local source_name2 = source_name:gsub ( "#%x%x%x%x%x%x", "" )
	local r, g, b = getPlayerNametagColor ( source )
	
	if ( messageType == 0 ) then -- normal message
		recipients = getElementsByType ( "player" )
		type_str = ""
		prefix = ""
	elseif ( messageType == 1 ) then -- /me message
		recipients = getElementsByType ( "player" )
		type_str = "ME"
		--prefix = ""
		message = source_name2.." "..message
		message2 = source_name2.." "..message2
	else -- team message
		recipients = getPlayersInTeam ( getPlayerTeam ( source ) )
		type_str = "TEAM"
		prefix = "(TEAM) "
	end
	
	-- remove recipients which ignore sender
	for i, player in ipairs ( recipients ) do
		local ignored = getElementData ( player, "ignored_players" )
		if ( type ( ignored ) == "table" and ignored[source_name2] ) then
			table.remove ( recipients, i )
		end
	end
	
	-- send message and show it above sender for recipients
	local x, y, z = getElementPosition ( source )
	for i, player in ipairs ( recipients ) do
		if ( messageType ~= 1 ) then
			outputChatBox ( prefix..source_name..": #EBDDB2"..message, player, r, g, b, true )
		else
			outputChatBox ( message, player, 255, 0, 255, false )
		end
		if ( SmGetBool ( "msgs_above_players" ) ) then
			local x2, y2, z2 = getElementPosition ( player )
			if ( getDistanceBetweenPoints3D ( x, y, z, x2, y2, z2 ) < 100 and g_Players[player] ) then
				triggerClientInternalEvent ( player, $(EV_CLIENT_PLAYER_CHAT), source, message2 )
			end
		end
	end
	
	outputServerLog ( type_str.."CHAT: "..source_name2..": "..message2 )
	
	cancelEvent () -- cancel event to disallow printing message twice
	
	if ( fine > 0 ) then
		local cash = StGet ( source, "cash" ) - fine
		StSet ( source, "cash", cash )
		privMsg ( source, "Do not swear %s! %s taked from your cash.", getPlayerName ( source ), formatMoney ( fine ) )
	end
	
	if ( AsProcessMsg ( source ) ) then
		return -- if it is spam don't run commands
	end
	
	-- fixme: CmdDoesIgnoreChat
	--if ( messageType ~= 1 and message:sub ( 1, 1 ) == "!" and not CmdDoesIgnoreChat ( cmd:sub ( 2 ) ) ) then
	--	parseCommand ( message, source, recipients, type_str_br )
	--end
end

local function onRafalhStart()
	local pdata = g_Players[client]
	pdata.sync = true
	
	local rows = DbQuery("SELECT lang FROM rafalh_players WHERE player=? LIMIT 1", pdata.id)
	local clientSettings = {}
	clientSettings.lang = pdata.lang
	clientSettings.breakable_glass = SmGetBool("breakable_glass")
	clientSettings.red_damage_screen = SmGetBool("red_damage_screen")
	triggerClientInternalEvent(client, $(EV_CLIENT_INIT), g_Root, pdata.id, clientSettings, pdata.new)
	
	BtSendMapInfo(pdata.room, pdata.new, client)
	
	local account = getPlayerAccount(client)
	if(isGuestAccount(account) and pdata.new and SmGetBool("loginWnd")) then
		triggerClientEvent(client, "main_onLoginReq", g_ResRoot)
	elseif(not isGuestAccount(account)) then
		local accountName = getAccountName(account)
		triggerClientEvent(pdata.el, "main_onLoginStatus", g_ResRoot, true, accountName)
	end
	
	pdata.new = false
end

local function onSetNameRequest(name)
	name = tostring(name)
	local pdata = g_Players[client]
	
	-- HACK: Cancelling event after setPlayerName doesn't work
	local plainName = name:gsub("#%x%x%x%x%x%x", "")
	if(plainName ~= "" and not (pdata.last_nick_change and (getTickCount() - pdata.last_nick_change) < 10000) and not getPlayerFromName(name)) then
		local oldPlainName = getPlayerName(client):gsub("#%x%x%x%x%x%x", "")
		if(oldPlainName ~= plainName) then
			local rows = DbQuery("SELECT locked_nick FROM rafalh_players WHERE player=? LIMIT 1", pdata.id)
			if(rows[1].locked_nick == 1) then
				return
			end
		end
		
		setPlayerName(client, name)
	end
end

------------
-- Events --
------------

addEventHandler("onPlayerJoin", g_Root, onPlayerJoin)
addEventHandler("onPlayerPrivateMessage", g_Root, onPlayerPrivateMessage)
addEventHandler("onPlayerChangeNick", g_Root, onPlayerChangeNick)
addEventHandler("onPlayerChat", g_Root, onPlayerChat)
addInternalEventHandler($(EV_RAFALH_START), onRafalhStart)
addInternalEventHandler($(EV_PLAYER_PM_REQUEST), onPlayerPMRequest)
addInternalEventHandler($(EV_SET_NAME_REQUEST), onSetNameRequest)
