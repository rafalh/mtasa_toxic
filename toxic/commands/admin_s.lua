local function CmdPBan(message, arg)
	local player = (#arg >= 2 and Player.find(arg[2]))
	local reason = arg[3]
	
	if(player) then
		local accountName = getAccountName(getPlayerAccount(source))
		local admin = Player.fromEl(source)
		
		outputMsg(g_Root, Styles.red, "%s serial has been banned by %s!", player:getName(true), admin:getName(true))
		local banInfo = '(nick: '..player:getName()..') (by: '..accountName..')'..(reason and ' '..reason or '')
		addBan(nil, nil, player:getSerial(), source, banInfo)
	else
		privMsg(source, "Usage: %s", arg[1]..' <player>')
	end
end

CmdRegister('pban', CmdPBan, 'command.banserial')

local function CmdBan1m(message, arg)
	local player = (#arg >= 2 and Player.find(arg[2]))
	local reason = arg[3]
	
	if(player) then
		local accountName = getAccountName(getPlayerAccount(source))
		local admin = Player.fromEl(source)
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (1 minute)!", player:getName(true), admin:getName(true))
		addBan(nil, nil, player:getSerial(), source, '(nick: '..player:getName()..') (by: '..accountName..')'..(reason and ' '..reason or ''), 60)
	else privMsg(source, "Usage: %s", arg[1]..' <player>') end
end

CmdRegister('ban1m', CmdBan1m, 'resource.'..g_ResName..'.ban1m', "Bans player for 1 minute")

local function CmdBan5m(message, arg)
	local player = (#arg >= 2 and Player.find(arg[2]))
	local reason = arg[3]
	
	if(player) then
		local accountName = getAccountName(getPlayerAccount(source))
		local admin = Player.fromEl(source)
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (5 minutes)!", player:getName(true), admin:getName(true))
		addBan(nil, nil, player:getSerial(), source, '(nick: '..player:getName()..') (by: '..accountName..')'..(reason and ' '..reason or ''), 60*5)
	else privMsg(source, "Usage: %s", arg[1]..' <player>') end
end

CmdRegister('ban5m', CmdBan5m, 'resource.'..g_ResName..'.ban5m', "Bans player for 5 minutes")

local function CmdBan1h(message, arg)
	local player = (#arg >= 2 and Player.find(arg[2]))
	local reason = arg[3]
	
	if(player) then
		local accountName = getAccountName(getPlayerAccount(source))
		local admin = Player.fromEl(source)
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (1 hour)!", player:getName(true), admin:getName(true))
		addBan(nil, nil, player:getSerial(), source, '(nick: '..player:getName()..') (by: '..accountName..')'..(reason and ' '..reason or ''), 3600)
	else privMsg(source, "Usage: %s", arg[1]..' <player>') end
end

CmdRegister('ban1h', CmdBan1h, 'resource.'..g_ResName..'.ban1h', "Bans player for 1 hour")

local function CmdBan24h(message, arg)
	local player = (#arg >= 2 and Player.find(arg[2]))
	local reason = arg[3]
	
	if(player) then
		local accountName = getAccountName(getPlayerAccount(source))
		local admin = Player.fromEl(source)
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (24 hours)!", player:getName(true), admin:getName(true))
		addBan(nil, nil, player:getSerial(), source, '(nick: '..player:getName()..') (by: '..accountName..')'..(reason and ' '..reason or ''), 24*3600)
	else privMsg(source, "Usage: %s", arg[1]..' <player>') end
end

CmdRegister('ban24h', CmdBan24h, 'resource.'..g_ResName..'.ban24h', "Bans player for 24 hours")

local function CmdMute(message, arg)
	local player = (#arg >= 2 and Player.find(arg[2]))
	local sec = touint(arg[3]) or Settings.mute_time
	local admin = Player.fromEl(source)
	if(player) then
		local reason = 'Muted by '..admin:getAccountName()
		if(player:mute(sec, reason)) then
			outputMsg(g_Root, Styles.red, "%s has been muted by %s!", player:getName(true), admin:getName(true))
		end
	else privMsg(source, "Usage: %s", arg[1]..' <player> [<time>]') end
end

CmdRegister('mute', CmdMute, 'command.mute', "Mutes player on chat and voice-chat for 1 minute")

local function CmdPMute(message, arg)
	local player = (#arg >= 2 and Player.find(message:sub(arg[1]:len() + 2)))
	local admin = Player.fromEl(source)
	
	if(player) then
		local reason = 'Muted by '..admin:getAccountName()
		if(player:mute(0, reason)) then
			outputMsg(g_Root, Styles.red, "%s has been permanently muted by %s!", player:getName(true), admin:getName(true))
		end
	else privMsg(source, "Usage: %s", arg[1]..' <player>') end
end

CmdRegister('pmute', CmdPMute, 'resource.'..g_ResName..'.pmute', "Mutes player for ever")

local function CmdUnmute(message, arg)
	local player = (#arg >= 2 and Player.find(message:sub(arg[1]:len() + 2)))
	local admin = Player.fromEl(source)
	
	if(player) then
		if(isPlayerMuted(player.el)) then
			outputMsg(g_Root, Styles.green, "%s has been unmuted by %s!", player:getName(true), admin:getName(true))
		end
		player:unmute()
	else privMsg(source, "Usage: %s", arg[1]..' <player>') end
end

CmdRegister('unmute', CmdUnmute, 'command.unmute', "Unmutes player on chat and voice-chat")

local function CmdKill(message, arg)
	local sourcePlayer = Player.fromEl(source)
	local player = (#arg >= 2 and Player.find(message:sub(arg[1]:len() + 2))) or sourcePlayer
	
	if(player == sourcePlayer or hasObjectPermissionTo(source, 'command.slap', false)) then
		killPed(player.el)
	else
		privMsg(source, "Access denied for \"%s\"!", arg[1])
	end
end

CmdRegister('kill', CmdKill, false, "Kills player", true)

local function CmdIp(message, arg)
	local player = (#arg >= 2 and Player.find(message:sub(arg[1]:len() + 2))) or Player.fromEl(source)
	local ip = player:getIP()
	if(ip) then
		scriptMsg("%s's IP: %s.", player:getName(), ip)
	end
end

CmdRegister('ip', CmdIp, 'resource.'..g_ResName..'.ip', "Shows player IP address")

local function CmdAccount(message, arg)
	local player = (#arg >= 2 and Player.find(message:sub(arg[1]:len() + 2))) or Player.fromEl(source)
	scriptMsg("%s's account ID: %s.", player:getName(), player.id or "none")
end

CmdRegister('account', CmdAccount, false, "Shows player account ID")

local function CmdFindAccountsIp(message, arg)
	if(#arg >= 2) then
		local buf = ''
		local rows = DbQuery('SELECT player FROM '..PlayersTable..' WHERE ip LIKE ?', arg[2]..'%')
		local found = {}
		
		for i, data in ipairs (rows) do
			table.insert(found, data.player)
		end
		local foundStr = #found > 0 and table.concat(found, ', ') or "none"
		scriptMsg("Found accounts: %s", foundStr)
	else privMsg(source, "Usage: %s", arg[1]..' <ip>') end
end

CmdRegister('findaccountsip', CmdFindAccountsIp, 'resource.'..g_ResName..'.findaccounts')
CmdRegisterAlias('findaccip', 'findaccountsip')

local function CmdDescribeAccount(message, arg)
	local id = touint(arg[2])
	if(id) then
		local accountData = AccountData.create(id)
		local data = accountData:getTbl()
		local tm = getRealTime(data.last_visit)
		local tm2 = getRealTime(data.first_visit)
		scriptMsg("Name: %s, points: %s, cash: %u, bid-level: %u, playtime: %u, last visit: %d-%02d-%02d %d:%02d:%02d, joined: %d-%02d-%02d %d:%02d:%02d, IP: %s, serial: %s.",
			data.name, data.points, data.cash, data.bidlvl, data.time_here,
			tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute, tm.second,
			tm2.monthday, tm2.month + 1, tm2.year + 1900, tm2.hour, tm2.minute, tm2.second,
			data.ip, data.serial)
	else privMsg(source, "Usage: %s", arg[1]..' <account ID>') end
end

CmdRegister('describeaccount', CmdDescribeAccount, 'resource.'..g_ResName..'.findaccounts')
CmdRegisterAlias ('descra', 'describeaccount')

local function CmdMergeAccounts(message, arg)
	local player = Player.find(arg[2])
	local id = touint(arg[3])
	
	if(player and player.id and id) then
		if(player.id == id) then
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
		
		--[[if(src_data.first_visit > player.accountData.first_visit) then
			privMsg(source, "Account for merge is newer")
			return
		end]]
		
		-- remove duplicated names
		local names = {}
		local questionMarks = {}
		local rows = DbQuery('SELECT n1.name FROM '..NamesTable..' n1, '..NamesTable..' n2 WHERE n1.player=? AND n2.player=? AND n1.name=n2.name', player.id, id)
		for i, data in ipairs(rows) do
			table.insert(names, data.name)
			table.insert(questionMarks, '?')
		end
		
		local questionMarksStr = table.concat(questionMarks, ',')
		DbQuery('DELETE FROM '..NamesTable..' WHERE player=? AND name IN ('..questionMarksStr..')', id, unpack(names)) -- remove duplicates
		DbQuery('UPDATE '..NamesTable..' SET player=? WHERE player=?', player.id, id) -- change all names owner
		
		-- update stats
		local newData = {}
		newData.cash = player.accountData.cash + src_data.cash
		newData.points = player.accountData.points + src_data.points
		newData.warnings = player.accountData.warnings + src_data.warnings
		newData.bidlvl = math.max(src_data.bidlvl, player.accountData.bidlvl)
		newData.time_here = player.accountData.time_here + src_data.time_here
		newData.first_visit = src_data.first_visit
		if(player.accountData.email == '') then
			newData.email = src_data.email
		end
		
		-- Statistics
		newData.exploded = player.accountData.exploded + src_data.exploded
		newData.drowned = player.accountData.drowned + src_data.drowned
		newData.maxWinStreak = math.max(player.accountData.maxWinStreak, src_data.maxWinStreak)
		newData.mapsPlayed = player.accountData.mapsPlayed + src_data.mapsPlayed
		newData.mapsBought = player.accountData.mapsBought + src_data.mapsBought
		-- mapsRated are set later
		newData.huntersTaken = player.accountData.huntersTaken + src_data.huntersTaken
		newData.dmVictories = player.accountData.dmVictories + src_data.dmVictories
		newData.ddVictories = player.accountData.ddVictories + src_data.ddVictories
		newData.raceVictories = player.accountData.raceVictories + src_data.raceVictories
		newData.racesFinished = player.accountData.racesFinished + src_data.racesFinished
		newData.dmPlayed = player.accountData.dmPlayed + src_data.dmPlayed
		newData.ddPlayed = player.accountData.ddPlayed + src_data.ddPlayed
		newData.racesPlayed = player.accountData.racesPlayed + src_data.racesPlayed
		
		-- Join Msg
		if(player.accountData.joinmsg == '' and src_data.joinmsg ~= '') then
			newData.joinmsg = src_data.joinmsg
		end
		
		-- Rates
		local rows = DbQuery('SELECT r1.map FROM '..RatesTable..' r1, '..RatesTable..' r2 WHERE r1.player=? AND r2.player=? AND r1.map=r2.map', player.id, id)
		local maps = {}
		local questionMarks = {}
		for i, data in ipairs(rows) do
			table.insert(maps, data.map)
			table.insert(questionMarks, '?')
		end
		if(#maps > 0) then
			local questionMarksStr = table.concat(questionMarks, ',')
			DbQuery('DELETE FROM '..RatesTable..' WHERE player=? AND map IN ('..questionMarksStr..')', id, unpack(maps)) -- remove duplicates
		end
		DbQuery('UPDATE '..RatesTable..' SET player=? WHERE player=?', player.id, id) -- set new rates owner
		local rows = DbQuery('SELECT COUNT(map) AS c FROM '..RatesTable..' WHERE player=?', player.id)
		newData.mapsRated = rows[1].c
		
		-- Best times
		local rows = DbQuery('SELECT bt1.map, bt1.time AS time1, bt2.time AS time2 FROM '..BestTimesTable..' bt1, '..BestTimesTable..' bt2 WHERE bt1.player=? AND bt2.player=? AND bt1.map=bt2.map', player.id, id)
		local mapsSrc, mapsDst = {}, {}
		local questionMarksSrc, questionMarksDst = {}, {}
		newData.toptimes_count = player.accountData.toptimes_count + src_data.toptimes_count
		
		for i, data in ipairs(rows) do
			local delTime = math.min(data.time1, data.time2)
			if(data.time1 > data.time2) then -- old besttime was better
				table.insert(mapsDst, data.map)
				table.insert(questionMarksDst, '?')
			else -- new besttime is better
				table.insert(mapsSrc, data.map)
				table.insert(questionMarksSrc, '?')
			end
			
			local rows = DbQuery('SELECT COUNT(player) AS pos FROM '..BestTimesTable..' WHERE map=? AND time<=?', data.map, delTime)
			if(rows[1].pos <= 3) then
				newData.toptimes_count = newData.toptimes_count - 1
			end
		end
		if(#mapsDst > 0) then
			local questionMarksStr = table.concat(questionMarksDst, ',')
			DbQuery('DELETE FROM '..BestTimesTable..' WHERE player=? AND map IN ('..questionMarksStr..')', player.id, unpack(mapsDst)) -- remove duplicates
		end
		if(#mapsSrc > 0) then
			local questionMarksStr = table.concat(questionMarksSrc, ',')
			DbQuery('DELETE FROM '..BestTimesTable..' WHERE player=? AND map IN ('..questionMarksStr..')', id, unpack(mapsSrc)) -- remove duplicates
		end
		DbQuery('UPDATE '..BestTimesTable..' SET player=? WHERE player=?', player.id, id) -- set new best times owner
		
		-- Profile fields
		local rows = DbQuery('SELECT p1.field FROM '..ProfilesTable..' p1, '..ProfilesTable..' p2 WHERE p1.player=? AND p2.player=? AND p1.field=p2.field', player.id, id)
		local fields = {}
		local questionMarks = {}
		for i, data in ipairs(rows) do
			table.insert(fields, data.field)
			table.insert(questionMarks, '?')
		end
		local questionMarksStr = table.concat(questionMarks, ',')
		DbQuery('DELETE FROM '..ProfilesTable..' WHERE player=? AND field IN ('..questionMarksStr..')', id, unpack(fields)) -- remove duplicates
		DbQuery('UPDATE '..ProfilesTable..' SET player=? WHERE player=?', player.id, id) -- set new profile fields owner
		
		-- Set new account data and delete old account
		player.accountData:set(newData, true)
		DbQuery('DELETE FROM '..PlayersTable..' WHERE player=?', id)
		AchvInvalidateCache(player.el)
		
		scriptMsg("Accounts has been merged. Old account has been removed...")
	else privMsg(source, "Usage: %s", arg[1]..' <player> <other account ID>') end
end

CmdRegister('mergeaccounts', CmdMergeAccounts, 'resource.'..g_ResName..'.mergeaccounts')
CmdRegisterAlias ('mergeacc', 'mergeaccounts')

local function CmdDelAcc(message, arg)
	local playerId = touint(arg[2])
	if(playerId) then
		if(Player.fromId(playerId)) then -- Note: fromId returns only online
			scriptMsg("You cannot remove online players")
			return
		end
		
		DbQuery('DELETE FROM '..NamesTable..' WHERE player=?', playerId)
		DbQuery('DELETE FROM '..RatesTable..' WHERE player=?', playerId)
		DbQuery('DELETE FROM '..BestTimesTable..' WHERE player=?', playerId)
		DbQuery('DELETE FROM '..ProfilesTable..' WHERE player=?', playerId)
		DbQuery('DELETE FROM '..PlayersTable..' WHERE player=?', playerId)
		
		scriptMsg("Account %u has been deleted!", playerId)
	else privMsg(source, "Usage: %s", arg[1]..' <account ID>') end
end

CmdRegister('delacc', CmdDelAcc, 'resource.'..g_ResName..'.resetstats', "Deletes player account")

local function CmdSqlQuery(message, arg)
	local query = #arg >= 2 and message:sub (arg[1]:len () + 2)
	if (query) then
		local rows = DbQuery(query)
		if(rows) then
			privMsg(source, "SQL query succeeded (%u rows)", #rows)
			for i, data in ipairs(rows) do
				local tbl = {}
				for k, v in pairs(data) do
					table.insert(tbl, tostring(k)..'='..tostring(v))
				end
				local buf = i..'. '..table.concat(tbl, ', ')
				privMsg(source, buf:sub(1, 512))
				if(i > 10) then break end
			end
		else
			privMsg(source, "SQL query failed")
		end
	else privMsg(source, "Usage: %s", arg[1]..' <query>') end
end

CmdRegister('sqlquery', CmdSqlQuery, true)
