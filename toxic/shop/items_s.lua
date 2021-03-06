--------------
-- Includes --
--------------

#include 'include/internal_events.lua'
#include 'include/config.lua'

addEvent('toxic.onBuyNextMapReq', true)

local g_RaceRes = Resource('race')
local g_VipRes = Resource('rafalh_vip')

ShpRegisterItem{
	id = 'joinmsg',
	field = 'joinmsg',
	onBuy = function(player, val)
		return not val and Player.fromEl(player).accountData:set('joinmsg', '')
	end,
	onSell = function(player, val)
		return val and Player.fromEl(player).accountData:set('joinmsg', nil)
	end,
}

ShpRegisterItem{
	id = 'health100',
	field = 'health100',
	onBuy = function(player, val)
		return Player.fromEl(player).accountData:add('health100', 1)
	end,
	onUse = function(player, val)
		local veh = getPedOccupiedVehicle(player)
		if(val <= 0 or isPedDead(player) or not veh or getElementHealth(veh) >= 1000) then
			return false
		end
		
		fixVehicle(veh)
		Player.fromEl(player).accountData:add('health100', -1)
		return true
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('health100', -1)
	end,
}

ShpRegisterItem{
	id = 'flip',
	field = 'flips',
	onBuy = function(player, val)
		return Player.fromEl(player).accountData:add('flips', 1)
	end,
	onUse = function(player, val)
		local veh = getPedOccupiedVehicle(player)
		if(not veh) then return false end
		
		local rx, ry, rz = getElementRotation(veh)
		if(val > 0 and not isPedDead(player) and(( rx > 90 and rx < 270) or(ry > 90 and ry < 270))) then
			setElementRotation(veh, 0, 0, rz + 180)
			Player.fromEl(player).accountData:add('flips', -1)
			return true
		end
		return false
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('flips', -1)
	end
}

ShpRegisterItem{
	id = 'selfdestr',
	field = 'selfdestr',
	onBuy = function(player, val)
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('selfdestr', 1)
	end,
	onUse = function(player, val)
		if(val > 0 and not isPedDead(player) and (not g_RaceRes:isReady() or g_RaceRes:call('getTimePassed') > 5000)) then
			setTimer(function(player)
				if(not isPedDead(player)) then
					local el = getPedOccupiedVehicle(player) or player
					local x, y, z = getElementPosition(el)
					createExplosion(x, y, z, 7)
				end
			end, 3000, 1, player)
			Player.fromEl(player).accountData:add('selfdestr', -1)
			return true
		end
		return false
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('selfdestr', -1)
	end
}

ShpRegisterItem{
	id = 'mine',
	field = 'mines',
	onBuy = function(player, val)
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('mines', 1)
	end,
	onUse = function(player, val)
		if(val <= 0 or isPedDead(player)) then
			return false
		end
		
		local el = getPedOccupiedVehicle(player) or player
		local x, y, z = getElementPosition(el)
		local vx, vy, vz = getElementVelocity(el)
		local speed =(vx^2 + vy^2 + vz^2) ^ 0.5
		local v = math.max(speed, 0.012)
		local marker = createMarker(x, y, z, 'cylinder', 1, 255, 0, 0, 128)
		if not marker then
			-- Note: createMarker fails on some bugged maps if created marker is immediately consumed in onMarkerHit event
			outputDebugString('createMarker failed', 2)
			return false
		end
		setTimer(function(x, y, z, marker)
			destroyElement(marker)
			local room = g_RootRoom
			local mine = createObject(1225, x, y, z)
			assert(mine)
			table.insert(room.tempElements, mine)
		end, math.max(60/v, 50), 1, x, y, z, marker)
		Player.fromEl(player).accountData:add('mines', -1)
		return true
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('mines', -1)
	end
}

