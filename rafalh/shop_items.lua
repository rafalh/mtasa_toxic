--------------
-- Includes --
--------------

#include "include/internal_events.lua"
addEvent ( "onBuyNextMapReq", true )

local JoinMsgItem = {
	id = "joinmsg",
	cost = 20000,
	field = "joinmsg",
}

function JoinMsgItem.onBuy ( player, val )
	return not val and DbQuery ( "UPDATE rafalh_players SET joinmsg='' WHERE player=?", g_Players[player].id )
end

function JoinMsgItem.onSell ( player, val )
	return val and DbQuery ( "UPDATE rafalh_players SET joinmsg=NULL WHERE player=?", g_Players[player].id )
end

ShpRegisterItem(JoinMsgItem)

function JmPlayerJoin ( player )
	if ( not g_Players[player] ) then
		return
	end
	
	local rows = DbQuery ( "SELECT joinmsg FROM rafalh_players WHERE player=? LIMIT 1", g_Players[player].id )
	
	if ( rows[1].joinmsg ) then
		local r, g, b = getPlayerNametagColor ( player )
		outputChatBox ( "(JOINMSG) "..getPlayerName ( player )..": #EBDDB2"..rows[1].joinmsg, g_Root, r, g, b, true )
	end
end

local HealthItem = {
	id = "health100",
	cost = 100000,
	field = "health100",
	onBuy = function ( player, val )
		return DbQuery ( "UPDATE rafalh_players SET health100=health100+1 WHERE player=?", g_Players[player].id )
	end,
	onUse = function ( player, val )
		local veh = getPedOccupiedVehicle ( player )
		if ( val <= 0 or isPedDead ( player ) or not veh or getElementHealth ( veh ) >= 1000 ) then
			return false
		end
		
		fixVehicle ( veh )
		DbQuery ( "UPDATE rafalh_players SET health100=health100-1 WHERE player=?", g_Players[player].id )
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and DbQuery ( "UPDATE rafalh_players SET health100=health100-1 WHERE player=?", g_Players[player].id )
	end
}

ShpRegisterItem(HealthItem)

local FlipItem = {
	id = "flip",
	cost = 50000,
	field = "flips",
	onBuy = function ( player, val )
		return DbQuery ( "UPDATE rafalh_players SET flips=flips+1 WHERE player=?", g_Players[player].id )
	end,
	onUse = function ( player, val )
		local veh = getPedOccupiedVehicle ( player )
		if ( not veh ) then return false end
		
		local rx, ry, rz = getElementRotation ( veh )
		if ( val > 0 and not isPedDead ( player ) and ( ( rx > 90 and rx < 270 ) or ( ry > 90 and ry < 270 ) ) ) then
			setElementRotation ( veh, 0, 0, rz + 180 )
			DbQuery ( "UPDATE rafalh_players SET flips=flips-1 WHERE player=?", g_Players[player].id )
			return true
		end
		return false
	end,
	onSell = function ( player, val )
		return val > 0 and DbQuery ( "UPDATE rafalh_players SET flips=flips-1 WHERE player=?", g_Players[player].id )
	end
}

ShpRegisterItem(FlipItem)

local SelfDestrItem = {
	id = "selfdestr",
	cost = 500000,
	field = "selfdestr",
	onBuy = function ( player, val )
		return DbQuery ( "UPDATE rafalh_players SET selfdestr=selfdestr+1 WHERE player=?", g_Players[player].id )
	end,
	onUse = function ( player, val )
		local res = getResourceFromName ( "race" )
		if ( val > 0 and not isPedDead ( player ) and ( not res or getResourceState ( res ) ~= "running" or call ( res, "getTimePassed" ) > 5000 ) ) then
			setTimer ( function ( player )
				if ( not isPedDead ( player ) ) then
					local el = getPedOccupiedVehicle ( player ) or player
					local x, y, z = getElementPosition ( el )
					createExplosion ( x, y, z, 7 )
				end
			end, 3000, 1, player )
			DbQuery ( "UPDATE rafalh_players SET selfdestr=selfdestr-1 WHERE player=?", g_Players[player].id )
			return true
		end
		return false
	end,
	onSell = function ( player, val )
		return val > 0 and DbQuery ( "UPDATE rafalh_players SET selfdestr=selfdestr-1 WHERE player=?", g_Players[player].id )
	end
}

