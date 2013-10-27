-- Includes
#include 'include/config.lua'

CmdMgr.register{
	name = 'pban',
	accessRight = AccessRight('command.banserial', true),
	args = {
		{'player', type = 'player'},
		{'reason', type = 'str'},
	},
	func = function(ctx, player, reason)
		local accountName = ctx.player:getAccountName()
		
		outputMsg(g_Root, Styles.red, "%s serial has been banned by %s!", player:getName(true), ctx.player:getName(true))
		local banInfo = '(nick: '..player:getName()..') (by: '..accountName..')'..reason
		addBan(nil, nil, player:getSerial(), ctx.player.el, banInfo)
	end
}

CmdMgr.register{
	name = 'ban1m',
	desc = "Bans player for 1 minute",
	accessRight = AccessRight('ban1m'),
	args = {
		{'player', type = 'player'},
		{'reason', type = 'str'},
	},
	func = function(ctx, player, reason)
		local accountName = ctx.player:getAccountName()
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (1 minute)!", player:getName(true), ctx.player:getName(true))
		addBan(nil, nil, player:getSerial(), ctx.player.el, '(nick: '..player:getName()..') (by: '..accountName..')'..reason, 60)
	end
}

CmdMgr.register{
	name = 'ban5m',
	desc = "Bans player for 5 minutes",
	accessRight = AccessRight('ban5m'),
	args = {
		{'player', type = 'player'},
		{'reason', type = 'str'},
	},
	func = function(ctx, player, reason)
		local accountName = ctx.player:getAccountName()
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (5 minutes)!", player:getName(true), ctx.player:getName(true))
		addBan(nil, nil, player:getSerial(), ctx.player.el, '(nick: '..player:getName()..') (by: '..accountName..')'..reason, 60*5)
	end
}

CmdMgr.register{
	name = 'ban1h',
	desc = "Bans player for 1 hour",
	accessRight = AccessRight('ban1h'),
	args = {
		{'player', type = 'player'},
		{'reason', type = 'str'},
	},
	func = function(ctx, player, reason)
		local accountName = ctx.player:getAccountName()
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (1 hour)!", player:getName(true), ctx.player:getName(true))
		addBan(nil, nil, player:getSerial(), ctx.player.el, '(nick: '..player:getName()..') (by: '..accountName..')'..reason, 3600)
	end
}

CmdMgr.register{
	name = 'ban24h',
	desc = "Bans player for 24 hours",
	accessRight = AccessRight('ban24h'),
	args = {
		{'player', type = 'player'},
		{'reason', type = 'str'},
	},
	func = function(ctx, player, reason)
		local accountName = ctx.player:getAccountName()
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (24 hours)!", player:getName(true), ctx.player:getName(true))
		addBan(nil, nil, player:getSerial(), ctx.player.el, '(nick: '..player:getName()..') (by: '..accountName..')'..reason, 3600*24)
	end
}

CmdMgr.register{
	name = 'ban7d',
	desc = "Bans player for 7 days",
	accessRight = AccessRight('ban7d'),
	args = {
		{'player', type = 'player'},
		{'reason', type = 'str'},
	},
	func = function(ctx, player, reason)
		local accountName = ctx.player:getAccountName()
		
		outputMsg(g_Root, Styles.red, "%s has been banned by %s (7 days)!", player:getName(true), ctx.player:getName(true))
		addBan(nil, nil, player:getSerial(), ctx.player.el, '(nick: '..player:getName()..') (by: '..accountName..')'..reason, 3600*24*7)
	end
}

CmdMgr.register{
	name = 'mute',
	desc = "Mutes player on chat and voice-chat for 1 minute",
	accessRight = AccessRight('command.mute', true),
	args = {
		{'player', type = 'player'},
		{'reason', type = 'str'},
		{'seconds', type = 'int', defVal = 60, min = 5},
	},
	func = function(ctx, player, reason, sec)
		if(sec > 3600 and not AccessRight('pmute'):check(ctx.player)) then
			privMsg(ctx.player, "Access denied! You can mute up to 1 hour.")
			return
		end
		
		local reason = 'Muted by '..ctx.player:getAccountName()..': '..reason
		if(player:mute(sec, reason)) then
			outputMsg(g_Root, Styles.red, "%s has been muted by %s (%u seconds)!", player:getName(true), ctx.player:getName(true), sec)
		end
	end
}

