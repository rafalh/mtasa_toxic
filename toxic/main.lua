--------------
-- Includes --
--------------

#include "include/internal_events.lua"

--------------------------------
-- Local function definitions --
--------------------------------

Styles = {
	joinQuit = {"#00BB00", "#EEEEEE"},
	stats = {"#FF6464", "#EEEEEE"},
	maps = {"#80FFC0", "#EEEEEE"},
	red = {"#FF0000", "#EEEEEE"},
	green = {"#00FF00", "#80FF80"},
	poll = "#80FFC0",
	gambling = {"#FFC000", "#FFE080"},
	info = {"#FFC000", "#FFFFFF"}
}

addEvent("main.onPlayerReady", true)

local function isNickChangeAllowed(player, name)
	local namePlain = name:gsub("#%x%x%x%x%x%x", "")
	if(namePlain == "") then
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
	
	local countryName
	if(g_Countries[player.country]) then
		countryName = g_Countries[player.country]
	else
		countryName = player.country
	end
	
	if(countryName) then
		outputMsg(g_Root, Styles.joinQuit, "* %s has joined the game (%s).", player:getName(true), countryName)
	else
		outputMsg(g_Root, Styles.joinQuit, "* %s has joined the game.", player:getName(true))
	end
end

local function onPlayerPMRequest(msg, recipient)
	if(isPlayerMuted(client)) then
		outputChatBox("pm: You are muted", client, 255, 128, 0)
	else
		local playerName = getPlayerName(client):gsub("#%x%x%x%x%x%x", "")
		outputChatBox("PM from "..playerName..": "..msg, recipient, 255, 96, 96)
		triggerClientInternalEvent(recipient, $(EV_CLIENT_PLAYER_PM), client, msg)
	end
end

local function onPlayerPrivateMessage(msg, recipient)
	triggerClientInternalEvent(recipient, $(EV_CLIENT_PLAYER_PM), source, msg)
end

local function onPlayerChangeNick(oldNick, newNick)
	local pdata = Player.fromEl(source)
	if(not pdata) then return end
	
	local oldNickPlain = oldNick:gsub("#%x%x%x%x%x%x", "")
	local newNickPlain = newNick:gsub("#%x%x%x%x%x%x", "")
	local onlyColorChanged = (oldNickPlain == newNickPlain)
	
	if(not onlyColorChanged and not isNickChangeAllowed(source, newNickPlain)) then
		cancelEvent()
		return
	end
	
	if(AsNotifyOfNickChange) then
		AsNotifyOfNickChange(source)
	end
	
	-- Note: getPlayerName returns old nick
	local fullNick = newNick
	local r, g, b = getPlayerNametagColor(pdata.el)
	if(r ~= 255 or g ~= 255 or b ~= 255) then
		fullNick = ("#%02X%02X%02X"):format(r, g, b)..fullNick
	end
	
	pdata.accountData:set("name", fullNick)
	if(not onlyColorChanged) then
		outputMsg(g_Root, Styles.joinQuit, "* %s is now known as %s.", oldNickPlain, newNickPlain)
	end
end

