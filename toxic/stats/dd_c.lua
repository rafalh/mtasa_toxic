local g_LastCol = false

local function onPlayerQuit(reason)
	g_LastCol[source] = nil
end

local function onVehCol(hitElement)
	if(source ~= getPedOccupiedVehicle(localPlayer)) then return end
	
	local hitPlayer = hitElement and getElementType(hitElement) == "vehicle" and getVehicleOccupant(hitElement)
	if(not hitPlayer) then return end
	
	g_LastCol[hitPlayer] = getTickCount()
end

local function onMyselfWasted()
	local ticks = getTickCount()
	
	local killersSorted = {}
	for player, colTicks in pairs(g_LastCol) do
		if(ticks - colTicks < 15000) then
			table.insert(killersSorted, player)
		end
	end
	
	table.sort(killersSorted, function(pl1, pl2) return g_LastCol[pl1] > g_LastCol[pl2] end)
	
	if(#killersSorted > 0) then
		local killerTicks = g_LastCol[killersSorted[1]]
		local killerPlayer = killersSorted[1]
		local assistTicks = killersSorted[2] and g_LastCol[killersSorted[2]]
		assert(not assistTicks or killerTicks > assistTicks) -- Note: killersSorted[1] is last killer
		local assistPlayer = assistTicks and (killerTicks - assistTicks < 2000) and killersSorted[2]
		
		outputDebugString("Killer "..getPlayerName(killersSorted[1]).." assist "..(assistPlayer and getPlayerName(assistPlayer) or "no"), 3)
		triggerServerEvent('stats.onDDKillersList', resourceRoot, killerPlayer, assistPlayer)
	end
	
	g_LastCol = {}
end

function DDSetKillersDetectionEnabled(enabled)
	local curEnabled = g_LastCol and true
	if(curEnabled == enabled) then return end
	--outputDebugString('DD killers detection: '..tostring(enabled), 3)
	
	if(enabled) then
		addEventHandler("onClientPlayerQuit", g_Root, onPlayerQuit)
		addEventHandler("onClientVehicleCollision", g_Root, onVehCol)
		addEventHandler("onClientPlayerWasted", g_Me, onMyselfWasted)
		g_LastCol = {}
	else
		removeEventHandler("onClientPlayerQuit", g_Root, onPlayerQuit)
		removeEventHandler("onClientVehicleCollision", g_Root, onVehCol)
		removeEventHandler("onClientPlayerWasted", g_Me, onMyselfWasted)
		g_LastCol = false
	end
end
