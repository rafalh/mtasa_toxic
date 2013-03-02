local g_TmEnabled = false
local g_Root = getRootElement ()
local g_DangerousVeh = { [425] = true, [520] = true, [464] = true, [447] = true } -- hunter etc.

addEvent ( "onClientTrainingMode", true )
addEvent ( "onRequestRespawn", true )
addEvent ( "onRaceStateChanging" )
addEvent ( "onPlayerPickUpRacePickup" )

local function TmDoesMapSupportRespawn ( map_res )
	if ( not map_res ) then
		map_res = exports.mapmanager:getRunningGamemodeMap ()
	end
	
	if ( not map_res ) then
		--outputDebugString ( "no map running", 3 )
		return false
	end
	
	local map_root = getResourceRootElement ( map_res )
	if ( #getElementsByType ( "checkpoint", map_root ) > 0 ) then
		--outputDebugString ( "race", 3 )
		return false
	end
	
	local res_name = getResourceName ( map_res )
	local respawn = get ( res_name..".respawn" ) or get ( "race.respawnmode" )
	if ( respawn ~= "none" ) then
		--outputDebugString ( "respawn", 3 )
		return false
	end
	
	local map_name = getResourceInfo ( map_res, "name" ) or res_name
	if ( not map_name:lower ():match ( "%[dm%]" ) ) then
		--outputDebugString ( "not dm", 3 )
		return false
	end
	
	--outputDebugString ( "dm", 3 )
	return true
end

local function TmLoadVehData ( veh, data )
	setElementModel ( veh, 481 ) -- fix motor sound
	setElementModel ( veh, data.model )
	spawnVehicle ( veh, data.pos[1], data.pos[2], data.pos[3], data.rot[1], data.rot[2], data.rot[3] )
	setElementHealth ( veh, data.health )
	if ( data.nitro ) then
		addVehicleUpgrade ( veh, data.nitro )
	end
	setVehicleLandingGearDown ( veh, true )
end

local function TmDelayedRespawn ( player, data )
	--outputDebugString ( "TmDelayedRespawn "..tostring ( g_TmEnabled ), 3 )
	if ( g_TmEnabled and isElement ( player ) ) then
		-- Make sure everything is still ok
		local veh = exports.race:getPlayerVehicle ( player )
		TmLoadVehData ( veh, data )
		
		-- Unfreeze on client side
		triggerClientEvent ( player, "onClientRequestUnfreeze", player, data )
	end
end

local function TmRequestRespawn ( data )
	--outputDebugString ( "TmRequestRespawn "..tostring ( g_TmEnabled ), 3 )
	if ( not g_TmEnabled ) then return end
	
	-- source is the player that requested respawn.
	-- spawn at the position where last saved.
	local player = client
	triggerClientEvent ( player, "onClientCall_race", player, "Spectate.stop", "manual" )
	triggerEvent ( 'onClientRequestSpectate', player, false )
	spawnPlayer ( player, unpack ( data.pos ) )
	
	local veh = exports.race:getPlayerVehicle ( player )
	if(not isElement(veh)) then
		outputDebugString("Invalid vehicle", 2)
		return
	end
	warpPedIntoVehicle ( player, veh )
	triggerClientEvent ( player, "onClientCall_race", player, "Spectate.stop", "manual" )
	
	setElementData ( player, "race.spectating", true )
	setElementData ( player, "status1", "dead" )
	setElementData ( player, "status2", "" )
	--setElementData ( player, "state", "training" )
	setElementData ( player, "race.finished", true )
	setCameraTarget ( player, player )
	
	--setElementData ( veh, "race.collideworld", 1 )
	--setElementData ( veh, "race.collideothers", 0 )
	--setElementData ( player, "race.alpha", 255 )
	--setElementData ( veh, "race.alpha", 255 )
	
	setElementData( player, "overrideCollide.tm", 0, false )
	setElementData( player, "overrideAlpha.tm", 0, false )
	
	--local veh = createVehicle ( data.model, data.pos[1], data.pos[2], data.pos[3] )
	TmLoadVehData ( veh, data )
	setElementFrozen ( veh, true )
	
	toggleAllControls ( player, true )
	
	setTimer ( TmDelayedRespawn, 2000, 1, player, data )
end

local function TmRaceStateChanging(newState, oldState)
	--outputDebugString ( "TmRaceStateChanging "..tostring ( newState ), 3 )
	
	if ( newState == "Running" ) then
		g_TmEnabled = TmDoesMapSupportRespawn ()
		if ( g_TmEnabled ) then
			triggerClientEvent ( "onClientTrainingMode", g_Root, true )
		end
	elseif ( g_TmEnabled ) then
		triggerClientEvent ( "onClientTrainingMode", g_Root, false )
		g_TmEnabled = false
		
		for i, player in ipairs ( getElementsByType ( "player" ) ) do
			local replaying = getElementData ( player, "respawn.playing" )
			if ( replaying ) then
				setElementData ( player, "race.spectating", false )
				setElementData ( player, "status1", "dead" )
				setElementData ( player, "status2", "" )
				setElementData ( player, "race.finished", false )
			end
		end
	end
end

-- Kill when respawned and gets hunter
local function TmPlayerPickUpRacePickup ( pickupID, pickupType, vehicleModel )
	if ( pickupType ~= "vehiclechange" or not g_DangerousVeh[vehicleModel] ) then
		return
	end
	
	-- for example hunter
	local state = getElementData ( source, "state" ) or "dead"
	if ( state == "dead" ) then
		-- Kill
		setElementHealth ( source, 0 )
		local veh = exports.race:getPlayerVehicle ( player )
		if ( veh ) then
			setElementHealth ( veh, 0 )
		end
		
		-- Disable respawn
		triggerClientEvent ( "onClientTrainingMode", g_Root, false )
	end
end

addEventHandler ( "onRaceStateChanging", g_Root, TmRaceStateChanging )
addEventHandler ( "onPlayerPickUpRacePickup", g_Root, TmPlayerPickUpRacePickup )
addEventHandler ( "onRequestRespawn", g_Root, TmRequestRespawn )
