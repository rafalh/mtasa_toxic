-- Includes
#include 'include/config.lua'

---------------------
-- Local variables --
---------------------

local db_tops = {
	cash = { "Top Cash", 'cash', formatMoney },
	points = { "Top Points", 'points', function (n) return formatNumber (n) end },
	playtime = { "Top Playtime", 'time_here', function (n) return formatTimePeriod (n, 0) end },
	bidlevel = { "Top Bid-level", 'bidlvl', function (n) return n end }
}
local local_tops = {
	lagger = { "Top Laggers", getPlayerPing, function (n) return formatNumber (n)..' ms' end },
	fps_lagger = { "Top FPS Laggers", function (player) return -(tonumber (getElementData (player, 'fps')) or 0) end, function (n) return formatNumber (-n)..' FPS' end }
}

----------------------------------
-- Global functions definitions --
----------------------------------

CmdMgr.register{
	name = 'top',
	desc = "Shows top of given type",
	args = {
		{'type', type = 'string', def = false},
	},
	func = function(ctx, topType)
		topType = topType and topType:lower()
		
		if(db_tops[topType]) then
			local field = db_tops[topType][2]
			scriptMsg(db_tops[topType][1]..':')
			rows = DbQuery('SELECT name, '..field..' FROM '..PlayersTable..' WHERE online=1 AND serial<>\'0\' ORDER BY '..field..' DESC LIMIT 3')
			for i, data in ipairs (rows) do
				if (db_tops[topType][3]) then
					data[field] = db_tops[topType][3] (data[field])
				end
				scriptMsg(i..'. '..data.name..' - '..data[field])
			end
		elseif(local_tops[topType]) then
			scriptMsg(local_tops[topType][1]..':')
			local top = {}
			for player, pdata in pairs (g_Players) do
				if(not pdata.is_console) then
					local n = local_tops[topType][2](player)
					
					table.insert(top, { player, n })
				end
			end
			
			table.sort(top, function (row1, row2) return row1[2] > row2[2] end)
			
			for i, toprow in ipairs(top) do
				if(i > 3) then break end
				
				if(local_tops[topType][3]) then
					toprow[2] = local_tops[topType][3] (toprow[2])
				end
				
				local name = getPlayerName(toprow[1])
				scriptMsg('%u. %s - %s', i, name, toprow[2])
			end
		elseif(topType == 'times') then
			BtPrintTopTimes ()
		else
			privMsg(ctx.player, "Supported types: %s.", 'lagger, fps_lagger, cash, points, playtime, bidlevel, times')
		end
	end
}

CmdMgr.register{
	name = 'gtop',
	desc = "Shows global top of given type",
	args = {
		{'type', type = 'string', def = false},
	},
	func = function(ctx, topType)
		topType = topType and topType:lower()
	
		if (db_tops[topType]) then
			local field = db_tops[topType][2]
			scriptMsg ('Global '..db_tops[topType][1]..':')
			rows = DbQuery ('SELECT name, '..field..' FROM '..PlayersTable..' WHERE serial<>\'0\' ORDER BY '..field..' DESC LIMIT 3')
			for i, data in ipairs (rows) do
				if (db_tops[topType][3]) then
					data[field] = db_tops[topType][3] (data[field])
				end
				scriptMsg(i..'. '..data.name..' - '..data[field])
			end
		else
			privMsg(ctx.player, "Supported types: %s.", 'cash, points, playtime, bidlevel.')
		end
	end
}

CmdMgr.register{
	name = 'cash',
	desc = "Shows player cash and bid-level",
	aliases = {'money'},
	args = {
		{'player', type = 'player', def = false},
	},
	func = function(ctx, player)
		if(not player) then player = ctx.player end
		scriptMsg("%s's cash: %s - Bid-level: %u.", player:getName(), formatMoney(player.accountData.cash), player.accountData.bidlvl)
	end
}

CmdMgr.register{
	name = 'points',
	desc = "Shows player points count",
	aliases = {'pts', 'exp'},
	args = {
		{'player', type = 'player', def = false},
	},
	func = function(ctx, player)
		if(not player) then player = ctx.player end
		scriptMsg("%s's points: %s.", player:getName(), formatNumber(player.accountData.points))
	end
}

