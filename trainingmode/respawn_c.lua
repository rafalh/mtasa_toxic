-- Some useful variables
local g_Me = getLocalPlayer ()
local g_Root = getRootElement ()
local g_ResRoot = getResourceRootElement ()
local g_ScrW, g_ScrH = guiGetScreenSize ()

-- Settings
local g_RespawnKey = "space"
local g_HelpMsg = {
	"#FF5500Press #FFFFFF"..g_RespawnKey.." #FF5500to respawn",
	pl = "#FF5500Wcisnij #FFFFFF"..(g_RespawnKey == "space" and "spacje" or g_RespawnKey).." #FF5500aby dokonac respawnu" }
	
local g_HelpMsgScale = (g_ScrH + g_ScrW) / 1800 -- 1.5 for 1680x1050
local g_HelpMsgFont = "bankgothic"
local g_HelpMsgColor = tocolor(255, 128, 0, 255)
local g_SaveInterval = 20000

-- Internal variables
local g_Running = false
local g_VehData = {}
local g_SaveTimer = false
local g_SavedTicks = 0
local g_RespawnedTicks = 0

local g_TmEnabled = false
local g_RespawnEnabled = false

addEvent ( "onClientTrainingMode", true )
addEvent ( "onClientRequestUnfreeze", true )
addEvent ( "onRequestRespawn", true )

local TmRespawn -- TmEnableRespawn and TmDisableRespawn needs it

local function TmRenderHelpMsg ()
	local lang = getElementData(g_Me, "lang")
	local msg = g_HelpMsg[lang] or g_HelpMsg[1]
	dxDrawText(msg, 0, g_ScrH * 0.75, g_ScrW, g_ScrH,
		g_HelpMsgColor, g_HelpMsgScale, g_HelpMsgFont, "center", "top",
		false, false, false, true)
end