local function onPlayerChat(message, messageType)
	local message2 = message:gsub("#%x%x%x%x%x%x", "")
	if(message2:gsub(" ", "") == "") then
		cancelEvent()
		return
	end
	
	local arg = split(message, (" "):byte()) -- defined in other place
	local cmd = arg[1]:lower() -- defined in other place
	
	local str = cmd:match("[^%w]?(%w)")
	if((str == "login" or str == "register") and arg[2]) then -- never display someone's password
		privMsg(source, "DON'T USE \""..arg[1].."\" anymore!!! It could show your password to everybody. Type /"..str.." <password> instead.")
		cancelEvent()
		return
	end
	
	local fine = 0
	if(CsProcessMsg) then
		fine, message = CsProcessMsg(message, source)
		if(not message) then
			cancelEvent()
			return
		end
	end
	
	local recipients, type_str, prefix
	local source_name = getPlayerName(source)
	local source_name2 = source_name:gsub("#%x%x%x%x%x%x", "")
	local r, g, b = getPlayerNametagColor(source)
	
	if(messageType == 0) then -- normal message
		recipients = getElementsByType("player")
		type_str = ""
		prefix = ""
	elseif(messageType == 1) then -- /me message
		recipients = getElementsByType("player")
		type_str = "ME"
		--prefix = ""
		message = source_name2.." "..message
		message2 = source_name2.." "..message2
	else -- team message
		recipients = getPlayersInTeam(getPlayerTeam(source))
		type_str = "TEAM"
		prefix = "(TEAM) "
	end
	
	-- remove recipients which ignore sender
	for i, player in ipairs(recipients) do
		local ignored = getElementData(player, "ignored_players")
		if(type(ignored) == "table" and ignored[source_name2]) then
			table.remove(recipients, i)
		end
	end
	
	-- send message and show it above sender for recipients
	local x, y, z = getElementPosition(source)
	for i, player in ipairs(recipients) do
		if (messageType ~= 1) then
			outputChatBox(prefix..source_name..": #EBDDB2"..message, player, r, g, b, true)
		else
			outputChatBox(message, player, 255, 0, 255, false)
		end
		if(Settings.msgs_above_players) then
			local x2, y2, z2 = getElementPosition(player)
			if(getDistanceBetweenPoints3D(x, y, z, x2, y2, z2) < 100 and Player.fromEl(player)) then
				triggerClientInternalEvent(player, $(EV_CLIENT_PLAYER_CHAT), source, message2)
			end
		end
	end
	
	outputServerLog(type_str.."CHAT: "..source_name2..": "..message2)
	
	cancelEvent() -- cancel event to disallow printing message twice
	
	if(fine > 0) then
		local pdata = Player.fromEl(source)
		pdata.accountData:add("cash", -fine)
		privMsg(source, "Do not swear %s! %s taked from your cash.", getPlayerName(source), formatMoney(fine))
	end
	
	if(AsProcessMsg and AsProcessMsg(source)) then
		return -- if it is spam don't run commands
	end
	
	-- fixme: CmdDoesIgnoreChat
	--if(messageType ~= 1 and message:sub ( 1, 1 ) == "!" and not CmdDoesIgnoreChat(cmd:sub(2))) then
	--	parseCommand(message, source, recipients, type_str_br)
	--end
end

local function onPlayerReady(localeId)
	local pdata = Player.fromEl(client)
	
	if(not LocaleList.exists(localeId)) then
		localeId = pdata.country and pdata.country:lower()
		if(not LocaleList.exists(localeId)) then
			localeId = "en"
		end
	end
	
	pdata:setLocale(localeId) -- set locale
	
	local globalSettings = Settings.getClient()
	
	pdata.sync = true -- set sync to true just before init event
	triggerClientInternalEvent(client, $(EV_CLIENT_INIT), g_Root, pdata.id, globalSettings, pdata.new, localeId)
	
	if(BtSendMapInfo) then
		BtSendMapInfo(pdata.room, pdata.new, client)
	end
	
	local account = getPlayerAccount(client)
	if(isGuestAccount(account) and pdata.new and Settings.loginWnd) then
		triggerClientEvent(client, "main.onLoginReq", g_ResRoot)
	elseif(not isGuestAccount(account)) then
		local accountName = getAccountName(account)
		triggerClientEvent(pdata.el, "main.onLoginStatus", g_ResRoot, true)
		triggerClientEvent(pdata.el, "main.onAccountChange", g_ResRoot, accountName, pdata.id)
	end
	
	pdata.new = false
end

allowRPC("getThisResourceVersion")
function getThisResourceVersion()
	return getResourceInfo(resource, "version")
end

------------
-- Events --
------------

addInitFunc(function()
	addEventHandler("onPlayerJoin", g_Root, onPlayerJoin)
	addEventHandler("onPlayerPrivateMessage", g_Root, onPlayerPrivateMessage)
	addEventHandler("onPlayerChangeNick", g_Root, onPlayerChangeNick)
	addEventHandler("onPlayerChat", g_Root, onPlayerChat)
	addEventHandler("main.onPlayerReady", g_ResRoot, onPlayerReady)
	addInternalEventHandler($(EV_PLAYER_PM_REQUEST), onPlayerPMRequest)
end)

Settings.register
{
	name = "version",
	type = "INTEGER",
	default = 0,
}

Settings.register
{
	name = "cleanup_done",
	type = "BOOL",
	default = 0,
}