CmdMgr.register{
	name = 'rank',
	desc = "Shows player rank title",
	args = {
		{'player', type = 'player', def = false},
	},
	func = function(ctx, player)
		if(not player) then player = ctx.player end
		scriptMsg("%s's rank: %s.", player:getName(), StRankFromPoints(player.accountData.points))
	end
}

CmdMgr.register{
	name = 'bidlevel',
	desc = "Displays player bid-level",
	args = {
		{'player', type = 'player', def = false},
	},
	func = function(ctx, player)
		if(not player) then player = ctx.player end
		scriptMsg("%s's bid-level: %u.", player:getName(), player.accountData.bidlvl)
	end
}

CmdMgr.register{
	name = 'givemoney',
	desc = "Transfers money to other player",
	aliases = {'givecash', 'transfer'},
	args = {
		{'player', type = 'player'},
		{'cash', type = 'integer', min = 1},
	},
	func = function(ctx, recipient, amount)
		if(ctx.player.accountData.cash >= amount) then
			ctx.player.accountData:add('cash', -amount)
			recipient.accountData:add('cash', amount)
			
			privMsg(ctx.player, "%s gave %s %s.", ctx.player:getName(), recipient:getName(), formatMoney(amount))
			privMsg(recipient, "You received %s from %s.", formatMoney(amount), ctx.player:getName())
		else
			privMsg(ctx.player, "You do not have enough cash!")
		end
	end
}

CmdMgr.register{
	name = 'seen',
	desc = "Shows when player joined the game",
	args = {
		{'player', type = 'player', def = false},
	},
	func = function(ctx, player)
		if(not player) then player = ctx.player end
		local tm = getRealTime(player.join_time)
		scriptMsg("%s seen since %d:%02u:%02u.", player:getName(), tm.hour, tm.minute, tm.second)
	end
}

CmdMgr.register{
	name = 'playtime',
	desc = "Shows time player spent in game",
	aliases = {'timehere'},
	args = {
		{'player', type = 'player', def = false},
	},
	func = function(ctx, player)
		if(not player) then player = ctx.player end
		local playTime = player:getPlayTime()
		scriptMsg("%s's time here: %s.", player:getName(), formatTimePeriod(playTime, 0))
	end
}

CmdMgr.register{
	name = 'stats',
	desc = "Shows player statistics",
	aliases = {'stat', 'st'},
	args = {
		{'player', type = 'player', def = false},
	},
	func = function(ctx, player)
		if(not player) then player = ctx.player end
		
		local stats = player.accountData:getTbl()
		
		scriptMsg("%s's statistics:", player:getName())
#if(TOP_TIMES) then
		scriptMsg("Points: %s - Maps played: %s - Top Times held: %s - Win Streak: %s",
			formatNumber(stats.points), formatNumber(stats.mapsPlayed), formatNumber(stats.toptimes_count), formatNumber(stats.maxWinStreak))
#else
		scriptMsg("Points: %s - Maps played: %s - Win Streak: %s",
			formatNumber(stats.points), formatNumber(stats.mapsPlayed), formatNumber(stats.maxWinStreak))
#end
#if(DM_STATS) then
		local dmRatio = stats.dmVictories/math.max(stats.dmPlayed, 1)
		local huntRatio = stats.huntersTaken/math.max(stats.dmPlayed, 1)
		--scriptMsg("DM Victories: %s / %s (%.2f%%)", formatNumber(stats.dmVictories), formatNumber(stats.dmPlayed), dmRatio*100)
		scriptMsg("DM Hunters: %s / %s (%.2f%%)", formatNumber(stats.huntersTaken), formatNumber(stats.dmPlayed), huntRatio*100)
#end
#if(DD_STATS) then
		local ddRatio = stats.ddVictories/math.max(stats.ddPlayed, 1)
		scriptMsg("DD Victories: %s / %s (%.2f%%)", formatNumber(stats.ddVictories), formatNumber(stats.ddPlayed), ddRatio*100)
#end
#if(RACE_STATS) then
		local raceRatio = stats.raceVictories/math.max(stats.racesPlayed, 1)
		scriptMsg("Race Victories: %s / %s (%.2f%%)", formatNumber(stats.raceVictories), formatNumber(stats.racesPlayed), raceRatio*100)
#end
	end
}
