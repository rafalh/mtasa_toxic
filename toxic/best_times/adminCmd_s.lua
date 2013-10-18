CmdMgr.register{
	name = 'remtoptime',
	desc = "Removes specified Top Time on the current map",
	accessRight = AccessRight('remtoptime'),
	args = {
		{'toptimeNumber', type = 'integer', min = 1, max = 8},
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
			'LIMIT '..math.max(n, 4), map_id)
		if(not rows or not rows[n]) then
			privMsg(ctx.player, "There are only %u Top Times saved!", rows and #rows or 0)
			return
		end
		
		BtDeleteTimes('WHERE player=? AND map=?', rows[n].player, map_id)
		local accountData = AccountData.create(rows[n].player)
		if(n <= 3) then
			accountData:add('toptimes_count', -1)
			if(rows[4]) then
				AccountData.create(rows[4].player):add('toptimes_count', 1)
			end
		end
		MiUpdateTops(map_id)
		
		local nextTops = ''
		for i = n + 1, math.min (n+3, #rows), 1 do
			nextTops = nextTops..', '..formatTimePeriod(rows[i].time / 1000)
		end
		
		local logStr = ctx.player:getName()..' removed '..n..'. toptime ('..formatTimePeriod(rows[n].time / 1000)..
			' by '..accountData:get('name')..') on map '..map:getName()..'.'..
			(nextTops ~= '' and ' Next Top Times: '..nextTops:sub(3)..'.' or '')
		outputServerLog('REMTOPTIME: '..logStr)
		
		local f = fileExists('logs/remtoptime.log') and fileOpen('logs/remtoptime.log') or fileCreate('logs/remtoptime.log')
		if(f) then
			fileSetPos(f, fileGetSize(f)) -- append to file
			
			local tm = getRealTime()
			local timeStr = ('[%u.%02u.%u %u-%02u-%02u]'):format(tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute, tm.second)
			fileWrite(f, timeStr..' '..logStr..'\n')
			
			fileClose(f)
		end
		
		outputMsg(room.el, Styles.red, "%u. Top Time (%s by %s) has been removed by %s!",
			n, formatTimePeriod(rows[n].time / 1000), accountData:get('name'), ctx.player:getName(true))
	end
}
