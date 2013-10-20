CmdMgr.register{
	name = 'rate',
	desc = "Rates current map",
	args = {
		{'rating', type = 'int', min = 1, max = 5},
	},
	func = function(ctx, rate)
		source = ctx.player.el -- FIXME
		RtPlayerRate(rate)
	end
}

CmdMgr.register{
	name = 'rating',
	desc = "Checks current map rating",
	func = function(ctx)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		if(map) then
			local rows = DbQuery('SELECT rates/2, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
			local rating = 0
			if(rows[1].rates_count > 0) then
				rating = rows[1].rates / rows[1].rates_count
			end
			
			scriptMsg("Map rating: %.2f (rated by %u players).", rating, rows[1].rates_count)
		end
	end
}