local function ShpOnOilHit(veh)
	if(getElementType(veh) ~= 'vehicle') then return end
	
	local vx, vy, vz = getElementVelocity(veh)
	local speed2 = vx^2 + vy^2 + vz^2
	local dir =({ 1, -1 })[math.random(1, 2)]
	local turn_v = speed2 / 5 * dir * math.random(80, 120) / 100
	--Debug.warn('Oil hit: '..turn_v)
	setVehicleTurnVelocity(veh, 0, 0, turn_v)
end

ShpRegisterItem{
	id = 'oil',
	field = 'oil',
	onBuy = function(player, val)
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('oil', 1)
	end,
	onUse = function(player, val)
		if(val <= 0 or isPedDead(player)) then
			return false
		end
		
		local el = getPedOccupiedVehicle(player) or player
		local x, y, z = getElementPosition(el)
		local vx, vy, vz = getElementVelocity(el)
		local v = math.max(( vx^2 + vy^2)^( 1/2), 0.001)
		local room = g_RootRoom
		local marker = createMarker(x, y, z - 0.4, 'cylinder', 8, 255, 255, 0, 32)
		if not marker then
			-- Note: createMarker fails on some bugged maps if created marker is immediately consumed in onMarkerHit event
			outputDebugString('createMarker failed', 2)
			return false
		end
		table.insert(room.tempElements, marker)
		setTimer(function(marker)
			if(isElement(marker)) then
				addEventHandler('onMarkerHit', marker, ShpOnOilHit, false)
			end
		end, math.max(80/v, 50), 1, marker)
		Player.fromEl(player).accountData:add('oil', -1)
		return true
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('oil', -1)
	end
}

ShpRegisterItem{
	id = 'beer',
	field = 'beers',
	onBuy = function(player, val)
		return Player.fromEl(player).accountData:add('beers', 1)
	end,
	onUse = function(player, val)
		if(val <= 0) then
			return false
		end
		
		triggerClientInternalEvent(player, $(EV_CLIENT_DRUNK_EFFECT), player)
		Player.fromEl(player).accountData:add('beers', -1)
		return true
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('beers', -1)
	end
}

ShpRegisterItem{
	id = 'invisibility',
	field = 'invisibility',
	onBuy = function(player, val)
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('invisibility', 1)
	end,
	onUse = function(player, val)
		local pdata = Player.fromEl(player)
		if(pdata.invisible or val <= 0 or isPedDead(player)) then
			return false
		end
		
		if(g_RaceRes:isReady() and g_RaceRes:call('getTimePassed') < 1000) then
			return false
		end
		
		addEvent('toxic.onSetPlayerAlphaReq', true)
		for player2, pdata2 in pairs(g_Players) do
			if(player2 ~= player and pdata2.sync) then
				triggerClientEvent(player2, 'toxic.onSetPlayerAlphaReq', player, 0)
			end
		end
		pdata.accountData:add('invisibility', -1)
		pdata.invisible = true
		return true
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('invisibility', -1)
	end
}

local function ShpGodmodeVehicleDamage(loss)
	if(loss > 0) then
		fixVehicle(source)
	end
end

ShpRegisterItem{
	id = 'godmode30',
	field = 'godmodes30',
	onBuy = function(player, val)
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('godmodes30', 1)
	end,
	onUse = function(player, val)
		local veh = getPedOccupiedVehicle(player)
		if(val <= 0 or isPedDead(player) or not veh) then
			return false
		end
		
		fixVehicle(veh)
		addEventHandler('onVehicleDamage', veh, ShpGodmodeVehicleDamage)
		local seconds = touint(Shop.Config.get('godmode30').params.seconds, 15)
		setTimer(function(veh)
			if(isElement(veh)) then
				removeEventHandler('onVehicleDamage', veh, ShpGodmodeVehicleDamage)
			end
		end, seconds*1000, 1, veh)
		Player.fromEl(player).accountData:add('godmodes30', -1)
		return true
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('godmodes30', -1)
	end
}

