local g_LastRedo = 0

---------------------------------
-- Global function definitions --
---------------------------------

local function CmdPBan (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (arg[2]))
	
	if (playerEl) then
		local account_name = getAccountName (getPlayerAccount (source))
		local player_name = getPlayerName (playerEl)
		local admin_name = getPlayerName (source)
		
		customMsg (255, 0, 0, "%s serial has been banned by %s!", player_name, admin_name)
		addBan (nil, nil, getPlayerSerial (playerEl), source, "(nick: "..player_name..")"..((account_name ~= admin_name and " (by: "..account_name..")") or "")..(arg[3] and " "..arg[3] or ""))
	else
		privMsg (source, "Usage: %s", arg[1].." <player>")
	end
end

CmdRegister("pban", CmdPBan, "command.banserial")

local function CmdBan1m (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (arg[2]))
	
	if (playerEl) then
		local account_name = getAccountName (getPlayerAccount (source))
		local player_name = getPlayerName (playerEl)
		local admin_name = getPlayerName (source)
		
		customMsg (255, 0, 0, "%s has been banned by %s (1 minute)!", player_name, getPlayerName (source))
		addBan (nil, nil, getPlayerSerial (playerEl), source, "(nick: "..player_name..")"..((account_name ~= admin_name and " (by: "..account_name..")") or "")..(arg[3] and " "..arg[3] or ""), 60)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("ban1m", CmdBan1m, "resource.rafalh.ban1m", "Bans player for 1 minute")

local function CmdBan5m (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (arg[2]))
	
	if (playerEl) then
		local account_name = getAccountName (getPlayerAccount (source))
		local player_name = getPlayerName (playerEl)
		local admin_name = getPlayerName (source)
		
		customMsg (255, 0, 0, "%s has been banned by %s (5 minutes)!", player_name, getPlayerName (source))
		addBan (nil, nil, getPlayerSerial (playerEl), source, "(nick: "..player_name..")"..((account_name ~= admin_name and " (by: "..account_name..")") or "")..(arg[3] and " "..arg[3] or ""), 60*5)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("ban5m", CmdBan5m, "resource.rafalh.ban5m", "Bans player for 5 minutes")

local function CmdBan1h (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (arg[2]))
	
	if (playerEl) then
		local account_name = getAccountName (getPlayerAccount (source))
		local player_name = getPlayerName (playerEl)
		local admin_name = getPlayerName (source)
		
		customMsg (255, 0, 0, "%s has been banned by %s (1 hour)!", player_name, getPlayerName (source))
		addBan (nil, nil, getPlayerSerial (playerEl), source, "(nick: "..player_name..")"..((account_name ~= admin_name and " (by: "..account_name..")") or "")..(arg[3] and " "..arg[3] or ""), 3600)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("ban1h", CmdBan1h, "resource.rafalh.ban1h", "Bans player for 1 hour")

local function CmdBan24h (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (arg[2]))
	
	if (playerEl) then
		local account_name = getAccountName (getPlayerAccount (source))
		local player_name = getPlayerName (playerEl)
		local admin_name = getPlayerName (source)
		
		customMsg (255, 0, 0, "%s has been banned by %s (24 hours)!", player_name, getPlayerName (source))
		addBan (nil, nil, getPlayerSerial (playerEl), source, "(nick: "..player_name..")"..((account_name ~= admin_name and " (by: "..account_name..")") or "")..(arg[3] and " "..arg[3] or ""), 24*3600)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("ban24h", CmdBan24h, "resource.rafalh.ban24h", "Bans player for 24 hours")

