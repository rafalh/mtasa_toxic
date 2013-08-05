--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

addEvent('onBuyNextMapReq', true)

local JoinMsgItem = {
	id = 'joinmsg',
	cost = 20000,
	field = 'joinmsg',
}

function JoinMsgItem.onBuy(player, val)
	return not val and Player.fromEl(player).accountData:set('joinmsg', '')
end

function JoinMsgItem.onSell ( player, val )
	return val and Player.fromEl(player).accountData:set('joinmsg', nil)
end

ShpRegisterItem(JoinMsgItem)

local HealthItem = {
	id = 'health100',
	cost = 100000,
	field = 'health100',
	onBuy = function ( player, val )
		return Player.fromEl(player).accountData:add('health100', 1)
	end,
	onUse = function ( player, val )
		local veh = getPedOccupiedVehicle ( player )
		if ( val <= 0 or isPedDead ( player ) or not veh or getElementHealth ( veh ) >= 1000 ) then
			return false
		end
		
		fixVehicle ( veh )
		Player.fromEl(player).accountData:add('health100', -1)
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and Player.fromEl(player).accountData:add('health100', -1)
	end
}

ShpRegisterItem(HealthItem)

local FlipItem = {
	id = 'flip',
	cost = 50000,
	field = 'flips',
	onBuy = function ( player, val )
		return Player.fromEl(player).accountData:add('flips', 1)
	end,
	onUse = function ( player, val )
		local veh = getPedOccupiedVehicle ( player )
		if ( not veh ) then return false end
		
		local rx, ry, rz = getElementRotation ( veh )
		if ( val > 0 and not isPedDead ( player ) and ( ( rx > 90 and rx < 270 ) or ( ry > 90 and ry < 270 ) ) ) then
			setElementRotation ( veh, 0, 0, rz + 180 )
			Player.fromEl(player).accountData:add('flips', -1)
			return true
		end
		return false
	end,
	onSell = function ( player, val )
		return val > 0 and Player.fromEl(player).accountData:add('flips', -1)
	end
}

ShpRegisterItem(FlipItem)

local SelfDestrItem = {
	id = 'selfdestr',
	cost = 500000,
	field = 'selfdestr',
	onBuy = function ( player, val )
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('selfdestr', 1)
	end,
	onUse = function ( player, val )
		local res = getResourceFromName ( 'race' )
		if ( val > 0 and not isPedDead ( player ) and ( not res or getResourceState ( res ) ~= 'running' or call ( res, 'getTimePassed' ) > 5000 ) ) then
			setTimer ( function ( player )
				if ( not isPedDead ( player ) ) then
					local el = getPedOccupiedVehicle ( player ) or player
					local x, y, z = getElementPosition ( el )
					createExplosion ( x, y, z, 7 )
				end
			end, 3000, 1, player )
			Player.fromEl(player).accountData:add('selfdestr', -1)
			return true
		end
		return false
	end,
	onSell = function ( player, val )
		return val > 0 and Player.fromEl(player).accountData:add('selfdestr', -1)
	end
}

ShpRegisterItem(SelfDestrItem)

local MineItem = {
	id = 'mine',
	cost = 200000,
	field = 'mines',
	onBuy = function ( player, val )
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('mines', 1)
	end,
	onUse = function ( player, val )
		if ( val <= 0 or isPedDead ( player ) ) then
			return false
		end
		
		local el = getPedOccupiedVehicle ( player ) or player
		local x, y, z = getElementPosition ( el )
		local vx, vy, vz = getElementVelocity ( el )
		local speed = ( vx^2 + vy^2 + vz^2 ) ^ 0.5
		local v = math.max ( speed, 0.012 )
		setTimer ( function ( x, y, z, marker )
			destroyElement ( marker )
			local room = g_RootRoom
			table.insert ( room.tempElements, createObject ( 1225, x, y, z ) )
		end, math.max ( 60/v, 50 ), 1, x, y, z, createMarker ( x, y, z, 'cylinder', 1, 255, 0, 0, 128 ) )
		Player.fromEl(player).accountData:add('mines', -1)
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and Player.fromEl(player).accountData:add('mines', -1)
	end
}

ShpRegisterItem(MineItem)

local function ShpOnOilHit ( veh )
	if ( getElementType ( veh ) ~= 'vehicle' ) then return end
	
	local vx, vy, vz = getElementVelocity ( veh )
	local speed2 = vx^2 + vy^2 + vz^2
	local dir = ( { 1, -1 } )[math.random ( 1, 2 )]
	local turn_v = speed2 / 5 * dir * math.random ( 80, 120 ) / 100
	--outputDebugString ( 'Oil hit: '..turn_v, 2 )
	setVehicleTurnVelocity ( veh, 0, 0, turn_v )
