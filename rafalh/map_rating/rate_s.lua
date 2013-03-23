local g_Poll = false

addEvent("onPollStarting")
addEvent("onPlayerRate", true)
addEvent("onClientSetRateGuiVisibleReq", true)

function RtPlayerRate(rate)
	local pdata = g_Players[source]
	local room = pdata.room
	local map = getCurrentMap(room)
	
	rate = touint(rate, 0)
	if(rate < 1 or rate > 5 or not map or not pdata.id) then return end
	
	rate = rate * 2
	local map_id = map:getId()
	local rows = DbQuery("SELECT rates, rates_count FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
	local mapData = rows and rows[1]
	
	local rows = DbQuery("SELECT rate FROM rafalh_rates WHERE player=? AND map=? LIMIT 1", pdata.id, map_id)
	local oldRate = rows and rows[1] and rows[1].rate
	if(not oldRate or SmGetBool("allow_rate_change")) then
		if(oldRate) then
			assert(mapData.rates_count > 0 and mapData.rates > 0)
			mapData.rates = mapData.rates - oldRate + rate
			DbQuery("UPDATE rafalh_rates SET rate=? WHERE player=? AND map=?", rate, pdata.id, map_id)
		else
			mapData.rates_count = mapData.rates_count + 1
			mapData.rates = mapData.rates + rate
			DbQuery("INSERT INTO rafalh_rates (player, map, rate) VALUES(?, ?, ?)", pdata.id, map_id, rate)
			pdata.accountData:add("mapsRated", 1)
		end
		
		DbQuery("UPDATE rafalh_maps SET rates=?, rates_count=? WHERE map=?", mapData.rates, mapData.rates_count, map_id)
		privMsg(source, "Rate added! Current average rating: %.2f", mapData.rates / mapData.rates_count)
		
		BtSendMapInfo(false)
	else
		privMsg(source, "You rated this map before: %u!", oldRate)
	end
end

local function RtShowGuiForPlayer(player, map_id)
	local pdata = g_Players[player]
	if(not pdata.id) then return end
	
	local rows = DbQuery("SELECT rate FROM rafalh_rates WHERE player=? AND map=? LIMIT 1", pdata.id, map_id)
	if(not rows or not rows[1]) then
		triggerClientEvent(player, "onClientSetRateGuiVisibleReq", g_Root, true)
	end
end

local function RtTimerProc(room)
	local map = getCurrentMap(room)
	if(map and not g_Poll) then
		local map_id = map:getId()
		for player, pdata in pairs(g_Players) do
			RtShowGuiForPlayer(player, map_id)
		end
	end
end

local function RtMapStart()
	setMapTimer(RtTimerProc, 60 * 1000, 1, g_RootRoom) -- FIXME
	g_Poll = false
end

local function RtPoolStarting()
	--outputDebugString("RtPoolStarting", 3)
	triggerClientEvent(g_Root, "onClientSetRateGuiVisibleReq", g_Root, false)
	g_Poll = true
end

addInitFunc(function()
	addEventHandler("onGamemodeMapStart", g_Root, RtMapStart) -- FIXME
	addEventHandler("onPlayerRate", g_Root, RtPlayerRate)
	addEventHandler("onPollStarting", g_Root, RtPoolStarting)
end)
