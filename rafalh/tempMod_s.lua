local g_TempModGroup = aclGetGroup("PremiumModerator")

function giveTempMod(player, days)
	local days = tonumber(days) or 30
	local account = player and getPlayerAccount(player)
	
	if(not account or isGuestAccount(account) or not g_TempModGroup) then
		return false
	end
	
	aclGroupAddObject(g_TempModGroup, "user."..getAccountName(account))
	
	local now = getRealTime().timestamp
	local timestamp = math.max(getAccountData(account, "toxic.tempModLimit") or 0, now) + days*24*60*60
	setAccountData(account, "toxic.tempModLimit", timestamp)
	
	local tm = getRealTime(timestamp)
	
	local dateStr = ("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute)
	outputServerLog("Temporary Moderator activated for "..getAccountName(account)..". It will be active untill "..dateStr)
	
	return timestamp
end

local function CmdGiveMod(msg, arg)
	local player = arg[2] and findPlayer(arg[2])
	local days = math.floor(tonumber(arg[3]) or 30)
	
	local timestamp = player and giveTempMod(player, days)
	if(timestamp) then
		local tm = getRealTime(timestamp)
		local name = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
		
		local dateStr = ("%u.%02u.%u %u:%02u GMT"):format (tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute)
		privMsg(source, "Temporary Moderator successfully given to %s! It will be valid untill %s.", name, dateStr)
		outputMsg(player, Styles.green, "You have become Temporary Moderator! It will be valid untill %s.", dateStr)
	else
		privMsg(source, "Usage: %s", arg[1].." <name> [<days>]")
	end
end
CmdRegister("givemod", CmdGiveMod, "resource."..g_ResName..".givemod")

local function onPlayerLogin(prevAccount, account)
	local timestamp = getAccountData(account, "toxic.tempModLimit")
	if(not timestamp) then return end
	
	local now = getRealTime().timestamp
	if(timestamp >= now) then return end
	
	local removed = aclGroupRemoveObject(g_TempModGroup, "user."..getAccountName(account))
	if(removed) then
		outputServerLog("Temporary Moderator disactivated for "..getAccountName(account)..".")
		outputMsg(player, Styles.red, "Your Moderator rank has been disactivated!")
	end
end

addInitFunc(function()
	addEventHandler("onPlayerLogin", g_Root, onPlayerLogin)
end)
