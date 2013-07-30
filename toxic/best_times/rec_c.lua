Recorder = {}
Recorder.__mt = {__index = {cls = Recorder}}
Recorder.map = {}

#include 'include/internal_events.lua'

#RECORDING_INTERVAL = 250

#RD_TIME = 1
#RD_X = 2
#RD_Y = 3
#RD_Z = 4
#RD_RX = 5
#RD_RY = 6
#RD_RZ = 7
#RD_MODEL = 8

local g_Rec, g_MapID
local g_Waiting

function Recorder.timerProc(id)
	local self = Recorder.map[id]
	
	local veh = getPedOccupiedVehicle(g_Me)
	if(not isElement(veh)) then return end
	
	local x, y, z = getElementPosition(veh)
	local rx, ry, rz = getElementRotation(veh) -- default rotation order for vehicles
	local model = getElementModel(veh)
	local ticks = getTickCount()
	
	x, y, z = math.floor(x*100), math.floor(y*100), math.floor(z*100)
	local dx, dy, dz = x - self.x, y - self.y, z - self.z
	if(dx ~= 0 or dy ~= 0 or dz ~= 0) then
		rx, ry, rz = math.floor(rx), math.floor(ry), math.floor(rz)
		local drx, dry, drz = rx - self.rx, ry - self.ry, rz - self.rz
		
		local data = {
			ticks - self.ticks,
			dx, dy, dz, -- pos
			drx, dry, drz, -- rot
		}
		if(model ~= self.model) then
			table.insert(data, model)
		end
		
		table.insert(self.data, data)
		
		self.x, self.y, self.z = x, y, z
		self.rx, self.ry, self.rz = rx, ry, rz
		self.model = model
		self.ticks = ticks
	end
end

function Recorder.__mt.__index:start()
	self.data = {}
	self.x, self.y, self.z = 0, 0, 0
	self.rx, self.ry, self.rz = 0, 0, 0
	self.model = 0
	self.ticks = getTickCount()
	Recorder.timerProc(self.id)
	self.timer = setTimer(Recorder.timerProc, $(RECORDING_INTERVAL), 0, self.id)
end

function Recorder.__mt.__index:destroy()
	if(self.timer) then
		killTimer(self.timer)
	end
	self.data = {}
	Recorder.map[self.id] = nil
end

function Recorder.create()
	local self = setmetatable({}, Recorder.__mt)
	self.id = #Recorder.map + 1
	Recorder.map[self.id] = self
	return self
end

function Recorder.preRender() -- checks for countdown end
	assert(g_Rec and g_Waiting)
	
	local veh = getPedOccupiedVehicle(g_Me)
	if(not veh or isVehicleFrozen(veh)) then return end
	
	--outputDebugString('Countdown has finished', 3)
	removeEventHandler('onClientPreRender', g_Root, Recorder.preRender)
	
	g_Waiting = false
	g_Rec:start()
end

function Recorder.startReq(map_id)
	--outputDebugString('Recorder.startReq', 3)
	
	if(g_Rec) then
		g_Rec:destroy()
	end
	
	g_MapID = map_id
	g_Rec = Recorder.create()
	if(not g_Waiting) then
		addEventHandler('onClientPreRender', g_Root, Recorder.preRender)
		g_Waiting = true
	end
end

function Recorder.stopReq()
	outputDebugString('Recorder.stopReq', 3)
	
	if(g_Rec) then
		g_Rec:destroy()
		g_Rec = false
	end
	
	if(g_Waiting) then
		removeEventHandler('onClientPreRender', g_Root, Recorder.preRender)
	end
end

function Recorder.stopSendReq(mapId)
	outputDebugString('Recorder.stopSendReq', 3)
	assert(g_Rec and not g_Waiting)
	
	if(mapId == g_MapID) then
		triggerServerInternalEvent($(EV_RECORDING), g_Me, g_MapID, g_Rec.data)
	else
		outputDebugString('Wrong map ID: '..tostring(map_id)..'<>'..tostring(g_MapID), 3)
	end
	
	g_Rec:destroy()
	g_Rec = false
end

------------
-- Events --
------------

local function RcInit()
	addInternalEventHandler($(EV_CLIENT_START_RECORDING_REQUEST), Recorder.startReq)
	addInternalEventHandler($(EV_CLIENT_STOP_RECORDING_REQUEST), Recorder.stopReq)
	addInternalEventHandler($(EV_CLIENT_STOP_SEND_RECORDING_REQUEST), Recorder.stopSendReq)
end

addEventHandler('onClientResourceStart', g_ResRoot, RcInit)