CmdMgr.register{
	name = 'pmute',
	desc = "Mutes player for ever",
	accessRight = AccessRight('pmute'),
	args = {
		{'player', type = 'player'},
		{'reason', type = 'str'},
	},
	func = function(ctx, player, reason, sec)
		local reason = 'Muted by '..ctx.player:getAccountName()..': '..reason
		if(player:mute(0, reason)) then
			outputMsg(g_Root, Styles.red, "%s has been permanently muted by %s!", player:getName(true), ctx.player:getName(true))
		end
	end
}

CmdMgr.register{
	name = 'unmute',
	desc = "Unmutes player on chat and voice-chat",
	accessRight = AccessRight('command.unmute', true),
	args = {
		{'player', type = 'player'},
	},
	func = function(ctx, player)
		if(isPlayerMuted(player.el)) then
			outputMsg(g_Root, Styles.green, "%s has been unmuted by %s!", player:getName(true), ctx.player:getName(true))
		end
		player:unmute()
	end
}

CmdMgr.register{
	name = 'killplayer',
	desc = "Kills specified player",
	accessRight = AccessRight('command.slap', true),
	args = {
		{'player', type = 'player'},
	},
	func = function(ctx, player)
		killPed(player.el)
	end
}

CmdMgr.register{
	name = 'ip',
	desc = "Shows player IP address",
	accessRight = AccessRight('ip'),
	args = {
		{'player', type = 'player'},
	},
	func = function(ctx, player)
		local ip = player:getIP()
		scriptMsg("%s's IP: %s.", player:getName(), ip or "unknown")
	end
}

CmdMgr.register{
	name = 'account',
	desc = "Shows player account ID",
	args = {
		{'player', type = 'player'},
	},
	func = function(ctx, player)
		scriptMsg("%s's account ID: %s.", player:getName(), player.id or "none")
	end
}

CmdMgr.register{
	name = 'findaccountsip',
	aliases = {'findaccip'},
	accessRight = AccessRight('findaccounts'),
	args = {
		{'IP', type = 'str'},
	},
	func = function(ctx, ip)
		local buf = ''
		local rows = DbQuery('SELECT player FROM '..PlayersTable..' WHERE ip LIKE ?', ip..'%')
		local found = {}
		
		for i, data in ipairs(rows) do
			table.insert(found, data.player)
		end
		local foundStr = #found > 0 and table.concat(found, ', ') or "none"
		scriptMsg("Found accounts: %s", foundStr)
	end
}

CmdMgr.register{
	name = 'describeaccount',
	aliases = {'descra'},
	accessRight = AccessRight('findaccounts'),
	args = {
		{'AccountID', type = 'int'},
	},
	func = function(ctx, id)
		local accountData = AccountData.create(id)
		local data = accountData:getTbl()
		if(not data) then
			privMsg(ctx.player, "Account has not been found!")
			return
		end
		
		local tm = getRealTime(data.last_visit)
		local tm2 = getRealTime(data.first_visit)
		scriptMsg("Name: %s, points: %s, cash: %u, bid-level: %u, playtime: %u, last visit: %d-%02d-%02d %d:%02d:%02d, joined: %d-%02d-%02d %d:%02d:%02d, IP: %s, serial: %s.",
			data.name, data.points, data.cash, data.bidlvl, data.time_here,
			tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute, tm.second,
			tm2.monthday, tm2.month + 1, tm2.year + 1900, tm2.hour, tm2.minute, tm2.second,
			data.ip, data.serial)
	end
}

