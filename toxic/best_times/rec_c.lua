--------------
-- Includes --
--------------

#include "include/internal_events.lua"

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

local g_Timer = nil
local g_WaitingForCountdown = false
local g_Recording = {}
local g_MapID = 0

local g_X, g_Y, g_Z
local g_RX, g_RY, g_RZ
local g_VX, g_VY, g_VZ
local g_Model
local g_Time

--------------------------------
-- Local function definitions --
--------------------------------

local function RcRecordingTimer()
	local veh = getPedOccupiedVehicle(g_Me)
	if(not isElement(veh)) then return end
	
	local x, y, z = getElementPosition(veh)
	x, y, z = math.floor(x*100), math.floor(y*100), math.floor(z*100)
	local dx, dy, dz = x - g_X, y - g_Y, z - g_Z
	
	if(dx ~= 0 or dy ~= 0 or dz ~= 0) then
		local rx, ry, rz = getElementRotation(veh) -- default rotation order for vehicles
		rx, ry, rz = math.floor(rx), math.floor(ry), math.floor(rz)
		--local vx, vy, vz = getElementVelocity ( veh )
		local model = getElementModel(veh)
		local ticks = getTickCount()
		
		local data = {
			ticks - g_Time,
			dx, dy, dz, -- x, y, z
			rx - g_RX, ry - g_RY, rz - g_RZ, -- rx, ry, rz
			--math.floor ( ( vx - g_VX ) * 100 ), math.floor ( ( vy - g_VY ) * 100 ), math.floor ( ( vz - g_VZ ) * 100 ) -- vx, vy, vz
		}
		if(model ~= g_Model) then
			table.insert(data, model)
		end
		
		table.insert(g_Recording, data)
		
		g_X, g_Y, g_Z = x, y, z
		g_RX, g_RY, g_RZ = rx, ry, rz
		g_VX, g_VY, g_VZ = vx, vy, vz
		g_Model = model
		g_Time = ticks
	end
end

local function RcStartRecording()
	g_Recording = {}
	g_X, g_Y, g_Z = 0, 0, 0
	g_RX, g_RY, g_RZ = 0, 0, 0
	g_VX, g_VY, g_VZ = 0, 0, 0
	g_Model = 0
	g_Time = getTickCount()
	RcRecordingTimer()
	g_Timer = setTimer(RcRecordingTimer, $(RECORDING_INTERVAL), 0)
end

local function RcPreRender() -- checks for countdown end
	assert(g_WaitingForCountdown)
	
	local veh = getPedOccupiedVehicle(g_Me)
	if(not veh or isVehicleFrozen(veh)) then return end
	
	--outputDebugString("Countdown has finished", 3)
	g_WaitingForCountdown = false
	removeEventHandler("onClientPreRender", g_Root, RcPreRender)
	
	RcStartRecording()
end

local function RcCleanupRecording()
	if(g_Timer) then
		killTimer(g_Timer)
		g_Timer = false
	elseif(g_WaitingForCountdown) then
		g_WaitingForCountdown = false
		removeEventHandler("onClientPreRender", g_Root, RcPreRender)
	end
	
	g_Recording = {}
end

local function RcStartRecordingReq(map_id)
	--outputDebugString("RcStartRecordingReq", 3)
	
	RcCleanupRecording()
	
	-- Remember map ID
	g_MapID = map_id
	
	-- Wait for countdown end
	g_WaitingForCountdown = true
	addEventHandler("onClientPreRender", g_Root, RcPreRender)
end

local function RcStopRecordingReq()
	outputDebugString("RcStopRecordingReq", 3)
	
	RcCleanupRecording()
end

local function RcStopSendRecordingReq(map_id)
	outputDebugString("RcStopSendRecordingReq", 3)
	
	if(map_id == g_MapID) then
		triggerServerInternalEvent($(EV_RECORDING), g_Me, g_MapID, g_Recording)
	else
		outputDebugString("Wrong map ID: "..tostring(map_id).."<>"..tostring(g_MapID), 3)
	end
	
	RcCleanupRecording()
end

------------
-- Events --
------------

local function RcInit()
	addInternalEventHandler($(EV_CLIENT_START_RECORDING_REQUEST), RcStartRecordingReq)
	addInternalEventHandler($(EV_CLIENT_STOP_RECORDING_REQUEST), RcStopRecordingReq)
	addInternalEventHandler($(EV_CLIENT_STOP_SEND_RECORDING_REQUEST), RcStopSendRecordingReq)
end

addEventHandler("onClientResourceStart", g_ResRoot, RcInit)
