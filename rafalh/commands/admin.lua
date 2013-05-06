---------------------------------
-- Global function definitions --
---------------------------------

local function CmdPBan(message, arg)
	local playerEl = (#arg >= 2 and findPlayer(arg[2]))
	local reason = arg[3]
	
	if(playerEl) then
		local accountName = getAccountName(getPlayerAccount (source))
		local player = Player.fromEl(playerEl)
		local admin = Player.fromEl(source)
		
		outputMsg(g_Root, Styles.red, "%s serial has been banned by %s!", player:getName(true), admin:getName(true))
		local banInfo = "(nick: "..player:getName()..") (by: "..accountName..")"..(reason and " "..reason or "")
		addBan(nil, nil, getPlayerSerial(playerEl), source, banInfo)
	else
		privMsg(source, "Usage: %s", arg[1].." <player>")
	end
end

CmdRegister("pban", CmdPBan, "command.banserial")

local function CmdBan1m(message, arg)
	local playerEl = (#arg >= 2 and findPlayer(arg[2]))
	local reason = arg[3]
	
	if(playerEl) then
		local accountName = getAccountName(getPlayerAccount(source))
		local player = Player.fromEl(playerEl)
		local admin = Player.fromEl(source)
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (1 minute)!", player:getName(true), admin:getName(true))
		addBan (nil, nil, getPlayerSerial(playerEl), source, "(nick: "..player:getName()..") (by: "..accountName..")"..(reason and " "..reason or ""), 60)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("ban1m", CmdBan1m, "resource."..g_ResName..".ban1m", "Bans player for 1 minute")

local function CmdBan5m(message, arg)
	local playerEl = (#arg >= 2 and findPlayer(arg[2]))
	local reason = arg[3]
	
	if(playerEl) then
		local accountName = getAccountName(getPlayerAccount(source))
		local player = Player.fromEl(playerEl)
		local admin = Player.fromEl(source)
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (5 minutes)!", player:getName(true), admin:getName(true))
		addBan (nil, nil, getPlayerSerial(playerEl), source, "(nick: "..player:getName()..") (by: "..accountName..")"..(reason and " "..reason or ""), 60*5)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("ban5m", CmdBan5m, "resource."..g_ResName..".ban5m", "Bans player for 5 minutes")

local function CmdBan1h(message, arg)
	local playerEl = (#arg >= 2 and findPlayer(arg[2]))
	local reason = arg[3]
	
	if(playerEl) then
		local accountName = getAccountName(getPlayerAccount(source))
		local player = Player.fromEl(playerEl)
		local admin = Player.fromEl(source)
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (1 hour)!", player:getName(true), admin:getName(true))
		addBan (nil, nil, getPlayerSerial(playerEl), source, "(nick: "..player:getName()..") (by: "..accountName..")"..(reason and " "..reason or ""), 3600)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("ban1h", CmdBan1h, "resource."..g_ResName..".ban1h", "Bans player for 1 hour")

local function CmdBan24h (message, arg)
	local playerEl = (#arg >= 2 and findPlayer(arg[2]))
	local reason = arg[3]
	
	if(playerEl) then
		local accountName = getAccountName(getPlayerAccount(source))
		local player = Player.fromEl(playerEl)
		local admin = Player.fromEl(source)
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (24 hours)!", player:getName(true), admin:getName(true))
		addBan (nil, nil, getPlayerSerial(playerEl), source, "(nick: "..player:getName()..") (by: "..accountName..")"..(reason and " "..reason or ""), 24*3600)
	else privMsg (source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("ban24h", CmdBan24h, "resource."..g_ResName..".ban24h", "Bans player for 24 hours")

local function CmdMute(message, arg)
	local playerEl = (#arg >= 2 and findPlayer(message:sub(arg[1]:len() + 2)))
	local player = playerEl and Player.fromEl(playerEl)
	local admin = Player.fromEl(source)
	
	if(player) then
		mutePlayer(player, tonumber(arg[3]) or Settings.mute_time, admin)
	else privMsg(source, "Usage: %s", arg[1].." <player> [<time>]") end
end

CmdRegister("mute", CmdMute, "command.mute", "Mutes player on chat and voice-chat for 1 minute")

local function CmdPMute(message, arg)
	local playerEl = (#arg >= 2 and findPlayer(message:sub(arg[1]:len() + 2)))
	local player = playerEl and Player.fromEl(playerEl)
	local admin = Player.fromEl(source)
	
	if(player) then
		player.accountData:set("pmuted", 1)
		mutePlayer(player, false, admin)
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("pmute", CmdPMute, "resource."..g_ResName..".pmute", "Mutes player for ever")

local function CmdUnmute(message, arg)
	local playerEl = (#arg >= 2 and findPlayer(message:sub (arg[1]:len () + 2)))
	local player = playerEl and Player.fromEl(playerEl)
	local admin = Player.fromEl(source)
	
	if(player) then
		if(player.accountData.pmuted == 1) then
			player.accountData.pmuted = 0
			outputMsg(g_Root, Styles.green, "%s has been unpmuted by %s!", player:getName(true), admin:getName(true))
		elseif(isPlayerMuted(player.el)) then
			outputMsg(g_Root, Styles.green, "%s has been unmuted by %s!", player:getName(true), admin:getName(true))
		end
		
		setPlayerMuted(player.el, false)
		setPlayerVoiceMuted(player.el, false)
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("unmute", CmdUnmute, "command.unmute", "Unmutes player on chat and voice-chat")

local function CmdWarn(message, arg)
	local playerEl = (#arg >= 2 and findPlayer(message:sub (arg[1]:len () + 2)))
	local player = playerEl and Player.fromEl(playerEl)
	
	if(player) then
		local warns = player.accountData:get("warnings") + 1
		player.accountData:set("warnings", warns)
		local max_warns = Settings.max_warns
		if(max_warns > 0) then
			scriptMsg ("%s has been warned %u. time (limit: %u)!", player:getName(true), warns, max_warns)
		else
			scriptMsg ("%s has been warned %u. time!", player:getName(true), warns)
		end
		
		if(max_warns > 0 and warns > max_warns) then
			kickPlayer(player.el, source, warns.." warnings (limit: "..max_warns..")")
		end
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("warn", CmdWarn, "resource."..g_ResName..".warn", "Adds player warning and bans if he has too many")

local function CmdUnwarn (message, arg)
	local playerEl = (#arg >= 2 and findPlayer(message:sub (arg[1]:len () + 2)))
	local player = playerEl and Player.fromEl(playerEl)
	
	if (player) then
		local warns = player.accountData:get("warnings")
		if (warns > 0) then
			player.accountData:set("warnings", warns - 1)
		end
		scriptMsg("%s has been unwarned!", player:getName(true))
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("unwarn", CmdUnwarn, "resource."..g_ResName..".unwarn", "Removes player warning")

local function CmdKill (message, arg)
	local playerEl = (#arg >= 2 and findPlayer(message:sub (arg[1]:len () + 2))) or source
	
	if(playerEl == source or hasObjectPermissionTo(source, "command.slap", false)) then
		killPed(playerEl)
	else
		privMsg(source, "Access denied for \"%s\"!", arg[1])
	end
end

CmdRegister("kill", CmdKill, false, "Kills player", true)

local function CmdIp (message, arg)
	local player = (#arg >= 2 and findPlayer(message:sub (arg[1]:len () + 2))) or source
	local ip = getPlayerIP(player)
	if(ip) then
		scriptMsg("%s's IP: %s.", getPlayerName(player), ip)
	end
end

CmdRegister("ip", CmdIp, "resource."..g_ResName..".ip", "Shows player IP address")

local function CmdAccount(message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	local pdata = Player.fromEl(player)
	
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

CmdRegister("findaccountsip", CmdFindAccountsIp, "resource."..g_ResName..".findaccounts")
CmdRegisterAlias("findaccip", "findaccountsip")

local function CmdDescribeAccount(message, arg)
	local id = touint(arg[2])
	if(id) then
		local accountData = AccountData.create(id)
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

CmdRegister("describeaccount", CmdDescribeAccount, "resource."..g_ResName..".findaccounts")
CmdRegisterAlias ("descra", "describeaccount")

local function CmdMergeAccounts(message, arg)
	local player = findPlayer(arg[2])
	local pdata = Player.fromEl(player)
	local id = touint(arg[3])
	
	if(player and id and pdata.id) then
		if(pdata.id == id) then
			privMsg(source, "Cannot merge account with the same account!", id)
			return
		end
		
		-- get statistics for id
		local srcAccountData = AccountData.create(id)
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

CmdRegister("mergeaccounts", CmdMergeAccounts, "resource."..g_ResName..".mergeaccounts")
CmdRegisterAlias ("mergeacc", "mergeaccounts")

local function CmdDelAcc(message, arg)
	local playerId = touint(arg[2])
	if(playerId) then
		if(Player.fromId(playerId)) then -- Note: fromId returns only online
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

CmdRegister("delacc", CmdDelAcc, "resource."..g_ResName..".resetstats", "Deletes player account")

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
