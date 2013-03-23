local function CmdRate(message, arg)
	local rate = touint(arg[2], 0)
	
	if(rate >= 1 and rate <= 10) then
		RtPlayerRate(rate)
	else
		privMsg(source, "Usage: %s", arg[1].." <1-5>")
	end
end

CmdRegister("rate", CmdRate, false, "Rates current map")

local function CmdRating(message, arg)
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	
	if(map) then
		local map_id = map:getId()
		local map_name = map:getName()
		local rows = DbQuery("SELECT rates, rates_count FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
		local rating = 0
		if(rows[1].rates_count > 0) then
			rating = rows[1].rates / rows[1].rates_count
		end
		
		scriptMsg("Map rating: %.2f (rated by %u players).", rating, rows[1].rates_count)
	end
end

CmdRegister("rating", CmdRating, false, "Checks current map rating")