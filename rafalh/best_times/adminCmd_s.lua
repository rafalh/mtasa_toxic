local function CmdRemTopTime(message, arg)
	local room = Player.fromEl(source).room
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
