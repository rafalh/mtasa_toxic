CmdMgr.register{
	name = 'besttime',
	desc = "Shows player best time on current map",
	args = {
		{'player', type = 'player', defValFromCtx = 'player'},
	},
	func = function(ctx, player)
		local map = getCurrentMap(player.room)
		local rows = player.id and DbQuery('SELECT time FROM '..BestTimesTable..' WHERE player=? AND map=? LIMIT 1', player.id, map:getId())
		
		local bestTimeStr = rows and rows[1] and formatTimePeriod(rows[1].time / 1000)
		scriptMsg("%s's personal best time: %s.", player:getName(), bestTimeStr or 'none')
	end
}

function BtPrintTopTimes()
	local room = Player.fromEl(source).room
	local map_id = getCurrentMap(room):getId()
	local rows = DbQuery(
		'SELECT bt.player, bt.time, p.name '..
		'FROM '..BestTimesTable..' bt '..
		'INNER JOIN '..PlayersTable..' p ON bt.player=p.player '..
		'WHERE map=? ORDER BY time LIMIT 3', map_id)
	
	if (rows and #rows > 0) then
		scriptMsg("Top Times:")
		for i, data in ipairs(rows) do
			scriptMsg("%u. %s - %s", i, data.name, formatTimePeriod(data.time/1000))
		end
	else
		scriptMsg("No top times saved!")
	end
end
