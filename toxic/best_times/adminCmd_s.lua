g_RemTopTimeLogger = Logger('remtoptime')

CmdMgr.register{
	name = 'remtoptime',
	desc = "Removes specified Top Time on the current map",
	accessRight = AccessRight('remtoptime'),
	args = {
		{'toptimeNumber', type = 'int', min = 1, max = 8},
	},
	func = function(ctx, num)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		if(not map) then
			privMsg(ctx.player, "No map is running now!")
			return
		end
		
		local map_id = map:getId()
		local rows = DbQuery(
			'SELECT player, time '..
			'FROM '..DbPrefix..'besttimes '..
			'WHERE map=? '..
			'ORDER BY time '..
			'LIMIT '..math.max(num, 4), map_id)
		if(not rows or not rows[num]) then
			privMsg(ctx.player, "There are only %u Top Times saved!", rows and #rows or 0)
			return
		end
		
		BtDeleteTimes(map_id, rows[num].player)
		local accountData = AccountData.create(rows[num].player)
		if(num <= 3) then
			accountData:add('toptimes_count', -1)
			if(rows[4]) then
				AccountData.create(rows[4].player):add('toptimes_count', 1)
			end
		end
		MiUpdateTops(map_id)
		
		local nextTops = ''
		for i = num + 1, math.min(num+3, #rows), 1 do
			nextTops = nextTops..', '..formatTimePeriod(rows[i].time / 1000)
		end
		
		local logStr = ctx.player:getName()..' removed '..num..'. toptime ('..formatTimePeriod(rows[num].time / 1000)..
			' by '..accountData:get('name')..') on map '..map:getName()..'.'..
			(nextTops ~= '' and ' Next Top Times: '..nextTops:sub(3)..'.' or '')
		outputServerLog('REMTOPTIME: '..logStr)
		g_RemTopTimeLogger:print(logStr)
		
		outputMsg(room.el, Styles.red, "%u. Top Time (%s by %s) has been removed by %s!",
			num, formatTimePeriod(rows[num].time / 1000), accountData:get('name'), ctx.player:getName(true))
	end
}