ShpRegisterItem{
	id = 'thunder',
	field = 'thunders',
	onBuy = function(player, val)
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('thunders', 1)
	end,
	onUse = function(player, val)
		if(val <= 0 or isPedDead(player)) then
			return false
		end
		
		if(g_RaceRes:isReady() and g_RaceRes:call('getTimePassed') < 3000) then
			return false
		end
		
		local bestplayer, bestdist = nil, 20
		local pos = { getElementPosition(player) }
		local dim = getElementDimension(player)
		for player2, pdata2 in pairs(g_Players) do
			if(player2 ~= player and not isPedDead(player2) and getElementDimension(player2) == dim) then
				local pos2 = { getElementPosition(player2) }
				local dist = getDistanceBetweenPoints3D(pos[1], pos[2], pos[3], pos2[1], pos2[2], pos2[3])
				if(dist < bestdist) then
					bestdist = dist
					bestplayer = player2
				end
			end
		end
		
		if(bestplayer) then
			privMsg(bestplayer, "You have been killed by %s's thunder!", getPlayerName(player))
			killPed(bestplayer, player, 40)
		else
			privMsg(player, "There is no player near your vehicle.")
			return false
		end
		
		local pdata = Player.fromEl(player)
		triggerClientEvent(getReadyPlayers(pdata.room), 'toxic.onThunderEffect', player, bestplayer)
		pdata.accountData:add('thunders', -1)
		return true
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('thunders', -1)
	end
}

ShpRegisterItem{
	id = 'smoke',
	field = 'smoke',
	onBuy = function(player)
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('smoke', 1)
	end,
	onUse = function(player, val)
		local veh = getPedOccupiedVehicle(player)
		if(val <= 0 or isPedDead(player) or not veh) then
			return false
		end
		
		local seconds = touint(Shop.Config.get('smoke').params.seconds, 15)
		local x, y, z = getElementPosition(veh)
		local obj = createObject(2780, x, y, z)
		attachElements(obj, veh, 0, -2, 0)
		setTimer(destroyElement, seconds * 1000, 1, obj)
		
		Player.fromEl(player).accountData:add('smoke', -1)
		return true
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('smoke', -1)
	end
}

-- 2892 - long spike strip
-- 2899 - short spike strip
ShpRegisterItem{
	id = 'spikestrip',
	field = 'spikeStrips',
	onBuy = function(player)
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('spikeStrips', 1)
	end,
	onUse = function(player, val)
		if(val <= 0 or isPedDead(player)) then
			return false
		end
		
		RPC('ShpUseItem', 'spikestrip'):setClient(player):exec()
		return true
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('spikeStrips', -1)
	end
}

ShpRegisterItem{
	id = 'nextmap',
	clientSideBuy = true,
}

ShpRegisterItem{
	id = 'vip1w',
	noDiscount = true,
	onBuy = function(player)
		local days = touint(Shop.Config.get('vip1w').params.days, 7)
		local success = g_VipRes:isReady() and g_VipRes:call('giveVip', player, days)
		if(not success) then
			privMsg(player, "You have to be logged in!")
		end
		return success
	end
}

--------------------------------
-- Local function definitions --
--------------------------------

local function ShpSetJoinMsgRequest(str)
	local pdata = Player.fromEl(client)
	local joinMsg = pdata.accountData:get('joinmsg')
	if(joinMsg) then
		pdata.accountData:set('joinmsg', str:sub(1, 128))
	end
end

local function ShpMapStop()
	for player, pdata in pairs(g_Players) do
		pdata.invisible = nil
	end
end