CmdMgr.register{
	name = 'mergeaccounts',
	aliases = {'mergeacc'},
	accessRight = AccessRight('mergeaccounts'),
	args = {
		{'Player', type = 'player'},
		{'OtherAccountID', type = 'int', min = 0},
	},
	func = function(ctx, player, id)
		if(not player.id) then
			privMsg(ctx.player, "Player %s is not logged in!", player:getName())
			return
		end
		
		if(player.id == id) then
			privMsg(ctx.player, "Cannot merge account with the same account!", id)
			return
		end
		
		-- get statistics for id
		local srcAccountData = AccountData.create(id)
		local src_data = srcAccountData:getTbl()
		if(not src_data) then
			privMsg(ctx.player, "Cannot find account %u!", id)
			return
		end
		
		--[[if(src_data.first_visit > player.accountData.first_visit) then
			privMsg(ctx.player, "Account for merge is newer")
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
#if(DM_STATS) then
		newData.huntersTaken = player.accountData.huntersTaken + src_data.huntersTaken
		newData.dmVictories = player.accountData.dmVictories + src_data.dmVictories
		newData.dmPlayed = player.accountData.dmPlayed + src_data.dmPlayed
#end
#if(DD_STATS) then
		newData.ddVictories = player.accountData.ddVictories + src_data.ddVictories
		newData.ddPlayed = player.accountData.ddPlayed + src_data.ddPlayed
#end
#if(RACE_STATS) then
		newData.raceVictories = player.accountData.raceVictories + src_data.raceVictories
		newData.racesFinished = player.accountData.racesFinished + src_data.racesFinished
		newData.racesPlayed = player.accountData.racesPlayed + src_data.racesPlayed
#end
		
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
		if(BestTimesTable) then
			local rows = DbQuery('SELECT bt1.map, bt1.time AS time1, bt2.time AS time2 FROM '..BestTimesTable..' bt1, '..BestTimesTable..' bt2 WHERE bt1.player=? AND bt2.player=? AND bt1.map=bt2.map', player.id, id)
			local mapsSrc, mapsDst = {}, {}
			local questionMarksSrc, questionMarksDst = {}, {}
			newData.toptimes_count = player.accountData.toptimes_count + src_data.toptimes_count
			
			for i, data in ipairs(rows) do
				local delTime = math.max(data.time1, data.time2)
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
				BtDeleteTimes('player=? AND map IN ('..questionMarksStr..')', player.id, unpack(mapsDst)) -- remove duplicates
			end
			if(#mapsSrc > 0) then
				local questionMarksStr = table.concat(questionMarksSrc, ',')
				BtDeleteTimes('player=? AND map IN ('..questionMarksStr..')', id, unpack(mapsSrc)) -- remove duplicates
			end
			DbQuery('UPDATE '..BestTimesTable..' SET player=? WHERE player=?', player.id, id) -- set new best times owner
		end
		
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
	end
}

CmdMgr.register{
	name = 'delaccount',
	aliases = {'delacc'},
	desc = "Deletes player account",
	accessRight = AccessRight('resetstats'),
	args = {
		{'AccountID', type = 'int'},
	},
	func = function(ctx, playerId)
		if(Player.fromId(playerId)) then -- Note: fromId returns only online
			scriptMsg("You cannot remove online players")
			return
		end
		
		DbQuery('DELETE FROM '..NamesTable..' WHERE player=?', playerId)
		DbQuery('DELETE FROM '..RatesTable..' WHERE player=?', playerId) -- FIXME: maps.rates
		if(BtDeleteTimes) then
			BtDeleteTimes('player=?', playerId)
		end
		DbQuery('DELETE FROM '..ProfilesTable..' WHERE player=?', playerId)
		DbQuery('DELETE FROM '..PlayersTable..' WHERE player=?', playerId)
		
		scriptMsg("Account %u has been deleted!", playerId)
	end
}

CmdMgr.register{
	name = 'sqlquery',
	desc = "Executes SQL query in script database",
	accessRight = AccessRight('sqlquery'),
	args = {
		{'query', type = 'str'},
	},
	func = function(ctx, query)
		local rows = DbQuerySync(query)
		if(type(rows) == 'table') then
			privMsg(ctx.player, "SQL query succeeded (%u rows)", #rows)
			for i, data in ipairs(rows) do
				local tbl = {}
				for k, v in pairs(data) do
					table.insert(tbl, tostring(k)..'='..tostring(v))
				end
				local buf = i..'. '..table.concat(tbl, ', ')
				privMsg(ctx.player, buf:sub(1, 512))
				if(i > 10) then break end
			end
		elseif(rows) then
			privMsg(ctx.player, "SQL query succeeded: ", tostring(rows))
		else
			privMsg(ctx.player, "SQL query failed")
		end
	end
}
