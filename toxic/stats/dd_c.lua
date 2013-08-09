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

-- Used by RPC
function DdGetKillers()
	assert(g_LastCol)
	local ticks = getTickCount()
	
	local killersSorted = {}
	for player, colTicks in pairs(g_LastCol) do
		local dt = ticks - colTicks
		if(dt < 15000) then
			table.insert(killersSorted, player)
		end
	end
	
	table.sort(killersSorted, function(pl1, pl2) return g_LastCol[pl1] > g_LastCol[pl2] end)
	
	-- Note: killersSorted[1] is last killer
	local lastColTicks = #killersSorted > 0 and g_LastCol[killersSorted[1]]
	local i = 2
	while(i <= #killersSorted) do
		local colTicks = g_LastCol[killersSorted[i]]
		assert(colTicks <= lastColTicks)
		if(lastColTicks - colTicks > 2000) then
			table.remove(killersSorted, i)
		else
			i = i + 1
		end
	end
	
	if(#killersSorted > 0) then
		local killerName = getPlayerName(killersSorted[1])
		local assistName = killersSorted[2] and getPlayerName(killersSorted[2]) or "no"
		outputDebugString("Killer "..killerName.." assist "..assistName, 3)
	end
	
	g_LastCol = {}
	return unpack(killersSorted)
end

--[[local function onMyselfWasted()
	local killerPlayer, assistPlayer = DdGetKillers()
	triggerServerEvent('stats.onDDKillersList', resourceRoot, killerPlayer, assistPlayer)
end]]

function DDSetKillersDetectionEnabled(enabled)
	local curEnabled = g_LastCol and true
	if(curEnabled == enabled) then return end
	--outputDebugString('DD killers detection: '..tostring(enabled), 3)
	
	if(enabled) then
		addEventHandler("onClientPlayerQuit", g_Root, onPlayerQuit)
		addEventHandler("onClientVehicleCollision", g_Root, onVehCol)
		--addEventHandler("onClientPlayerWasted", g_Me, onMyselfWasted)
		g_LastCol = {}
	else
		removeEventHandler("onClientPlayerQuit", g_Root, onPlayerQuit)
		removeEventHandler("onClientVehicleCollision", g_Root, onVehCol)
		--removeEventHandler("onClientPlayerWasted", g_Me, onMyselfWasted)
		g_LastCol = false
	end
end