local function ShpBuyNextMap(mapResName)
	local pdata = Player.fromEl(client)
	local now = getRealTime().timestamp
	
	local price = ShpGetItemPrice('nextmap', client)
	if(pdata.accountData.cash < price) then
		privMsg(client, "Not enough cash!")
		return
	end
	
	local mapRes = getResourceFromName(mapResName)
	local map = mapRes and Map(mapRes)
	if(not map) then
		Debug.warn('getResourceFromName failed')
		return
	end
	
	local room = pdata.room
	local mapName = map:getName()
	if(MqGetMapPos(room, map)) then
		privMsg(client, "Map %s is already queued!", mapName)
		return
	end
	
	local forbReason, arg = map:isForbidden(room)
	if(forbReason) then
		privMsg(client, forbReason, arg)
		return
	end
	
	local minDelayForPlayer = Settings.minBuyMapPlayerDelay
	local mapBoughtTimestamp = pdata.accountData.mapBoughtTimestamp
	if(mapBoughtTimestamp > 0 and now - mapBoughtTimestamp < minDelayForPlayer) then
		local delay = mapBoughtTimestamp + minDelayForPlayer - now
		privMsg(client, "You cannot buy maps so often. Please wait %s...", formatTimePeriod(delay, 0))
		return
	end
	
	local mapId = map:getId()
	local row = DbQuerySingle('SELECT played_timestamp FROM '..MapsTable..' WHERE map=? LIMIT 1', mapId)
	
	-- Note: played_timestamp can be NULL if map has not been played yet
	local minDelayForMap = Settings.minBuyMapDelay
	local dt = row.played_timestamp and (now - row.played_timestamp)
	if(not dt or dt > minDelayForMap) then
		local pos = MqAdd(room, map)
		if(pos) then
			outputMsg(room, Styles.maps, "%s has been bought by %s (%u. in map queue)!", mapName, pdata:getName(true), pos)
			
			pdata.accountData:add('cash', -price)
			pdata.accountData:add('mapsBought', 1)
			pdata.accountData:set('mapBoughtTimestamp', now)
		else
			outputMsg(pdata.el, Styles.red, "Map queue is full!")
		end
	else
		local delay = minDelayForMap - dt
		privMsg(client, "Map %s have been recently played. Please wait %s...", mapName, formatTimePeriod(delay, 0))
	end
end

RPC.allow('ShpSpikeStrip')
function ShpSpikeStrip(x, y, z, rx, ry, rz, mat)
	local player = Player.fromEl(client)
	if(not player or player.accountData.spikeStrips <= 0) then return end
	
	local el = getPedOccupiedVehicle(player.el) or player.el
	local vx, vy, vz = getElementVelocity(el)
	local speed = (vx^2 + vy^2 + vz^2) ^ 0.5
	local v = math.max(speed, 0.012)
	local room = g_RootRoom
	
	local obj = createObject(2892, x, y, z, rx, ry, rz)
	assert(obj)
	table.insert(room.tempElements, obj)
	
	local center = Vector3(x, y, z)
	local rightDir = Vector3(mat[1][1], mat[1][2], mat[1][3]):normalize()
	local fwDir = Vector3(mat[2][1], mat[2][2], mat[2][3]):normalize()
	local bwLeft = center - rightDir*5 - fwDir
	local bwRight = center + rightDir*5 - fwDir
	local fwLeft = center - rightDir*5 + fwDir
	local fwRight = center + rightDir*5 + fwDir
	local col = createColPolygon(center[1], center[2], bwLeft[1], bwLeft[2], bwRight[1], bwRight[2], fwRight[1], fwRight[2], fwLeft[1], fwLeft[2])
	local minZ, maxZ = z, z + 3
	assert(col)
	table.insert(room.tempElements, col)
	
	setTimer(function()
		if(not isElement(obj)) then return end
		
		addEventHandler('onColShapeHit', col, function(el)
			if(getElementType(el) ~= 'player') then return end
			local x, y, z = getElementPosition(el)
			if(z < minZ or z > maxZ) then return end
			
			local veh = getPedOccupiedVehicle(el)
			setVehicleWheelStates(veh, 1, 1, 1, 1)
		end)
	end, math.max(60/v, 50), 1)
	
	player.accountData.spikeStrips = player.accountData.spikeStrips - 1
	ShpSyncInventory(player)
end

------------
-- Events --
------------

addInitFunc(function()
	addInternalEventHandler($(EV_SET_JOIN_MSG_REQUEST), ShpSetJoinMsgRequest)
	addEventHandler('onGamemodeMapStop', g_Root, ShpMapStop)
	addEventHandler('toxic.onBuyNextMapReq', g_Root, ShpBuyNextMap)
end)