ShpRegisterItem(SelfDestrItem)

local MineItem = {
	id = "mine",
	cost = 200000,
	field = "mines",
	onBuy = function ( player, val )
		return DbQuery ( "UPDATE rafalh_players SET mines=mines+1 WHERE player=?", g_Players[player].id )
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
			table.insert ( g_CreatedObjects, createObject ( 1225, x, y, z ) )
		end, math.max ( 60/v, 50 ), 1, x, y, z, createMarker ( x, y, z, "cylinder", 1, 255, 0, 0, 128 ) )
		DbQuery ( "UPDATE rafalh_players SET mines=mines-1 WHERE player=?", g_Players[player].id )
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and DbQuery ( "UPDATE rafalh_players SET mines=mines-1 WHERE player=?", g_Players[player].id )
	end
}

ShpRegisterItem(MineItem)

local function ShpOnOilHit ( veh )
	if ( getElementType ( veh ) ~= "vehicle" ) then return end
	
	local vx, vy, vz = getElementVelocity ( veh )
	local speed2 = vx^2 + vy^2 + vz^2
	local dir = ( { 1, -1 } )[math.random ( 1, 2 )]
	local turn_v = speed2 / 5 * dir * math.random ( 80, 120 ) / 100
	--outputDebugString ( "Oil hit: "..turn_v, 2 )
	setVehicleTurnVelocity ( veh, 0, 0, turn_v )
end

local OilItem = {
	id = "oil",
	cost = 100000,
	field = "oil",
	onBuy = function ( player, val )
		return DbQuery ( "UPDATE rafalh_players SET oil=oil+1 WHERE player=?", g_Players[player].id )
	end,
	onUse = function ( player, val )
		if ( val <= 0 or isPedDead ( player ) ) then
			return false
		end
		
		local el = getPedOccupiedVehicle ( player ) or player
		local x, y, z = getElementPosition ( el )
		local vx, vy, vz = getElementVelocity ( el )
		local v = math.max ( ( vx^2 + vy^2 )^( 1/2 ), 0.001 )
		local marker = createMarker ( x, y, z - 0.4, "cylinder", 8, 255, 255, 0, 32 )
		table.insert ( g_CreatedObjects, marker )
		setTimer ( function ( marker )
			if ( isElement ( marker ) ) then
				addEventHandler ( "onMarkerHit", marker, ShpOnOilHit, false )
			end
		end, math.max ( 60/v, 50 ), 1, marker )
		DbQuery ( "UPDATE rafalh_players SET oil=oil-1 WHERE player=?", g_Players[player].id )
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and DbQuery ( "UPDATE rafalh_players SET oil=oil-1 WHERE player=?", g_Players[player].id )
	end
}

ShpRegisterItem(OilItem)

local BeerItem = {
	id = "beer",
	cost = 2,
	field = "beers",
	onBuy = function ( player, val )
		return DbQuery ( "UPDATE rafalh_players SET beers=beers+1 WHERE player=?", g_Players[player].id )
	end,
	onUse = function ( player, val )
		if ( val <= 0 ) then
			return false
		end
		
		triggerClientInternalEvent ( player, $(EV_CLIENT_DRUNK_EFFECT), player )
		DbQuery ( "UPDATE rafalh_players SET beers=beers-1 WHERE player=?", g_Players[player].id )
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and DbQuery ( "UPDATE rafalh_players SET beers=beers-1 WHERE player=?", g_Players[player].id )
	end
}

ShpRegisterItem(BeerItem)