local function CmdMute (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	
	if (playerEl) then
		mutePlayer(playerEl, tonumber (arg[3]) or SmGetUInt ("mute_time"), source)
	else privMsg(source, "Usage: %s", arg[1].." <player> [<time>]") end
end

CmdRegister("mute", CmdMute, "command.mute", "Mutes player on chat and voice-chat for 1 minute")

local function CmdPMute (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	local player = playerEl and g_Players[playerEl]
	
	if (player) then
		player.accountData:set("pmuted", 1)
		mutePlayer(player.el, false, source)
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("pmute", CmdPMute, "resource.rafalh.pmute", "Mutes player for ever")

local function CmdUnmute (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	local player = playerEl and g_Players[playerEl]
	
	if(player) then
		player.accountData:set("pmuted", 0)
		if(isPlayerMuted(player.el)) then
			triggerEvent("aPlayer", source, player.el, "mute")
		end
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("unmute", CmdUnmute, "command.unmute", "Unmutes player on chat and voice-chat")

local function CmdSetAddCash (message, arg)
	local playerEl = (#arg >= 3 and findPlayer (arg[2])) or source
	local player = playerEl and g_Players[playerEl]
	local cash = toint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (cash) then
		outputServerLog(getPlayerName(source):gsub ("#%x%x%x%x%x%x", "").." executed: "..arg[1].." "..getPlayerName(player.el):gsub ("#%x%x%x%x%x%x", "").." "..cash)
		if (arg[1] == "!addcash" or arg[1] == "/addcash" or arg[1] == "addcash") then
			cash = cash + player.accountData:get("cash")
		end
		player.accountData:set("cash", cash)
		scriptMsg(getPlayerName(player.el).."'s cash: "..formatMoney(cash)..".")
	else privMsg(source, "Usage: %s", arg[1].." [<player>] <cash>") end
end

CmdRegister("setcash", CmdSetAddCash, "command.setmoney")
CmdRegisterAlias ("addcash", "setcash")

local function CmdSetPoints (message, arg)
	local playerEl = (#arg >= 3 and findPlayer (arg[2])) or source
	local player = playerEl and g_Players[playerEl]
	local pts = toint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (pts) then
		player.accountData:set("points", pts)
		scriptMsg(getPlayerName(player.el).."'s points: "..formatNumber(pts)..".")
	else privMsg(source, "Usage: %s", arg[1].." [<player>] <points>") end
end

CmdRegister("setpoints", CmdSetPoints, "resource.rafalh.setpoints", "Sets player points")

local function CmdSetBidLevel (message, arg)
	local playerEl = (#arg >= 3 and findPlayer (arg[2])) or source
	local player = playerEl and g_Players[playerEl]
	local bidlvl = touint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (bidlvl) then
		player.accountData:set("bidlvl", bidlvl)
		scriptMsg(getPlayerName(player).."'s bidlevel: "..bidlvl..".")
	else privMsg(source, "Usage: %s", arg[1].." [<player>] <bidlvl>") end
end

CmdRegister("setbidlevel", CmdSetBidLevel, "resource.rafalh.setbidlevel", "Sets player bidlevel")

local function CmdWarn(message, arg)
	local playerEl = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	local player = playerEl and g_Players[playerEl]
	
	if (player) then
		local warns = player.accountData:get("warnings") + 1
		player.accountData:set("warnings", warns)
		local max_warns = SmGetUInt ("max_warns", 0)
		if(max_warns > 0) then
			scriptMsg ("%s has been warned %u. time (limit: %u)!", getPlayerName(player.el), warns, max_warns)
		else
			scriptMsg ("%s has been warned %u. time!", getPlayerName(player.el), warns)
		end
		
		if (max_warns > 0 and warns > max_warns) then
			kickPlayer(player.el, source, warns.." warnings (limit: "..max_warns..")")
		end
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("warn", CmdWarn, "resource.rafalh.warn", "Adds player warning and bans if he has too many")

local function CmdUnwarn (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2)))
	local player = playerEl and g_Players[playerEl]
	
	if (player) then
		local warns = player.accountData:get("warnings")
		if (warns > 0) then
			player.accountData:set("warnings", warns - 1)
		end
		scriptMsg("%s has been unwarned!", getPlayerName(player.el))
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("unwarn", CmdUnwarn, "resource.rafalh.unwarn", "Removes player warning")

local function CmdKill (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	
	if (playerEl == source or hasObjectPermissionTo (source, "command.slap", false)) then
		killPed(playerEl)
	else
		privMsg(source, "Access denied for \"%s\"!", arg[1])
	end
end

CmdRegister("kill", CmdKill, false, "Kills player", true)

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

CmdRegister("remmap", CmdRemMap, "resource.rafalh.remmap", "Removes map from server")
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

CmdRegister("restoremap", CmdRestoreMap, "resource.rafalh.restoremap", "Restores proviously removed map")

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

CmdRegister("map", CmdMap, "command.setmap", "Changes current map")

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

CmdRegister("nextmap", CmdNextMap, "resource.rafalh.nextmap", "Adds next map to queue")
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

CmdRegister("cancelnext", CmdCancelNextMap, "resource.rafalh.nextmap", "Removes last map from queue")

local function CmdRedo (message, arg)
	local now = getRealTime ().timestamp
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	if (map and now - g_LastRedo > 10) then
		GbCancelBets ()
		g_LastRedo = now
		map:start(room)
	else
		privMsg(source, "You cannot redo yet! Please wait "..(now - g_LastRedo).." seconds.")
	end
end

CmdRegister("redo", CmdRedo, "command.setmap", "Restarts current map")

local function CmdIp (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	
	scriptMsg ("%s's IP: %s.", getPlayerName (player), getPlayerIP (player))
end

CmdRegister("ip", CmdIp, "resource.rafalh.ip", "Shows player IP address")

local function CmdAccount(message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	local pdata = g_Players[player]
	
	scriptMsg(getPlayerName(player).."'s account ID: "..(pdata.id or "none")..".")
end

CmdRegister("account", CmdAccount, false, "Shows player account ID")

local function CmdFindAccountsIp(message, arg)
	if(#arg >= 2) then
		local buf = ""
		local rows = DbQuery("SELECT player FROM rafalh_players WHERE ip LIKE ?", arg[2].."%")
		local found = {}
		
		for i, data in ipairs (rows) do
			table.insert(found, data.player)
		end
		local foundStr = #found > 0 and table.concat(found, ", ") or "none"
		scriptMsg("Found accounts: %s", foundStr)
	else privMsg(source, "Usage: %s", arg[1].." <ip>") end
end

CmdRegister("findaccountsip", CmdFindAccountsIp, "resource.rafalh.findaccounts")
CmdRegisterAlias("findaccip", "findaccountsip")

local function CmdDescribeAccount(message, arg)
	local id = touint(arg[2])
	if(id) then
		local accountData = PlayerAccountData.create(id)
		local data = accountData:getTbl()
		local tm = getRealTime (data.last_visit)
		local tm2 = getRealTime (data.first_visit)
		scriptMsg("Name: %s, points: %s, cash: %u, bidlevel: %u, playtime: %u, last visit: %d-%02d-%02d %d:%02d:%02d, joined: %d-%02d-%02d %d:%02d:%02d, IP: %s, serial: %s.",
			data.name, data.points, data.cash, data.bidlvl, data.time_here,
			tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute, tm.second,
			tm2.monthday, tm2.month + 1, tm2.year + 1900, tm2.hour, tm2.minute, tm2.second,
			data.ip, data.serial)
	else privMsg(source, "Usage: %s", arg[1].." <account ID>") end
end

CmdRegister("describeaccount", CmdDescribeAccount, "resource.rafalh.findaccounts")
CmdRegisterAlias ("descra", "describeaccount")

local function CmdMergeAccounts(message, arg)
	local player = findPlayer(arg[2])
	local pdata = g_Players[player]
	local id = touint(arg[3])
	
	if(player and id and pdata.id) then
		if(pdata.id == id) then
			privMsg(source, "Cannot merge account with the same account!", id)
			return
		end
		
		-- get statistics for id
		local srcAccountData = PlayerAccountData.create(id)
		local src_data = srcAccountData:getTbl()
		if(not src_data) then
			privMsg(source, "Cannot find account %u!", id)
			return
		end
		
		--[[if(src_data.first_visit > pdata.accountData.first_visit) then
			privMsg(source, "Account for merge is newer")
			return
		end]]
		
		-- remove duplicated names
		local names = {}
		local questionMarks = {}
		local rows = DbQuery("SELECT n1.name FROM rafalh_names n1, rafalh_names n2 WHERE n1.player=? AND n2.player=? AND n1.name=n2.name", pdata.id, id)
		for i, data in ipairs(rows) do
			table.insert(names, data.name)
			table.insert(questionMarks, "?")
		end
		
		local questionMarksStr = table.concat(questionMarks, ",")
		DbQuery("DELETE FROM rafalh_names WHERE player=? AND name IN ("..questionMarksStr..")", id, unpack(names)) -- remove duplicates
		DbQuery("UPDATE rafalh_names SET player=? WHERE player=?", pdata.id, id) -- change all names owner
		
		-- update stats
		local newData = {}
		newData.cash = pdata.accountData.cash + src_data.cash
		newData.points = pdata.accountData.points + src_data.points
		newData.warnings = pdata.accountData.warnings + src_data.warnings
		newData.bidlvl = math.max(src_data.bidlvl, pdata.accountData.bidlvl)
		newData.time_here = pdata.accountData.time_here + src_data.time_here
		newData.first_visit = src_data.first_visit
		if(pdata.accountData.email == "") then
			newData.email = src_data.email
		end
		
		-- Old statistics
		newData.dm = pdata.accountData.dm + src_data.dm
		newData.dm_wins= pdata.accountData.dm_wins + src_data.dm_wins
		newData.first = pdata.accountData.first + src_data.first
		newData.second = pdata.accountData.second + src_data.second
		newData.third = pdata.accountData.third + src_data.third
		newData.exploded = pdata.accountData.exploded + src_data.exploded
		newData.drowned = pdata.accountData.drowned + src_data.drowned
		
		-- New statistics
		newData.maxWinStreak = math.max(pdata.accountData.maxWinStreak, src_data.maxWinStreak)
		newData.mapsPlayed = pdata.accountData.mapsPlayed + src_data.mapsPlayed
		newData.mapsBought = pdata.accountData.mapsBought + src_data.mapsBought
		-- mapsRated are set later
		newData.huntersTaken = pdata.accountData.huntersTaken + src_data.huntersTaken
		newData.dmVictories = pdata.accountData.dmVictories + src_data.dmVictories
		newData.ddVictories = pdata.accountData.ddVictories + src_data.ddVictories
		newData.raceVictories = pdata.accountData.raceVictories + src_data.raceVictories
		newData.racesFinished = pdata.accountData.racesFinished + src_data.racesFinished
		newData.dmPlayed = pdata.accountData.dmPlayed + src_data.dmPlayed
		newData.ddPlayed = pdata.accountData.ddPlayed + src_data.ddPlayed
		newData.racesPlayed = pdata.accountData.racesPlayed + src_data.racesPlayed
		
		-- Join Msg
		if(pdata.accountData.joinmsg == "" and src_data.joinmsg ~= "") then
			newData.joinmsg = src_data.joinmsg
		end
		
		-- Rates
		local rows = DbQuery("SELECT r1.map FROM rafalh_rates r1, rafalh_rates r2 WHERE r1.player=? AND r2.player=? AND r1.map=r2.map", pdata.id, id)
		local maps = {}
		local questionMarks = {}
		for i, data in ipairs(rows) do
			table.insert(maps, data.map)
			table.insert(questionMarks, "?")
		end
		if(#maps > 0) then
			local questionMarksStr = table.concat(questionMarks, ",")
			DbQuery("DELETE FROM rafalh_rates WHERE player=? AND map IN ("..questionMarksStr..")", id, unpack(maps)) -- remove duplicates
		end
		DbQuery("UPDATE rafalh_rates SET player=? WHERE player=?", pdata.id, id) -- set new rates owner
		local rows = DbQuery("SELECT COUNT(map) AS c FROM rafalh_rates WHERE player=?", pdata.id)
		newData.mapsRated = rows[1].c
		
		-- Best times
		local rows = DbQuery("SELECT bt1.map, bt1.time AS time1, bt2.time AS time2 FROM rafalh_besttimes bt1, rafalh_besttimes bt2 WHERE bt1.player=? AND bt2.player=? AND bt1.map=bt2.map", pdata.id, id)
		local mapsSrc, mapsDst = {}, {}
		local questionMarksSrc, questionMarksDst = {}, {}
		newData.toptimes_count = pdata.accountData.toptimes_count + src_data.toptimes_count
		
		for i, data in ipairs(rows) do
			local delTime = math.min(data.time1, data.time2)
			if(data.time1 > data.time2) then -- old besttime was better
				table.insert(mapsDst, data.map)
				table.insert(questionMarksDst, "?")
			else -- new besttime is better
				table.insert(mapsSrc, data.map)
				table.insert(questionMarksSrc, "?")
			end
			
			local rows = DbQuery("SELECT COUNT(player) AS pos FROM rafalh_besttimes WHERE map=? AND time<=?", data.map, delTime)
			if(rows[1].pos <= 3) then
				newData.toptimes_count = newData.toptimes_count - 1
			end
		end
		if(#mapsDst > 0) then
			local questionMarksStr = table.concat(questionMarksDst, ",")
			DbQuery("DELETE FROM rafalh_besttimes WHERE player=? AND map IN ("..questionMarksStr..")", pdata.id, unpack(mapsDst)) -- remove duplicates
		end
		if(#mapsSrc > 0) then
			local questionMarksStr = table.concat(questionMarksSrc, ",")
			DbQuery("DELETE FROM rafalh_besttimes WHERE player=? AND map IN ("..questionMarksStr..")", id, unpack(mapsSrc)) -- remove duplicates
		end
		DbQuery("UPDATE rafalh_besttimes SET player=? WHERE player=?", pdata.id, id) -- set new best times owner
		
		-- Profile fields
		local rows = DbQuery("SELECT p1.field FROM rafalh_profiles p1, rafalh_profiles p2 WHERE p1.player=? AND p2.player=? AND p1.field=p2.field", pdata.id, id)
		local fields = {}
		local questionMarks = {}
		for i, data in ipairs(rows) do
			table.insert(fields, data.field)
			table.insert(questionMarks, "?")
		end
		local questionMarksStr = table.concat(questionMarks, ",")
		DbQuery("DELETE FROM rafalh_profiles WHERE player=? AND field IN ("..questionMarksStr..")", id, unpack(fields)) -- remove duplicates
		DbQuery("UPDATE rafalh_profiles SET player=? WHERE player=?", pdata.id, id) -- set new profile fields owner
		
		-- Set new account data and delete old account
		pdata.accountData:set(newData, true)
		DbQuery("DELETE FROM rafalh_players WHERE player=?", id)
		AchvInvalidateCache(player)
		
		scriptMsg("Accounts has been merged. Old account has been removed...")
	else privMsg(source, "Usage: %s", arg[1].." <player> <other account ID>") end
end

CmdRegister("mergeaccounts", CmdMergeAccounts, "resource.rafalh.mergeaccounts")
CmdRegisterAlias ("mergeacc", "mergeaccounts")

local function CmdRemTopTime(message, arg)
	local room = g_Players[source].room
	local n = touint(arg[2], 0)
	if (n >= 1 and n <= 8) then
		local map = getCurrentMap(room)
		if (map) then
			local map_id = map:getId()
			local rows = DbQuery("SELECT player, time FROM rafalh_besttimes WHERE map=? ORDER BY time LIMIT "..math.max(n, 4), map_id)
			if(rows and rows[n]) then
				DbQuery("DELETE FROM rafalh_besttimes WHERE player=? AND map=?", rows[n].player, map_id)
				local accountData = PlayerAccountData.create(rows[n].player)
				if(n <= 3) then
					accountData:add("toptimes_count", -1)
					if(rows[4]) then
						PlayerAccountData.create(rows[4].player):add("toptimes_count", 1)
					end
				end
				BtDeleteCache()
				BtSendMapInfo(false)
				
				local f = fileExists("logs/remtoptime.log") and fileOpen("logs/remtoptime.log") or fileCreate("logs/remtoptime.log")
				if(f) then
					fileSetPos(f, fileGetSize (f)) -- append to file
					
					local next_tops = ""
					for i = n + 1, math.min (n+3, #rows), 1 do
						next_tops = next_tops..", "..formatTimePeriod(rows[i].time / 1000)
					end
					
					local tm = getRealTime()
					fileWrite(f, ("[%u.%02u.%u %u-%02u-%02u] "):format(tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute, tm.second)..
						getPlayerName(source).." removed "..n..". toptime ("..formatTimePeriod(rows[n].time / 1000).." by "..accountData:get("name")..") on map "..map:getName().."."..
						(next_tops ~= "" and " Next toptimes: "..next_tops:sub(3).."." or "").."\n")
					
					fileClose(f)
				end
				
				outputMsg(room.el, "#FF0000", "%u. toptime (%s by %s) has been removed by %s!",
					n, formatTimePeriod(rows[n].time / 1000), accountData:get("name"), getPlayerName(source))
			elseif(rows) then
				privMsg(source, "There are only %u toptimes saved!", #rows)
			end
		else privMsg(source, "Cannot find map!") end
	else privMsg(source, "Usage: %s", arg[1].." <toptime number>") end
end

CmdRegister("remtoptime", CmdRemTopTime, "resource.rafalh.remtoptime", "Removes specified toptime on current map")

local function CmdResetStats(message, arg)
	local player = #arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))
	local pdata = player and g_Players[player]
	if(pdata and pdata.id) then
		DbQuery("DELETE FROM rafalh_besttimes WHERE player=?", pdata.id)
		local stats = {
			cash = 0, bidlvl = 0, points = 0, warnings = 0, dm = 0, dm_wins = 0,
			first = 0, second = 0, third = 0, toptimes_count = 0 }
		pdata.accountData:set(stats)
		scriptMsg("Statistics has been reset for %s!", getPlayerName(player))
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("resetstats", CmdResetStats, "resource.rafalh.resetstats", "Resets player statistics")

local function CmdDelAcc(message, arg)
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

CmdRegister("delacc", CmdDelAcc, "resource.rafalh.resetstats", "Deletes player account")

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
				privMsg(source, buf:sub(1, 512))
				if(i > 10) then break end
			end
		else
			privMsg(source, "SQL query failed")
		end
	else privMsg(source, "Usage: %s", arg[1].." <query>") end
end

CmdRegister("sqlquery", CmdSqlQuery, true)

local function CmdMapId(message, arg)
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	scriptMsg("Map ID: %u", map:getId())
end

CmdRegister("mapid", CmdMapId, true)

local function loadMsgIdSet(path)
	local node = xmlLoadFile(path)
	if(not node) then return false end
	
	local msgIdSet = {}
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local id = xmlNodeGetAttribute(subnode, "id")
		if(id) then
			msgIdSet[id] = true
		end
	end
	
	xmlUnloadFile(node)
	return msgIdSet
end

local function checkLangFile(path, msgIdSet, opt)
	local node = xmlLoadFile(path)
	if(not node) then return false end
	
	local cnt = 0
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local id = xmlNodeGetAttribute(subnode, "id")
		if(not msgIdSet[id]) then
			xmlDestroyNode(subnode)
			cnt = cnt + 1
			if(opt == "details") then
				scriptMsg("Out-dated message: %s", id)
			end
		end
	end
	
	if(opt == "fix") then
		xmlSaveFile(node)
	end
	xmlUnloadFile(node)
	
	return cnt
end

local function CmdCheckLang(message, arg)
	local lang, opt = arg[2], arg[3]
	if(lang) then
		local msgIdSetS = loadMsgIdSet("lang/pl.xml")
		local msgIdSetC = loadMsgIdSet("lang/pl_c.xml")
		if(msgIdSetS and msgIdSetC) then
			local countS = checkLangFile("lang/"..lang..".xml", msgIdSetS, opt)
			local countC = checkLangFile("lang/"..lang.."_c.xml", msgIdSetC, opt)
			scriptMsg("Out-dated lines: %u (server) + %u (client)", countS or 0, countC or 0)
		else
			outputDebugString("loadMsgIdSet failed", 2)
		end
	else
		scriptMsg("Usage: %s", arg[1].." <lang> [fix/details]")
	end
	
end

CmdRegister("checklang", CmdCheckLang, true)
