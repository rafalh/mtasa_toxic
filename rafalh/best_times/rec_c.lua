--------------
-- Includes --
--------------

#include "include/internal_events.lua"
#include "../include/serv_verification.lua"

-------------
-- Defines --
-------------

#RECORDING_INTERVAL = 250

#RD_TIME = 1
#RD_X = 2
#RD_Y = 3
#RD_Z = 4
#RD_RX = 5
#RD_RY = 6
#RD_RZ = 7
#RD_MODEL = 8

---------------------
-- Local variables --
---------------------

local TITLE_COLOR = tocolor(196, 196, 196, 96)

local g_Verified = false

local g_Timer = nil
local g_WaitingForCountdown = false
local g_Recording = {}
local g_MapID = 0

local g_X, g_Y, g_Z
local g_RX, g_RY, g_RZ
local g_VX, g_VY, g_VZ
local g_Model
local g_Time

local g_PlaybackVeh, g_PlaybackBlip, g_Playback
local g_PlaybackTitle, g_PlaybackTime, g_RcPlaybackTimer, g_PlaybackFrame, g_PlaybackTimeOffset
local g_PlaybackX, g_PlaybackY, g_PlaybackZ
local g_PlaybackRotX, g_PlaybackRotY, g_PlaybackRotZ

--------------------------------
-- Local function definitions --
--------------------------------

--[[local function moveVeh ( el, ms, x, y, z, drx, dry, drz )
	local old_x, old_y, old_z = getElementPosition ( el )
	local old_rx, old_ry, old_rz = getElementRotation ( el )
	local current_ms = 0
	
	local function interpolate ( dt )
		current_ms = current_ms + dt
		if ( current_ms >= ms ) then
			removeEventHandler ( "onClientPreRender", g_Root, interpolate )
		end
		
		local new_m = current_ms / ms
		local old_m = 1 - new_m
		
		local new_x = x * new_m + old_x * old_m
		local new_y = y * new_m + old_y * old_m
		local new_z = z * new_m + old_z * old_m
		setElementPosition ( el, new_x, new_y, new_z )
		
		--local new_rx = old_rx + new_m * drx
		--local new_ry = old_ry + new_m * dry
		--local new_rz = old_rz + new_m * drz
		--setElementRotation ( el, new_rx, new_ry, new_rz )
	end
	
	addEventHandler ( "onClientPreRender", g_Root, interpolate	)
end]]

local function RcRecordingTimer ()
	local veh = getPedOccupiedVehicle ( g_Me )
	if ( not isElement ( veh ) ) then return end
	
	local x, y, z = getElementPosition ( veh )
	x, y, z = math.floor ( x*100 ), math.floor ( y*100 ), math.floor ( z*100 )
	local dx, dy, dz = x - g_X, y - g_Y, z - g_Z
	
	if ( dx ~= 0 or dy ~= 0 or dz ~= 0 ) then
		local rx, ry, rz = getElementRotation ( veh ) -- default rotation order for vehicles
		rx, ry, rz = math.floor ( rx ), math.floor ( ry ), math.floor ( rz )
		--local vx, vy, vz = getElementVelocity ( veh )
		local model = getElementModel ( veh )
		local ticks = getTickCount ()
		
		local data = {
			ticks - g_Time,
			dx, dy, dz, -- x, y, z
			rx - g_RX, ry - g_RY, rz - g_RZ, -- rx, ry, rz
			--math.floor ( ( vx - g_VX ) * 100 ), math.floor ( ( vy - g_VY ) * 100 ), math.floor ( ( vz - g_VZ ) * 100 ) -- vx, vy, vz
		}
		if ( model ~= g_Model ) then
			table.insert ( data, model )
		end
		
		table.insert ( g_Recording, data )
		
		g_X, g_Y, g_Z = x, y, z
		g_RX, g_RY, g_RZ = rx, ry, rz
		g_VX, g_VY, g_VZ = vx, vy, vz
		g_Model = model
		g_Time = ticks
	end
end

local function RcRenderPlaybackTitle ()
	local cx, cy, cz = getCameraMatrix()
	local x, y, z = getElementPosition(g_PlaybackVeh)
	local scale = 18/getDistanceBetweenPoints3D(cx, cy, cz, x, y, z)
	if(scale < 0.3) then return end
	local scr_x, scr_y = getScreenFromWorldPosition(x, y, z + 1)
	if(not scr_x) then return end
	dxDrawText(g_PlaybackTitle, scr_x, scr_y, scr_x, scr_y, TITLE_COLOR, scale, "default", "center")
end

local function RcCleanupPlayback ()
	if ( not g_Playback ) then return end
	
	if ( g_RcPlaybackTimer ) then
		killTimer ( g_RcPlaybackTimer )
		g_RcPlaybackTimer = false
	end
	
	removeEventHandler("onClientRender", g_Root, RcRenderPlaybackTitle)
	destroyElement(g_PlaybackVeh)
	
	g_Playback = false