local InvisibilityItem = {
	id = "invisibility",
	cost = 300000,
	field = "invisibility",
	onBuy = function ( player, val )
		return DbQuery ( "UPDATE rafalh_players SET invisibility=invisibility+1 WHERE player=?", g_Players[player].id )
	end,
	onUse = function ( player, val )
		local pdata = g_Players[player]
		if ( pdata.invisible or val <= 0 or isPedDead ( player ) ) then
			return false
		end
		
		local res = getResourceFromName ( "race" )
		if ( res and getResourceState ( res ) == "running" and call ( res, "getTimePassed" ) < 1000 ) then
			return false
		end
		
		addEvent ( "onSetPlayerAlphaReq", true )
		for player2, pdata2 in pairs ( g_Players ) do
			local a = ( player2 == player ) and 102 or 0
			triggerClientEvent ( player2, "onSetPlayerAlphaReq", player, a )
		end
		DbQuery ( "UPDATE rafalh_players SET invisibility=invisibility-1 WHERE player=?", g_Players[player].id )
		pdata.invisible = true
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and DbQuery ( "UPDATE rafalh_players SET invisibility=invisibility-1 WHERE player=?", g_Players[player].id )
	end
}

ShpRegisterItem(InvisibilityItem)

local function ShpGodmodeVehicleDamage ( loss )
	if ( loss > 0 ) then
		fixVehicle ( source )
	end
end

local GodmodeItem = {
	id = "godmode30",
	cost = 300000,
	field = "godmodes30",
	onBuy = function ( player, val )
		return DbQuery ( "UPDATE rafalh_players SET godmodes30=godmodes30+1 WHERE player=?", g_Players[player].id )
	end,
	onUse = function ( player, val )
		local veh = getPedOccupiedVehicle ( player )
		if ( val <= 0 or isPedDead ( player ) or not veh ) then
			return false
		end
		
		fixVehicle ( veh )
		addEventHandler ( "onVehicleDamage", veh, ShpGodmodeVehicleDamage )
		setTimer ( function ( veh )
			if ( isElement ( veh ) ) then
				removeEventHandler ( "onVehicleDamage", veh, ShpGodmodeVehicleDamage )
			end
		end, 60000, 1, veh )
		DbQuery ( "UPDATE rafalh_players SET godmodes30=godmodes30-1 WHERE player=?", g_Players[player].id )
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and DbQuery ( "UPDATE rafalh_players SET godmodes30=godmodes30-1 WHERE player=?", g_Players[player].id )
	end
}

ShpRegisterItem(GodmodeItem)

local ThunderItem = {
	id = "thunder",
	cost = 200000,
	field = "thunders",
	onBuy = function ( player, val )
		return DbQuery ( "UPDATE rafalh_players SET thunders=thunders+1 WHERE player=?", g_Players[player].id )
	end,
	onUse = function ( player, val )
		if ( val <= 0 ) then
			return false
		end
		
		local res = getResourceFromName ( "race" )
		if ( res and getResourceState ( res ) == "running" and call ( res, "getTimePassed" ) < 3000 ) then
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
			privMsg ( bestplayer, "You have been killed by %s thunder", getPlayerName ( player ) )
			killPed ( bestplayer, player, 40 )
		else
			privMsg ( player, "There is no player near your vehicle." )
			return false
		end
		
		addEvent ( "onThunderEffect", true )
		triggerClientEvent ( g_Root, "onThunderEffect", player, bestplayer )
		DbQuery ( "UPDATE rafalh_players SET thunders=thunders-1 WHERE player=?", g_Players[player].id )
		return true
	end,
	onSell = function ( player, val )
		return val > 0 and DbQuery ( "UPDATE rafalh_players SET thunders=thunders-1 WHERE player=?", g_Players[player].id )
	end
}

ShpRegisterItem(ThunderItem)

