local g_LastRedo = 0

---------------------------------
-- Global function definitions --
---------------------------------

local function CmdLockPlayerNick (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	
	if (player) then
		DbQuery ("UPDATE rafalh_players SET locked_nick=1 WHERE player=?", g_Players[player].id)
		customMsg (255, 0, 0, "%s's nick has been locked by %s!", getPlayerName (player), getPlayerName (source))
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("lockplayernick", CmdLockPlayerNick, "resource.rafalh.lockplayernick")

local function CmdUnlockPlayerNick (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	
	if (player) then
		DbQuery ("UPDATE rafalh_players SET locked_nick=0 WHERE player=?", g_Players[player].id)
		customMsg (0, 255, 0, "%s's nick has been unlocked by %s!", getPlayerName (player), getPlayerName (source))
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("unlockplayernick", CmdUnlockPlayerNick, "resource.rafalh.lockplayernick")

local function CmdSetMaxPing (message, arg)
	local max_ping = touint (arg[2], 0)
	set ("max_ping", max_ping)
	if (max_ping > 0) then
		scriptMsg ("Maximal ping set to: %u.", max_ping)
	else
		scriptMsg ("Maximal ping disabled.")
	end
end

CmdRegister ("setmaxping", CmdSetMaxPing, "resource.rafalh.setmaxping")

local function CmdPBan (message, arg)
	local player = (#arg >= 2 and findPlayer (arg[2]))
	
	if (player) then
		local account_name = getAccountName (getPlayerAccount (source))
		local player_name = getPlayerName (player)
		local admin_name = getPlayerName (source)
		
		customMsg (255, 0, 0, "%s serial has been banned by %s!", player_name, admin_name)
		addBan (nil, nil, getPlayerSerial (player), source, "(nick: "..player_name..")"..((account_name ~= admin_name and " (by: "..account_name..")") or "")..(arg[3] and " "..arg[3] or ""))
	else
		privMsg (source, "Usage: %s", arg[1].." <player>")
	end
end

CmdRegister ("pban", CmdPBan, "command.banserial")

local function CmdBan1m (message, arg)
	local player = (#arg >= 2 and findPlayer (arg[2]))
	
	if (player) then
		local account_name = getAccountName (getPlayerAccount (source))
		local player_name = getPlayerName (player)
		local admin_name = getPlayerName (source)
		
		customMsg (255, 0, 0, "%s has been banned by %s (1 minute)!", player_name, getPlayerName (source))
		addBan (nil, nil, getPlayerSerial (player), source, "(nick: "..player_name..")"..((account_name ~= admin_name and " (by: "..account_name..")") or "")..(arg[3] and " "..arg[3] or ""), 60)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("ban1m", CmdBan1m, "resource.rafalh.ban1m", "Bans player for 1 minute")

local function CmdBan5m (message, arg)
	local player = (#arg >= 2 and findPlayer (arg[2]))
	
	if (player) then
		local account_name = getAccountName (getPlayerAccount (source))
		local player_name = getPlayerName (player)
		local admin_name = getPlayerName (source)
		
		customMsg (255, 0, 0, "%s has been banned by %s (5 minutes)!", player_name, getPlayerName (source))
		addBan (nil, nil, getPlayerSerial (player), source, "(nick: "..player_name..")"..((account_name ~= admin_name and " (by: "..account_name..")") or "")..(arg[3] and " "..arg[3] or ""), 60*5)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("ban5m", CmdBan5m, "resource.rafalh.ban5m", "Bans player for 5 minutes")

local function CmdBan1h (message, arg)
	local player = (#arg >= 2 and findPlayer (arg[2]))
	
	if (player) then
		local account_name = getAccountName (getPlayerAccount (source))
		local player_name = getPlayerName (player)
		local admin_name = getPlayerName (source)
		
		customMsg (255, 0, 0, "%s has been banned by %s (1 hour)!", player_name, getPlayerName (source))
		addBan (nil, nil, getPlayerSerial (player), source, "(nick: "..player_name..")"..((account_name ~= admin_name and " (by: "..account_name..")") or "")..(arg[3] and " "..arg[3] or ""), 3600)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("ban1h", CmdBan1h, "resource.rafalh.ban1h", "Bans player for 1 hour")

local function CmdBan24h (message, arg)
	local player = (#arg >= 2 and findPlayer (arg[2]))
	
	if (player) then
		local account_name = getAccountName (getPlayerAccount (source))
		local player_name = getPlayerName (player)
		local admin_name = getPlayerName (source)
		
		customMsg (255, 0, 0, "%s has been banned by %s (24 hours)!", player_name, getPlayerName (source))
		addBan (nil, nil, getPlayerSerial (player), source, "(nick: "..player_name..")"..((account_name ~= admin_name and " (by: "..account_name..")") or "")..(arg[3] and " "..arg[3] or ""), 24*3600)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("ban24h", CmdBan24h, "resource.rafalh.ban24h", "Bans player for 24 hours")

local function CmdMute (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	
	if (player) then
		mutePlayer (player, tonumber (arg[3]) or SmGetUInt ("mute_time"), source)
	else privMsg (source, "Usage: %s", arg[1].." <player> [<time>]") end
end

CmdRegister ("mute", CmdMute, "command.mute", "Mutes player on chat and voice-chat for 1 minute")

local function CmdPMute (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	
	if (player) then
		DbQuery ("UPDATE rafalh_players SET pmuted=1 WHERE player=?", g_Players[player].id)
		mutePlayer (player, false, source)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("pmute", CmdPMute, "resource.rafalh.pmute", "Mutes player for ever")

local function CmdUnmute (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	
	if (player) then
		DbQuery ("UPDATE rafalh_players SET pmuted=0 WHERE player=?", g_Players[player].id)
		if (isPlayerMuted (player)) then
			triggerEvent ("aPlayer", source, player, "mute")
		end
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("unmute", CmdUnmute, "command.unmute", "Unmutes player on chat and voice-chat")

local function CmdSetAddCash (message, arg)
	local player = (#arg >= 3 and findPlayer (arg[2])) or source
	local cash = toint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (cash) then
		outputServerLog (getPlayerName (source):gsub ("#%x%x%x%x%x%x", "").." executed: "..arg[1].." "..getPlayerName (player):gsub ("#%x%x%x%x%x%x", "").." "..cash)
		if (arg[1] == "!addcash" or arg[1] == "/addcash" or arg[1] == "addcash") then
			cash = cash + StGet (player, "cash")
		end
		StSet (player, "cash", cash)
		scriptMsg (getPlayerName (player).."'s cash: "..formatMoney (cash)..".")
	else privMsg (source, "Usage: %s", arg[1].." [<player>] <cash>") end
end

CmdRegister ("setcash", CmdSetAddCash, "command.setmoney")
CmdRegisterAlias ("addcash", "setcash")

local function CmdSetPoints (message, arg)
	local player = (#arg >= 3 and findPlayer (arg[2])) or source
	local pts = toint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (pts) then
		StSet (player, "points", pts)
		scriptMsg (getPlayerName (player).."'s points: "..formatNumber (pts)..".")
	else privMsg (source, "Usage: %s", arg[1].." [<player>] <points>") end
end

CmdRegister ("setpoints", CmdSetPoints, "resource.rafalh.setpoints", "Sets player points")

local function CmdSetBidLevel (message, arg)
	local player = (#arg >= 3 and findPlayer (arg[2])) or source
	local bidlvl = touint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (bidlvl) then
		StSet (player, "bidlvl", bidlvl)
		scriptMsg (getPlayerName (player).."'s bidlevel: "..bidlvl..".")
	else privMsg (source, "Usage: %s", arg[1].." [<player>] <bidlvl>") end
end

CmdRegister ("setbidlevel", CmdSetBidLevel, "resource.rafalh.setbidlevel", "Sets player bidlevel")

local function CmdWarn (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	
	if (player) then
		local warns = StGet (player, "warnings") + 1
		StSet (player, "warnings", warns)
		local max_warns = SmGetUInt ("max_warns", 0)
		if (max_warns > 0) then
			scriptMsg ("%s has been warned %u. time (limit: %u)!", getPlayerName (player), warns, max_warns)
		else
			scriptMsg ("%s has been warned %u. time!", getPlayerName (player), warns)
		end
		
		if (max_warns > 0 and rows[1].warnings > max_warns) then
			kickPlayer (player, source, rows[1].warnings.." warnings (limit: "..max_warns..")")
		end
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("warn", CmdWarn, "resource.rafalh.warn", "Adds player warning and bans if he has too many")

local function CmdUnwarn (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	
	if (player) then
		local warns = StGet (player, "warnings")
		if (warns > 0) then
			StSet (player, "warnings", warns - 1)
		end
		scriptMsg ("%s has been unwarned!", getPlayerName (player))
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("unwarn", CmdUnwarn, "resource.rafalh.unwarn", "Removes player warning")

local function CmdKill (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	
	if (player == source or hasObjectPermissionTo (source, "command.slap", false)) then
		killPed (player)
	else
		privMsg (source, "Access denied for \"%s\"!", arg[1])
	end
end

CmdRegister ("kill", CmdKill, false, "Kills player", true)

local function CmdRemMap (message, arg)
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	if (not map) then return end
	
	local reason = message:sub (arg[1]:len () + 2)
	if (reason:len () < 5) then
		privMsg (source, "Usage: %s", arg[1].." <reason>")
		return
	end
	
	local account = getPlayerAccount (source)
	reason = reason.." (removed by "..getAccountName (account)..")"
	
	local map_id = map:getId()
	DbQuery ("UPDATE rafalh_maps SET removed=? WHERE map=?", reason, map_id)
	
	local map_name = map:getName()
	customMsg (255, 0, 0, "%s has been removed by %s!", map_name, getPlayerName (source))
	startRandomMap(room)
end

CmdRegister ("remmap", CmdRemMap, "resource.rafalh.remmap", "Removes map from server")
CmdRegisterAlias ("removemap", "remmap")

local function CmdRestoreMap (message, arg)
	if (#arg >= 2) then
		local str = message:sub (arg[1]:len () + 2)
		local map = findMap (str, true)
		
		if (map) then
			local map_name = map:getName()
			local map_id = map:getId()
			DbQuery ("UPDATE rafalh_maps SET removed='' WHERE map=?", map_id)
			customMsg (0, 255, 0, "%s has been restored by %s!", map_name, getPlayerName (source))
		else privMsg (source, "Cannot find map \"%s\" or it has not been removed!", str) end
	else privMsg (source, "Usage: %s", arg[1].." <map>") end
end

CmdRegister ("restoremap", CmdRestoreMap, "resource.rafalh.restoremap", "Restores proviously removed map")

local function CmdMap (message, arg)
	local mapName = message:sub (arg[1]:len () + 2)
	local room = g_Players[source].room
	
	if (mapName:len () > 1) then
		local map
		
		if (mapName:lower () == "random") then
			map = getRandomMap ()
		else
			map = findMap (mapName, false)
		end
		
		if (map) then
			local map_name = map:getName()
			local map_id = map:getId()
			local rows = DbQuery ("SELECT removed FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
			
			if (rows[1].removed ~= "") then
				privMsg (source, "%s has been removed!", map_name)
			else
				GbCancelBets ()
				map:start(room)
			end
		else
			privMsg (source, "Cannot find map \"%s\"!", mapName)
		end
	else
		addEvent ("onClientDisplayChangeMapGuiReq", true)
		triggerClientEvent (source, "onClientDisplayChangeMapGuiReq", g_ResRoot)
	end
end

CmdRegister ("map", CmdMap, "command.setmap", "Changes current map")

local function AddMapToQueue(room, map)
	local map_id = map:getId()
	local rows = DbQuery ("SELECT removed FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
	if (rows[1].removed ~= "") then
		local map_name = map:getName()
		privMsg (source, "%s has been removed!", map_name)
	else
		MqAdd(room, map, true, source)
	end
end

local function CmdNextMap (message, arg)
	local mapName = message:sub (arg[1]:len () + 2)
	if (mapName:len () > 1) then
		local room = g_Players[source].room
		assert(type(room) == "table")
		
		local map
		if (mapName:lower () == "random") then
			map = getRandomMap()
		elseif (mapName:lower () == "redo") then
			map = getCurrentMap(room)
		else
			map = findMap(mapName, false)
		end
		
		if (map) then
			AddMapToQueue(room, map)
		else
			privMsg (source, "Cannot find map \"%s\"!", mapName)
		end
	else
		addEvent ("onClientDisplayNextMapGuiReq", true)
		triggerClientEvent (source, "onClientDisplayNextMapGuiReq", g_ResRoot)
	end
end

CmdRegister ("nextmap", CmdNextMap, "resource.rafalh.nextmap", "Adds next map to queue")
CmdRegisterAlias ("next", "nextmap", true)

-- For Admin Panel
local function onSetNextMap (mapName)
	if (hasObjectPermissionTo(client, "resource.rafalh.nextmap", false)) then
		local map = findMap(mapName, false)
		if(map) then
			local pdata = g_Players[client]
			AddMapToQueue(pdata.room, map)
		end
	end
end

addEvent ("setNextMap_s", true)
addEventHandler ("setNextMap_s", g_Root, onSetNextMap)

local function CmdCancelNextMap (message, arg)
	local room = g_Players[source].room
	local map = MqRemove(room)
	if(map) then
		local mapName = map:getName()
		outputMsg(room.el, "#80FFC0", "%s has been removed from map queue by %s!", mapName, getPlayerName(source))
	else
		privMsg(source, "Map queue is empty!")
	end
end

CmdRegister ("cancelnext", CmdCancelNextMap, "resource.rafalh.nextmap", "Removes last map from queue")

local function CmdRedo (message, arg)
	local now = getRealTime ().timestamp
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	if (map and now - g_LastRedo > 10) then
		GbCancelBets ()
		g_LastRedo = now
		map:start(room)
	else
		privMsg(source, "You cannot redo yet "..(now - g_LastRedo).." "..tostring(map))
	end
end

CmdRegister ("redo", CmdRedo, "command.setmap", "Restarts current map")

local function CmdIp (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	
	scriptMsg ("%s's IP: %s.", getPlayerName (player), getPlayerIP (player))
end

CmdRegister ("ip", CmdIp, "resource.rafalh.ip", "Shows player IP address")

local function CmdAccount (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	
	scriptMsg (getPlayerName (player).."'s account: "..g_Players[player].id..".")
end

CmdRegister ("account", CmdAccount, false, "Shows player account ID")

local function CmdFindAccounts (message, arg)
	if (#arg >= 2) then
		local buf = ""
		local tbl = {}
		local name = message:sub (arg[1]:len () + 2)
		local rows = DbQuery ("SELECT player FROM rafalh_names WHERE name LIKE ?", "%"..name.."%")
		
		for i, data in ipairs (rows) do
			if not tbl[data.player] then
				buf = buf..((buf ~= "" and ", ") or "")..data.player
				tbl[data.player] = true
			end
		end
		scriptMsg ("Found accounts: "..((buf ~= "" and buf..".") or "none."))
	else privMsg (source, "Usage: %s", arg[1].." <name>") end
end

CmdRegister ("findaccounts", CmdFindAccounts, "resource.rafalh.findaccounts")
CmdRegisterAlias ("findacc", "findaccounts")

local function CmdFindAccountsIp (message, arg)
	if (#arg >= 2) then
		local buf = ""
		local rows = DbQuery ("SELECT player FROM rafalh_players WHERE ip LIKE ?", arg[2].."%")
		
		for i, data in ipairs (rows) do
			buf = buf..((buf ~= "" and ", ") or "")..data.player
		end
		scriptMsg ("Found accounts: %s", (buf ~= "" and buf..".") or "none.")
	else privMsg (source, "Usage: %s", arg[1].." <ip>") end
end

CmdRegister ("findaccountsip", CmdFindAccountsIp, "resource.rafalh.findaccounts")
CmdRegisterAlias ("findaccip", "findaccountsip")

local function CmdAccountLastVisit (message, arg)
	local id = touint (arg[2])
	if (id) then
		local rows = DbQuery ("SELECT last_visit FROM rafalh_players WHERE player=?", id)
		if (rows and rows[1]) then
			local time = getRealTime (rows[1].last_visit)
			scriptMsg ("Account last visit: %d-%02d-%02d %d:%02d:%02d.", time.monthday, time.month + 1, time.year + 1900, time.hour, time.minute, time.second)
		else privMsg (source, "Cannot find account %u!", id) end
	else privMsg (source, "Usage: %s", arg[1].." <account ID>") end
end

CmdRegister ("accountlastvisit", CmdAccountLastVisit, "resource.rafalh.findaccounts")
CmdRegisterAlias ("alastvisit", "accountlastvisit")

local function CmdFindLostAccount (message, arg)
	if (#arg >= 2) then
		local player = findPlayer (message:sub (arg[1]:len () + 2))
		if (player) then
			local t = {}
			local str = message:sub (arg[1]:len () + 2)
			local rows = DbQuery ("SELECT player FROM rafalh_names WHERE name LIKE ?", "%"..str.."%")
			for i, data in ipairs (rows) do
				if not t[data.player] then
					buf = buf..((buf ~= "" and ", ") or "")..data.player
					t[data.player] = true
				end
			end
			scriptMsg ("Found accounts: %s", (buf ~= "" and buf..".") or "none.")
		else privMsg (source, "Cannot find player") end
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister ("findlostaccount", CmdFindLostAccount, "resource.rafalh.findaccounts")
CmdRegisterAlias ("findlostacc", "findlostaccount")

local function CmdDescribeAccount (message, arg)
	local id = touint (arg[2])
	if (id) then
		local rows = DbQuery ("SELECT * FROM rafalh_players  WHERE player=?", id)
		if (rows and rows[1]) then
			local tm = getRealTime (rows[1].last_visit)
			local tm2 = getRealTime (rows[1].first_visit)
			scriptMsg ("Name: %s, points: %s, cash: %u, bidlevel: %u, playtime: %u, last visit: %d-%02d-%02d %d:%02d:%02d, joined: %d-%02d-%02d %d:%02d:%02d, ip: %s.",
				rows[1].name, rows[1].points, rows[1].cash, rows[1].bidlvl, rows[1].time_here,
				tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute, tm.second,
				tm2.monthday, tm2.month + 1, tm2.year + 1900, tm2.hour, tm2.minute, tm2.second,
				rows[1].ip)
		else privMsg (source, "Cannot find account %u!", id) end
	else privMsg (source, "Usage: %s", arg[1].." <account ID>") end
end

CmdRegister ("describeaccount", CmdDescribeAccount, "resource.rafalh.findaccounts")
CmdRegisterAlias ("descra", "describeaccount")

local function CmdMergeAccounts(message, arg)
	local player = findPlayer(arg[2])
	local pdata = g_Players[player]
	local id = touint(arg[3])
	
	if(player and id) then
		if(pdata.id == id) then
			privMsg(source, "Cannot merge account with the same account!", id)
			return
		end
		
		-- get statistics for id
		local rows = DbQuery("SELECT * FROM rafalh_players WHERE player=?", id)
		local src_data = rows and rows[1]
		if(not src_data) then
			privMsg(source, "Cannot find account %u!", id)
			return
		end
		
		-- remove duplicated names
		local rows = DbQuery("SELECT name FROM rafalh_names WHERE player=?", id)
		local names = {}
		local questionMarks = {}
		for i, data in ipairs(rows) do
			table.insert(names, data.name)
			table.insert(questionMarks, "?")
		end
		local questionMarksStr = table.concat(questionMarks, ",")
		DbQuery("DELETE FROM rafalh_names WHERE player=? AND name IN ("..questionMarksStr..")", id, unpack(names))
		
		-- change all names owner
		DbQuery("UPDATE rafalh_names SET player=? WHERE player=?", pdata.id, id)
		
		-- update stats
		local stats = {}
		stats.cash = StGet (player, "cash") + src_data.cash
		stats.points = StGet (player, "points") + src_data.points
		stats.warnings = StGet (player, "warnings") + src_data.warnings
		stats.dm = StGet (player, "dm") + src_data.dm
		stats.dm_wins= StGet (player, "dm_wins") + src_data.dm_wins
		stats.first = StGet (player, "first") + src_data.first
		stats.second = StGet (player, "second") + src_data.second
		stats.third = StGet (player, "third") + src_data.third
		stats.bidlvl = math.max (src_data.bidlvl, StGet (player, "bidlvl"))
		stats.time_here = StGet (player, "time_here") + src_data.time_here
		StSet (player, stats)
		
		local rows = DbQuery("SELECT joinmsg FROM rafalh_players WHERE player=?", pdata.id)
		if(rows[1].joinmsg == "" and src_data.joinmsg ~= "") then
			DbQuery("UPDATE rafalh_players SET joinmsg=? WHERE player=?", src_data.joinmsg, pdata.id)
		end
		
		-- remove duplicated rates
		local rows = DbQuery("SELECT map FROM rafalh_rates WHERE player=?", id)
		local maps = {}
		local questionMarks = {}
		for i, data in ipairs(rows) do
			table.insert(maps, data.map)
			table.insert(questionMarks, "?")
		end
		local questionMarksStr = table.concat(questionMarks, ",")
		DbQuery("DELETE FROM rafalh_rates WHERE player=? AND map IN ("..questionMarksStr..")", id, unpack(maps))
		
		-- set new rates owner
		DbQuery("UPDATE rafalh_rates SET player=? WHERE player=?", pdata.id, id)
		
		-- sync best times
		local rows = DbQuery ("SELECT map, time FROM rafalh_besttimes WHERE player=?", id)
		for i, data in ipairs (rows) do
			addPlayerTime (pdata.id, data.map, data.time)
		end
		
		-- remove player from system
		DbQuery("DELETE FROM rafalh_besttimes WHERE player=?", id)
		DbQuery("DELETE FROM rafalh_profiles WHERE player=?", id)
		DbQuery("DELETE FROM rafalh_players WHERE player=?", id)
		
		scriptMsg("Accounts has been merged. Old account has been removed...")
	else privMsg(source, "Usage: %s", arg[1].." <player> <other account ID>") end
end

CmdRegister ("mergeaccounts", CmdMergeAccounts, "resource.rafalh.mergeaccounts")
CmdRegisterAlias ("mergeacc", "mergeaccounts")

local function CmdRemTopTime (message, arg)
	local room = g_Players[source].room
	local n = touint (arg[2], 0)
	if (n >= 1 and n <= 8) then
		local map = getCurrentMap(room)
		if (map) then
			local map_id = map:getId()
			local rows = DbQuery("SELECT p.player, p.name, bt.time FROM rafalh_besttimes bt, rafalh_players p WHERE map=? AND bt.player=p.player ORDER BY time LIMIT "..(n + 3), map_id)
			if (rows and rows[n]) then
				DbQuery("DELETE FROM rafalh_besttimes WHERE player=? AND map=?", rows[n].player, map_id)
				StSet(rows[n].player, "toptimes_count", StGet (rows[n].player, "toptimes_count") - 1)
				if(rows[4] and n <= 3) then
					StSet(rows[4].player, "toptimes_count", StGet (rows[4].player, "toptimes_count") + 1)
				end
				BtDeleteCache ()
				BtSendMapInfo (false)
				
				local f = fileExists ("logs/remtoptime.log") and fileOpen ("logs/remtoptime.log") or fileCreate ("logs/remtoptime.log")
				if (f) then
					fileSetPos (f, fileGetSize (f)) -- append to file
					
					local next_tops = ""
					for i = n + 1, math.min (n+3, #rows), 1 do
						next_tops = next_tops..", "..formatTimePeriod (rows[i].time / 1000)
					end
					
					local tm = getRealTime ()
					fileWrite (f, ("[%u.%02u.%u %u-%02u-%02u] "):format (tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute, tm.second)..getPlayerName (source).." removed "..n..". toptime ("..formatTimePeriod (rows[n].time / 1000).." by "..rows[n].name..") on map "..map:getName().."."..(next_tops ~= "" and " Next toptimes: "..next_tops:sub (3).."." or "").."\n")
					
					fileClose (f)
				end
				
				outputMsg(room.el, "#FF0000", "%u. toptime (%s by %s) has been removed by %s!", n, formatTimePeriod (rows[n].time / 1000), rows[n].name, getPlayerName (source))
			else
				privMsg(source, "There are only %u toptimes saved!", #rows)
			end
		else privMsg (source, "Cannot find map!") end
	else privMsg (source, "Usage: %s", arg[1].." <toptime number>") end
end

CmdRegister ("remtoptime", CmdRemTopTime, "resource.rafalh.remtoptime", "Removes specified toptime on current map")

local function CmdResetStats(message, arg)
	local player = #arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))
	if(player) then
		DbQuery("DELETE FROM rafalh_besttimes WHERE player=?", g_Players[player].id)
		local stats = {
			cash = 0, bidlvl = 0, points = 0, warnings = 0, dm = 0, dm_wins = 0,
			first = 0, second = 0, third = 0, toptimes_count = 0 }
		StSet (player, stats)
		scriptMsg("Statistics has been reset for %s!", getPlayerName (player))
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("resetstats", CmdResetStats, "resource.rafalh.resetstats", "Resets player statistics")

local function CmdResetStats(message, arg)
	local playerId = touint(arg[2])
	if(playerId) then
		if(g_IdToPlayer[playerId]) then
			scriptMsg("You cannot remove online players")
			return
		end
		
		DbQuery("DELETE FROM rafalh_names WHERE player=?", playerId)
		DbQuery("DELETE FROM rafalh_rates WHERE player=?", playerId)
		DbQuery("DELETE FROM rafalh_besttimes WHERE player=?", playerId)
		DbQuery("DELETE FROM rafalh_profiles WHERE player=?", playerId)
		DbQuery("DELETE FROM rafalh_players WHERE player=?", playerId)
		
		scriptMsg("Account %u has been deleted!", playerId)
	else privMsg(source, "Usage: %s", arg[1].." <account ID>") end
end

CmdRegister("delacc", CmdResetStats, "resource.rafalh.resetstats", "Deletes player account")

local function CmdSqlQuery(message, arg)
	local query = #arg >= 2 and message:sub (arg[1]:len () + 2)
	if (query) then
		local rows = DbQuery(query)
		if(rows) then
			privMsg(source, "SQL query succeeded ("..#rows.." rows)")
			for i, data in ipairs(rows) do
				local tbl = {}
				for k, v in pairs(data) do
					table.insert(tbl, tostring(k).."="..tostring(v))
				end
				local buf = i..". "..table.concat(tbl, ", ")
				privMsg(source, buf:sub(1, 100))
				if(i > 10) then break end
			end
		else
			privMsg(source, "SQL query failed")
		end
	else privMsg (source, "Usage: %s", arg[1].." <query>") end
end

CmdRegister ("sqlquery", CmdSqlQuery, true)

local function CmdMapId (message, arg)
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	scriptMsg("Map ID: %u", map:getId())
end

CmdRegister ("mapid", CmdMapId, true)