end

local OilItem = {
	id = 'oil',
	cost = 100000,
	field = 'oil',
	onBuy = function ( player, val )
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('oil', 1)
	end,
	onUse = function ( player, val )
		if ( val <= 0 or isPedDead ( player ) ) then
			return false
		end
		
		local el = getPedOccupiedVehicle ( player ) or player
		local x, y, z = getElementPosition ( el )
		local vx, vy, vz = getElementVelocity ( el )
		local v = math.max ( ( vx^2 + vy^2 )^( 1/2 ), 0.001 )
		local marker = createMarker(x, y, z - 0.4, 'cylinder', 8, 255, 255, 0, 32)
		local room = g_RootRoom
		table.insert(room.tempElements, marker)
		setTimer ( function(marker)
			if(isElement(marker)) then
				addEventHandler('onMarkerHit', marker, ShpOnOilHit, false)
			end
		end, math.max ( 60/v, 50 ), 1, marker)
		Player.fromEl(player).accountData:add('oil', -1)
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and Player.fromEl(player).accountData:add('oil', -1)
	end
}

ShpRegisterItem(OilItem)

local BeerItem = {
	id = 'beer',
	cost = 2,
	field = 'beers',
	onBuy = function ( player, val )
		return Player.fromEl(player).accountData:add('beers', 1)
	end,
	onUse = function ( player, val )
		if ( val <= 0 ) then
			return false
		end
		
		triggerClientInternalEvent ( player, $(EV_CLIENT_DRUNK_EFFECT), player )
		Player.fromEl(player).accountData:add('beers', -1)
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and Player.fromEl(player).accountData:add('beers', -1)
	end
}

ShpRegisterItem(BeerItem)

local InvisibilityItem = {
	id = 'invisibility',
	cost = 300000,
	field = 'invisibility',
	onBuy = function ( player, val )
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('invisibility', 1)
	end,
	onUse = function ( player, val )
		local pdata = Player.fromEl(player)
		if ( pdata.invisible or val <= 0 or isPedDead ( player ) ) then
			return false
		end
		
		local res = getResourceFromName ( 'race' )
		if ( res and getResourceState ( res ) == 'running' and call ( res, 'getTimePassed' ) < 1000 ) then
			return false
		end
		
		addEvent ( 'onSetPlayerAlphaReq', true )
		for player2, pdata2 in pairs ( g_Players ) do
			local a = ( player2 == player ) and 102 or 0
			triggerClientEvent ( player2, 'onSetPlayerAlphaReq', player, a )
		end
		Player.fromEl(player).accountData:add('invisibility', -1)
		pdata.invisible = true
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and Player.fromEl(player).accountData:add('invisibility', -1)
	end
}

ShpRegisterItem(InvisibilityItem)

local function ShpGodmodeVehicleDamage ( loss )
	if ( loss > 0 ) then
		fixVehicle ( source )
	end
end

local GodmodeItem = {
	id = 'godmode30',
	cost = 300000,
	field = 'godmodes30',
	onBuy = function ( player, val )
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('godmodes30', 1)
	end,
	onUse = function ( player, val )
		local veh = getPedOccupiedVehicle ( player )
		if ( val <= 0 or isPedDead ( player ) or not veh ) then
			return false
		end
		
		fixVehicle ( veh )
		addEventHandler ( 'onVehicleDamage', veh, ShpGodmodeVehicleDamage )
		setTimer ( function ( veh )
			if ( isElement ( veh ) ) then
				removeEventHandler ( 'onVehicleDamage', veh, ShpGodmodeVehicleDamage )
			end
		end, 60000, 1, veh )
		Player.fromEl(player).accountData:add('godmodes30', -1)
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and Player.fromEl(player).accountData:add('godmodes30', -1)
	end
}

ShpRegisterItem(GodmodeItem)