local function TmEnableRespawn ( wait )
	if ( not g_TmEnabled ) then return end
	
	if ( wait ) then
		setTimer ( TmEnableRespawn, 3000, 1 )
	elseif ( #g_VehData > 0 and not g_RespawnEnabled ) then
		g_RespawnEnabled = true
		addEventHandler ( "onClientRender", g_Root, TmRenderHelpMsg )
		bindKey ( g_RespawnKey, "up", TmRespawn )
	end
end

local function TmDisableRespawn ()
	if ( not g_RespawnEnabled ) then return end
	
	g_RespawnEnabled = false
	unbindKey ( g_RespawnKey, "up", TmRespawn )
	removeEventHandler ( "onClientRender", g_Root, TmRenderHelpMsg )
end

-- Save vehicle data, to later spawn with that data.
local function TmSaveVehData ()
	assert ( g_TmEnabled )
	
	local veh = getPedOccupiedVehicle( g_Me )
	if ( not veh ) then return end
	
	local data = {}
	
	-- Later add worldSpecialProperty too.
	data.pos = { getElementPosition ( veh ) }
	data.rot = { getElementRotation ( veh ) }
	data.vel = { getElementVelocity ( veh ) }
	data.turn_vel = { getVehicleTurnVelocity ( veh ) }
	data.grav = { getVehicleGravity ( veh ) }
	data.health = getElementHealth ( veh )
	data.model = getElementModel ( veh )
	data.dimension = getElementDimension ( veh )
	data.fire = getControlState('vehicle_fire')
	data.hovercars = isWorldSpecialPropertyEnabled('hovercars')
	data.aircars = isWorldSpecialPropertyEnabled('aircars')
	
	data.nitro = false
	local upgrades = getVehicleUpgrades ( veh )
	for k, v in ipairs ( upgrades ) do
		if ( v >= 1008 and v <= 1010 ) then
			data.nitro = v
		end
	end
	
	if ( #g_VehData > 0 ) then
		local prev_data = g_VehData[#g_VehData]
		local dist = getDistanceBetweenPoints3D ( data.pos[1], data.pos[2], data.pos[3], prev_data.pos[1], prev_data.pos[2], prev_data.pos[3] )
		if ( dist < 1 and data.model == prev_data.model ) then
			--outputDebugString ( "AFK detected.", 3 )
			return
		end
	end
	
	table.insert ( g_VehData, data )
	g_SavedTicks = getTickCount ()
	
	--outputDebugString ( "Vehicle data num "..#g_VehData.." saved.", 3 )
end

-- respawn player, later add "checkpoints"
TmRespawn = function ()
	--outputDebugString ( "Respawning with vehicle data index: "..#g_VehData, 3 )
	
	TmDisableRespawn ()
	
	setElementData ( g_Me, "respawn.playing", true, true )
	triggerServerEvent ( "onRequestRespawn", g_Me, g_VehData[#g_VehData] )
	g_RespawnedTicks = getTickCount ()
	
	if ( not g_SaveTimer ) then
		g_SaveTimer = setTimer ( TmSaveVehData, g_SaveInterval, 0 )
	end
end

-- When element data for the player changes, bind or unbind key.
local function TmUpdatePlayerState ()
	local state = getElementData ( g_Me, "state" )
	
	if ( state ~= "dead" ) then
		TmDisableRespawn ()
		setElementData ( g_Me, "respawn.playing", false, true )
	end
	
	if ( state == "alive" ) then
		if ( not g_SaveTimer ) then
			TmSaveVehData ()
			g_SaveTimer = setTimer ( TmSaveVehData, g_SaveInterval, 0 )
		end
	end
end

local function TmOnPlayerDataChange ( dataName )
	if ( g_TmEnabled and source == g_Me and dataName == "state" ) then
		TmUpdatePlayerState ()
	end
end

local function TmPlayerWasted ()
	assert ( source == g_Me )
	
	setElementData ( g_Me, "respawn.playing", false, true )
	
	if ( g_SaveTimer ) then
		killTimer ( g_SaveTimer )
		g_SaveTimer = false
		
		if ( #g_VehData > 1 ) then
			local saved_delay = getTickCount () - g_SavedTicks
			local respawned_delay = getTickCount () - g_RespawnedTicks
			if ( saved_delay <= 5000 or respawned_delay <= 5000 ) then
				table.remove ( g_VehData )
				saved_delay = 0
				--outputDebugString ( "Removed vehicle data num "..( #g_VehData + 1 )..".", 3 )
			end
		end
	end
	
	if ( g_TmEnabled ) then
		TmEnableRespawn ( true )
	end
end

local function TmUnfreeze2 ( data )
	local veh = getPedOccupiedVehicle ( g_Me )
	if ( not veh ) then return end
	
	--setElementHealth ( veh, data.health )
	setElementPosition ( veh, unpack ( data.pos ) )
	setElementRotation ( veh, unpack ( data.rot ) )
	setElementVelocity ( veh, unpack ( data.vel ) )
	setVehicleTurnVelocity ( veh, unpack ( data.turn_vel ) )
	setVehicleGravity ( veh, unpack ( data.grav ) )
	setElementDimension ( veh, data.dimension )
	setControlState ( 'vehicle_fire', data.fire )
	
	setWorldSpecialPropertyEnabled('hovercars', data.hovercars)
	setWorldSpecialPropertyEnabled('aircars', data.aircars)
end

local function TmUnfreeze ( data )
	local veh = getPedOccupiedVehicle ( g_Me )
	if ( not veh ) then return end
	
	setElementFrozen ( veh, false )
	setTimer ( TmUnfreeze2, 50, 1, data )
end

local function TmSetEnabled ( enabled )
	if ( g_TmEnabled == enabled ) then return end
	
	g_TmEnabled = enabled
	g_VehData = {}
	--outputDebugString ( "Training mode is "..( g_TmEnabled and "enabled" or "disabled" )..".", 3 )
	
	if ( g_TmEnabled ) then
		TmUpdatePlayerState ()
	else
		TmDisableRespawn ()
		
		if ( g_SaveTimer ) then
			killTimer ( g_SaveTimer )
			g_SaveTimer = false
		end
		
		setElementData ( g_Me, "respawn.playing", false, true )
	end
end

local function TmInit ()
	setElementData ( g_Me, "respawn.playing", false, true )
end

addEventHandler ( "onClientElementDataChange", g_Me, TmOnPlayerDataChange )
addEventHandler ( "onClientPlayerWasted", g_Me, TmPlayerWasted )
addEventHandler ( "onClientResourceStart", g_ResRoot, TmInit )
addEventHandler ( "onClientTrainingMode", g_Me, TmSetEnabled )
addEventHandler ( "onClientRequestUnfreeze", g_Root, TmUnfreeze )