end

local function RcPlaybackTimer ()
	--outputDebugString ( "pos = "..g_PlaybackX.." "..g_PlaybackY.." "..g_PlaybackZ..", rot: "..g_PlaybackRotX.." "..g_PlaybackRotY.." "..g_PlaybackRotZ )
	
	-- move from g_PlaybackFrame-1 to g_PlaybackFrame
	
	local ticks = getTickCount ()
	local time_offset = ( ticks - g_PlaybackTime ) - g_PlaybackTimeOffset -- offset wzgledem czasu nagrania g_PlaybackFrame
	local frame = g_Playback[g_PlaybackFrame]
	
	--outputDebugString ( "step: "..g_PlaybackFrame..", time: "..g_Playback[g_PlaybackFrame][$(RD_TIME)].." time_offset: "..time_offset )
	
	local vx, vy, vz = frame[$(RD_X)]/100/frame[$(RD_TIME)], frame[$(RD_Y)]/100/frame[$(RD_TIME)],
		frame[$(RD_Z)]/100/frame[$(RD_TIME)]
	--local vrx, vry, vrz = g_Playback[g_PlaybackFrame][$(RD_RX)]/g_Playback[g_PlaybackFrame][$(RD_TIME)], g_Playback[g_PlaybackFrame][$(RD_RY)]/g_Playback[g_PlaybackFrame][$(RD_TIME)],
	--	g_Playback[g_PlaybackFrame][$(RD_RZ)]/g_Playback[g_PlaybackFrame][$(RD_TIME)]
	
	--outputDebugString ( "step: "..g_PlaybackFrame..", vx: "..vx..", vy: "..vy..", vrx: "..vrx..", vry: "..vry..", vrz: "..vrz..", time_offset: "..time_offset )
	
	if ( frame[$(RD_MODEL)] ) then
		setElementModel ( g_PlaybackVeh, frame[$(RD_MODEL)] )
	end
	
	--if ( g_PlaybackFrame%20 == 0 ) then
		setElementPosition ( g_PlaybackVeh, g_PlaybackX+vx*time_offset, g_PlaybackY+vy*time_offset, g_PlaybackZ+vz*time_offset )
	--end
	--setElementRotation ( g_PlaybackVeh, g_PlaybackRotZ+vrz*time_offset, g_PlaybackRotY+vry*time_offset, g_PlaybackRotX+vrx*time_offset )
	setElementRotation ( g_PlaybackVeh, g_PlaybackRotX, g_PlaybackRotY, g_PlaybackRotZ )
	setElementVelocity ( g_PlaybackVeh, vx*20.7, vy*20.7, vz*20.7 )
	setVehicleTurnVelocity ( g_PlaybackVeh, 0, 0, 0 )
	--setVehicleTurnVelocity ( g_PlaybackVeh, vrx/10, vry/10, vrz/10 )
	
	setElementRotation ( g_PlaybackVeh, g_PlaybackRotX, g_PlaybackRotY, g_PlaybackRotZ )
	g_PlaybackX = g_PlaybackX + frame[$(RD_X)]/100
	g_PlaybackY = g_PlaybackY + frame[$(RD_Y)]/100
	g_PlaybackZ = g_PlaybackZ + frame[$(RD_Z)]/100
	g_PlaybackRotX = g_PlaybackRotX + frame[$(RD_RX)]
	g_PlaybackRotY = g_PlaybackRotY + frame[$(RD_RY)]
	g_PlaybackRotZ = g_PlaybackRotZ + frame[$(RD_RZ)]
	
	-- moveObject doesnt work for vehicles
	--[[setElementFrozen ( g_PlaybackVeh, true )
	moveVeh ( g_PlaybackVeh, math.max ( g_Playback[g_PlaybackFrame][$(RD_TIME)] - time_offset, 50 ),
		g_PlaybackX,
		g_PlaybackY,
		g_PlaybackZ,
		frame[$(RD_RX)], frame[$(RD_RY)], frame[$(RD_RZ)] )]]
	
	g_PlaybackFrame = g_PlaybackFrame + 1
	
	if ( g_Playback[g_PlaybackFrame] ) then
		g_PlaybackTime = ticks
		g_PlaybackTimeOffset = math.max ( g_Playback[g_PlaybackFrame][$(RD_TIME)] - time_offset, 50 )
		g_RcPlaybackTimer = setTimer ( RcPlaybackTimer, g_PlaybackTimeOffset, 1 )
	else
		g_RcPlaybackTimer = false
		RcCleanupPlayback ()
	end
end

local function RcStartRecording ()
	g_Recording = {}
	g_X, g_Y, g_Z = 0, 0, 0
	g_RX, g_RY, g_RZ = 0, 0, 0
	g_VX, g_VY, g_VZ = 0, 0, 0
	g_Model = 0
	g_Time = getTickCount ()
	RcRecordingTimer ()
	g_Timer = setTimer ( RcRecordingTimer, $(RECORDING_INTERVAL), 0 )