local SmokeItem = {
	id = "smoke",
	cost = 100000,
	field = "smoke",
	onBuy = function ( player )
		return DbQuery ( "UPDATE rafalh_players SET smoke=smoke+1 WHERE player=?", g_Players[player].id )
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
		
		DbQuery ( "UPDATE rafalh_players SET smoke=smoke-1 WHERE player=?", g_Players[player].id )
		return true
	end
}

ShpRegisterItem(SmokeItem)

local NextMapItem = {
	id = "nextmap",
	cost = 20000,
	onBuy = function ( player )
		triggerClientEvent(player, "rafalh_onBuyNextMap", g_ResRoot)
		return false
	end
}

ShpRegisterItem(NextMapItem)

local VipItem = {
	id = "vip1w",
	cost = 2200000,
	onBuy = function ( player )
		local res = getResourceFromName ( "rafalh_vip" )
		local success = res and call ( res, "giveVip", player, 7 )
		if ( not success ) then
			privMsg ( player, "You have to be loged in!" )
		end
		return success
	end
}

ShpRegisterItem(VipItem)

--------------------------------
-- Local function definitions --
--------------------------------

local function ShpSetJoinMsgRequest ( str )
	local rows = DbQuery ( "SELECT joinmsg FROM rafalh_players WHERE player=? LIMIT 1", g_Players[client].id )
	if ( str and rows[1].joinmsg ) then
		DbQuery ( "UPDATE rafalh_players SET joinmsg=? WHERE player=?", str:sub ( 1, 128 ), g_Players[client].id )
	end
end

local function ShpMapStop ()
	for player, pdata in pairs ( g_Players ) do
		pdata.invisible = nil
	end
end

local function ShpBuyNextMap ( map_res_name )
	local pdata = g_Players[client]
	local now = getRealTime().timestamp
	
	local cash = StGet ( client, "cash" )
	if ( cash < g_ShopItems.nextmap.cost ) then
		privMsg ( client, "Not enough cash!" )
		return
	end
	
	local map_res = getResourceFromName(map_res_name)
	local map = map_res and Map.create(map_res)
	if ( not map ) then
		outputDebugString("getResourceFromName failed", 2)
		return
	end
	
	local room = pdata.room
	local mapName = map:getName()
	if(MqGetMapPos(room, map)) then
		privMsg(client, "Map %s is already queued!", mapName)
		return
	end
	
	local forb_reason, arg = map:isForbidden(room)
	if ( forb_reason ) then
		privMsg ( client, forb_reason, arg )
		return
	end
	
	local minDelayForPlayer = SmGetUInt("minBuyMapPlayerDelay", 600)
	if(pdata.buyMapTimeStamp and now - pdata.buyMapTimeStamp < minDelayForPlayer) then
		local delay = pdata.buyMapTimeStamp + minDelayForPlayer - now
		privMsg(client, "You cannot buy maps so often. Please wait %s...", formatTimePeriod(delay, 0))
		return
	end
	
	local map_id = map:getId()
	local rows = DbQuery("SELECT played_timestamp FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
	
	local minDelayForMap = SmGetUInt("minBuyMapDelay", 600)
	local dt = now - rows[1].played_timestamp
	if(dt > minDelayForMap) then
		local pos = MqAdd(room, map)
		customMsg(128, 255, 196, "%s has been bought by %s (%u. in map queue)!", mapName, getPlayerName(client), pos)
		
		cash = cash - g_ShopItems.nextmap.cost
		StSet(client, "cash", cash)
		pdata.buyMapTimeStamp = now
	else
		local delay = max_delay - dt
		privMsg(client, "Map %s have been recently played. Please wait %s...", mapName, formatTimePeriod(delay, 0))
	end
end

------------
-- Events --
------------

addInternalEventHandler ( $(EV_SET_JOIN_MSG_REQUEST), ShpSetJoinMsgRequest )
addEventHandler ( "onGamemodeMapStop", g_Root, ShpMapStop )
addEventHandler ( "onBuyNextMapReq", g_Root, ShpBuyNextMap )