local ThunderItem = {
	id = 'thunder',
	cost = 200000,
	field = 'thunders',
	onBuy = function ( player, val )
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('thunders', 1)
	end,
	onUse = function ( player, val )
		if ( val <= 0 ) then
			return false
		end
		
		local res = getResourceFromName ( 'race' )
		if ( res and getResourceState ( res ) == 'running' and call ( res, 'getTimePassed' ) < 3000 ) then
			return false
		end
		
		local bestplayer, bestdist = nil, 20
		local pos = { getElementPosition ( player ) }
		for player2, pdata2 in pairs ( g_Players ) do
			if ( player2 ~= player ) then
				local pos2 = { getElementPosition ( player2 ) }
				local dist = getDistanceBetweenPoints3D (pos[1], pos[2], pos[3], pos2[1], pos2[2], pos2[3])
				if ( dist < bestdist ) then
					bestdist = dist
					bestplayer = player2
				end
			end
		end
		
		if ( bestplayer ) then
			privMsg ( bestplayer, "You have been killed by %s's thunder!", getPlayerName ( player ) )
			killPed ( bestplayer, player, 40 )
		else
			privMsg ( player, "There is no player near your vehicle." )
			return false
		end
		
		addEvent ( 'onThunderEffect', true )
		triggerClientEvent ( g_Root, 'onThunderEffect', player, bestplayer )
		Player.fromEl(player).accountData:add('thunders', -1)
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and Player.fromEl(player).accountData:add('thunders', -1)
	end
}

ShpRegisterItem(ThunderItem)

local SmokeItem = {
	id = 'smoke',
	cost = 100000,
	field = 'smoke',
	onBuy = function ( player )
		AchvActivate(player, 'Buy a weapon')
		return Player.fromEl(player).accountData:add('smoke', 1)
	end,
	onUse = function ( player, val )
		local veh = getPedOccupiedVehicle ( player )
		if ( val <= 0 or isPedDead ( player ) or not veh ) then
			return false
		end
		
		local x, y, z = getElementPosition ( veh )
		local obj = createObject ( 2780, x, y, z )
		attachElements ( obj, veh, 0, -2, 0 )
		setTimer ( destroyElement, 15000, 1, obj )
		
		Player.fromEl(player).accountData:add('smoke', -1)
		return true
	end,
	onSell = function(player, val)
		return val > 0 and Player.fromEl(player).accountData:add('smoke', -1)
	end
}

ShpRegisterItem(SmokeItem)

local NextMapItem = {
	id = 'nextmap',
	cost = 20000,
	onBuy = function ( player )
		triggerClientEvent(player, 'rafalh_onBuyNextMap', g_ResRoot)
		return false
	end
}

ShpRegisterItem(NextMapItem)

local VipItem = {
	id = 'vip1w',
	cost = 2800000,
	noDiscount = true,
	onBuy = function ( player )
		local res = getResourceFromName ( 'rafalh_vip' )
		local success = res and call ( res, 'giveVip', player, 7 )
		if ( not success ) then
			privMsg ( player, "You have to be logged in!" )
		end
		return success
	end
}

ShpRegisterItem(VipItem)

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
	local map = mapRes and Map.create(mapRes)
	if ( not map ) then
		outputDebugString('getResourceFromName failed', 2)
		return
	end
	
	local room = pdata.room
	local mapName = map:getName()
	if(MqGetMapPos(room, map)) then
		privMsg(client, "Map %s is already queued!", mapName)
		return
	end
	
	local forb_reason, arg = map:isForbidden(room)
	if(forb_reason) then
		privMsg(client, forb_reason, arg)
		return
	end
	
	local minDelayForPlayer = Settings.minBuyMapPlayerDelay
	local mapBoughtTimestamp = pdata.accountData.mapBoughtTimestamp
	if(mapBoughtTimestamp > 0 and now - mapBoughtTimestamp < minDelayForPlayer) then
		local delay = mapBoughtTimestamp + minDelayForPlayer - now
		privMsg(client, "You cannot buy maps so often. Please wait %s...", formatTimePeriod(delay, 0))
		return
	end
	
	local map_id = map:getId()
	local rows = DbQuery('SELECT played_timestamp FROM '..MapsTable..' WHERE map=? LIMIT 1', map_id)
	
	local minDelayForMap = Settings.minBuyMapDelay
	local dt = now - rows[1].played_timestamp
	if(dt > minDelayForMap) then
		local pos = MqAdd(room, map)
		outputMsg(room, Styles.maps, "%s has been bought by %s (%u. in map queue)!", mapName, pdata:getName(true), pos)
		
		pdata.accountData:add('cash', -price)
		pdata.accountData:add('mapsBought', 1)
		pdata.accountData:set('mapBoughtTimestamp', now)
	else
		local delay = minDelayForMap - dt
		privMsg(client, "Map %s have been recently played. Please wait %s...", mapName, formatTimePeriod(delay, 0))
	end
end

------------
-- Events --
------------

addInitFunc(function()
	addInternalEventHandler($(EV_SET_JOIN_MSG_REQUEST), ShpSetJoinMsgRequest)
	addEventHandler('onGamemodeMapStop', g_Root, ShpMapStop)
	addEventHandler('onBuyNextMapReq', g_Root, ShpBuyNextMap)
end)