end

local function RcStartPlayback ()
	if ( g_Playback ) then
		outputDebugString("RcStartPlayback", 3)
		g_PlaybackTime = getTickCount ()
		g_PlaybackTimeOffset = 0
		g_PlaybackFrame = 2
		RcPlaybackTimer ()
	end
end

local function RcPreRender () -- checks for countdown end
	assert ( g_WaitingForCountdown )
	
	local veh = getPedOccupiedVehicle ( g_Me )
	if(not veh or isVehicleFrozen(veh)) then return end
	
	--outputDebugString ( "Countdown has finished", 3 )
	g_WaitingForCountdown = false
	removeEventHandler ( "onClientPreRender", g_Root, RcPreRender )
	
	RcStartRecording ()
	RcStartPlayback ()
end

local function RcCleanupRecording ()
	if ( g_Timer ) then
		killTimer ( g_Timer )
		g_Timer = false
	elseif ( g_WaitingForCountdown ) then
		g_WaitingForCountdown = false
		removeEventHandler ( "onClientPreRender", g_Root, RcPreRender )
	end
	
	g_Recording = {}
end

local function RcInitPlayback ( playback, playback_title )
	g_Playback = playback
	if ( not g_Playback ) then return end
	
	local first_frame = g_Playback[1]
	g_PlaybackX = first_frame[$(RD_X)]/100
	g_PlaybackY = first_frame[$(RD_Y)]/100
	g_PlaybackZ = first_frame[$(RD_Z)]/100
	g_PlaybackRotX = first_frame[$(RD_RX)]
	g_PlaybackRotY = first_frame[$(RD_RY)]
	g_PlaybackRotZ = first_frame[$(RD_RZ)]
	outputDebugString ( "Playback: frames = "..#g_Playback..", pos = "..g_PlaybackX.." "..g_PlaybackY.." "..g_PlaybackZ..", rot: "..g_PlaybackRotX.." "..g_PlaybackRotY.." "..g_PlaybackRotZ )
	
	g_PlaybackVeh = createVehicle ( first_frame[$(RD_MODEL)], g_PlaybackX, g_PlaybackY, g_PlaybackZ, first_frame[$(RD_RX)], first_frame[$(RD_RY)], first_frame[$(RD_RZ)] )
	setVehicleGravity ( g_PlaybackVeh, 0, 0, -0.1 )
	setElementCollisionsEnabled ( g_PlaybackVeh, false )
	setElementPosition ( g_PlaybackVeh, g_PlaybackX, g_PlaybackY, g_PlaybackZ ) -- reposition again after disabling collisions
	setElementAlpha ( g_PlaybackVeh, 102 )
	
	g_PlaybackBlip = createBlipAttachedTo ( g_PlaybackVeh, 0, 1, 150, 150, 150, 50 )
	setElementParent ( g_PlaybackBlip, g_PlaybackVeh )
	
	g_PlaybackTitle = playback_title
	addEventHandler ( "onClientRender", g_Root, RcRenderPlaybackTitle )
end

local function RcWaitForCountdown ()
	g_WaitingForCountdown = true
	addEventHandler ( "onClientPreRender", g_Root, RcPreRender ) -- wait for countdown end
end

local function RcStartRecordingReq ( map_id, playback, playback_title )
	outputDebugString ( "RcStartRecordingReq", 3 )
	
	RcCleanupRecording ()
	RcCleanupPlayback ()
	
	g_MapID = map_id
	
	RcInitPlayback ( playback, playback_title )
	RcWaitForCountdown ()
end

local function RcStopRecordingReq ()
	outputDebugString ( "RcStopRecordingReq", 3 )
	
	RcCleanupRecording ()
end

local function RcStopSendRecordingReq ( map_id )
	outputDebugString ( "RcStopSendRecordingReq", 3 )
	
	if ( map_id == g_MapID ) then
		triggerServerInternalEvent ( $(EV_RECORDING), g_Me, g_MapID, g_Recording )
	else
		outputDebugString("Wrong map ID: "..tostring(map_id).."<>"..tostring(g_MapID), 3)
	end
	
	RcCleanupRecording ()
end

local function RcMapStopping ()
	RcCleanupPlayback ()
end

------------
-- Events --
------------

#VERIFY_SERVER_BEGIN ( "15037C1B515E37A28A04BCBE719D5B71" )
	addInternalEventHandler ( $(EV_CLIENT_START_RECORDING_REQUEST), RcStartRecordingReq )
	addInternalEventHandler ( $(EV_CLIENT_STOP_RECORDING_REQUEST), RcStopRecordingReq )
	addInternalEventHandler ( $(EV_CLIENT_STOP_SEND_RECORDING_REQUEST), RcStopSendRecordingReq )
	addEventHandler ( "onClientMapStopping", g_Root, RcMapStopping )
	g_Verified = true
#VERIFY_SERVER_END ()
