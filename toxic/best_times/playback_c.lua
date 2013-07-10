Playback = {}
Playback.__mt = {__index = {cls = Playback}}
Playback.list = {}
Playback.count = 0
Playback.map = {}
Playback.waitingCount = 0

-- Note: Don't use onClientMapStopping and onGamemodeMapStart because race
--       gamemode is stupid and triggers the first after the second

#RD_TIME = 1
#RD_X = 2
#RD_Y = 3
#RD_Z = 4
#RD_RX = 5
#RD_RY = 6
#RD_RZ = 7
#RD_MODEL = 8

local TITLE_COLOR = tocolor(196, 196, 196, 96)

function Playback.renderTitle()
	local cx, cy, cz = getCameraMatrix()
	for id, playback in pairs(Playback.map) do
		local x, y, z = getElementPosition(playback.veh)
		local scale = 18/getDistanceBetweenPoints3D(cx, cy, cz, x, y, z)
		if(scale > 0.3) then
			local scr_x, scr_y = getScreenFromWorldPosition(x, y, z + 1)
			if(scr_x) then
				dxDrawText(playback.title, scr_x, scr_y, scr_x, scr_y, TITLE_COLOR, scale, "default", "center")
			end
		end
	end
end

--[[local function moveVeh(el, ms, x, y, z, drx, dry, drz)
	local old_x, old_y, old_z = getElementPosition(el)
	local old_rx, old_ry, old_rz = getElementRotation(el)
	local current_ms = 0
	
	local function interpolate(dt)
		current_ms = current_ms + dt
		if(current_ms >= ms) then
			removeEventHandler("onClientPreRender", g_Root, interpolate)
		end
		
		local new_m = current_ms / ms
		local old_m = 1 - new_m
		
		local new_x = x * new_m + old_x * old_m
		local new_y = y * new_m + old_y * old_m
		local new_z = z * new_m + old_z * old_m
		setElementPosition(el, new_x, new_y, new_z)
		
		--local new_rx = old_rx + new_m * drx
		--local new_ry = old_ry + new_m * dry
		--local new_rz = old_rz + new_m * drz
		--setElementRotation(el, new_rx, new_ry, new_rz)
	end
	
	addEventHandler("onClientPreRender", g_Root, interpolate)
end]]

function Playback.timerProc(id)
	local self = Playback.map[id]
	--outputDebugString("pos = "..self.x.." "..self.y.." "..self.z..", rot: "..self.rotX.." "..self.rotY.." "..self.rotZ)
	
	-- move from self.curFrameIdx-1 to self.curFrameIdx
	
	local ticks = getTickCount()
	local time_offset = (ticks - self.ticks) - self.ticksOffset -- offset wzgledem czasu nagrania self.curFrameIdx
	local frame = self.data[self.curFrameIdx]
	
	--outputDebugString("step: "..self.curFrameIdx..", time: "..self.data[self.curFrameIdx][$(RD_TIME)].." time_offset: "..time_offset)
	
	local vx = frame[$(RD_X)]/100/frame[$(RD_TIME)]
	local vy = frame[$(RD_Y)]/100/frame[$(RD_TIME)]
	local vz = frame[$(RD_Z)]/100/frame[$(RD_TIME)]
	--local vrx = self.data[self.curFrameIdx][$(RD_RX)]/self.data[self.curFrameIdx][$(RD_TIME)]
	--local vry = self.data[self.curFrameIdx][$(RD_RY)]/self.data[self.curFrameIdx][$(RD_TIME)]
	--local vrz = self.data[self.curFrameIdx][$(RD_RZ)]/self.data[self.curFrameIdx][$(RD_TIME)]
	
	--outputDebugString("step: "..self.curFrameIdx..", vx: "..vx..", vy: "..vy..", vrx: "..vrx..", vry: "..vry..", vrz: "..vrz..", time_offset: "..time_offset)
	
	if(frame[$(RD_MODEL)]) then
		setElementModel(self.veh, frame[$(RD_MODEL)])
	end
	
	--if(self.curFrameIdx%20 == 0) then
		setElementPosition(self.veh, self.x+vx*time_offset, self.y+vy*time_offset, self.z+vz*time_offset)
	--end
	--setElementRotation(self.veh, self.rotZ+vrz*time_offset, self.rotY+vry*time_offset, self.rotX+vrx*time_offset)
	setElementRotation(self.veh, self.rotX, self.rotY, self.rotZ)
	setElementVelocity(self.veh, vx*20.7, vy*20.7, vz*20.7)
	setVehicleTurnVelocity(self.veh, 0, 0, 0)
	--setVehicleTurnVelocity(self.veh, vrx/10, vry/10, vrz/10)
	
	setElementRotation(self.veh, self.rotX, self.rotY, self.rotZ)
	self.x = self.x + frame[$(RD_X)]/100
	self.y = self.y + frame[$(RD_Y)]/100
	self.z = self.z + frame[$(RD_Z)]/100
	self.rotX = self.rotX + frame[$(RD_RX)]
	self.rotY = self.rotY + frame[$(RD_RY)]
	self.rotZ = self.rotZ + frame[$(RD_RZ)]
	
	-- moveObject doesnt work for vehicles
	--[[setElementFrozen(self.veh, true )
	moveVeh(self.veh, math.max(self.data[self.curFrameIdx][$(RD_TIME)] - time_offset, 50),
		self.x, self.y, self.z,
		frame[$(RD_RX)], frame[$(RD_RY)], frame[$(RD_RZ)])]]
	
	self.curFrameIdx = self.curFrameIdx + 1
	
	if(self.data[self.curFrameIdx]) then
		self.ticks = ticks
		self.ticksOffset = math.max(self.data[self.curFrameIdx][$(RD_TIME)] - time_offset, 50)
		self.timer = setTimer(Playback.timerProc, self.ticksOffset, 1, self.id)
	else
		self.timer = false
		self:destroy()
	end
end

function Playback.__mt.__index:start()
	assert(not self.ticks)
	
	-- Setup object state
	self.ticks = getTickCount()
	self.ticksOffset = 0
	self.curFrameIdx = 2
	
	-- Update vehicle
	Playback.timerProc(self.id)
end

function Playback.preRender()
	local veh = getPedOccupiedVehicle(g_Me)
	if(not veh or isVehicleFrozen(veh)) then return end
	
	for id, playback in pairs(Playback.map) do
		if(playback.waiting) then
			playback.waiting = false
			playback:start()
		end
	end
	
	Playback.waitingCount = 0
	removeEventHandler("onClientPreRender", g_Root, Playback.preRender)
end

function Playback.__mt.__index:startAfterCountdown()
	-- Wait for countdown end
	self.waiting = true
	Playback.waitingCount = Playback.waitingCount + 1
	
	if(Playback.waitingCount == 1) then
		addEventHandler("onClientPreRender", g_Root, Playback.preRender)
	end
end

function Playback.__mt.__index:destroy()
	if(self.timer) then
		killTimer(self.timer)
		self.timer = false
	end
	
	destroyElement(self.blip)
	destroyElement(self.veh)
	self.data = false
	
	if(self.waiting) then
		Playback.waitingCount = Playback.waitingCount - 1
		assert(Playback.waitingCount >= 0)
		
		if(Playback.waitingCount == 0) then
			removeEventHandler("onClientPreRender", g_Root, Playback.preRender)
		end
	end
	
	Playback.map[self.id] = nil
	Playback.count = Playback.count - 1
	assert(Playback.count >= 0)
	if(Playback.count == 0) then
		removeEventHandler("onClientRender", g_Root, Playback.renderTitle)
	end
end

function Playback.create(data, title)
	local self = setmetatable({}, Playback.__mt)
	self.data = data
	self.title = title
	
	local firstFrame = data[1]
	self.x = firstFrame[$(RD_X)]/100
	self.y = firstFrame[$(RD_Y)]/100
	self.z = firstFrame[$(RD_Z)]/100
	self.rotX = firstFrame[$(RD_RX)]
	self.rotY = firstFrame[$(RD_RY)]
	self.rotZ = firstFrame[$(RD_RZ)]
	
	self.veh = createVehicle(
		firstFrame[$(RD_MODEL)],
		self.x, self.y, self.z,
		firstFrame[$(RD_RX)], firstFrame[$(RD_RY)], firstFrame[$(RD_RZ)])
	setVehicleGravity(self.veh, 0, 0, -0.1)
	setElementCollisionsEnabled(self.veh, false)
	setElementPosition(self.veh, self.x, self.y, self.z) -- reposition again after disabling collisions
	setElementAlpha(self.veh, 102)
	
	self.blip = createBlipAttachedTo(self.veh, 0, 1, 150, 150, 150, 50)
	setElementParent(self.blip, self.veh)
	
	outputDebugString("Playback: frames = "..#data..", pos = ("..self.x.." "..self.y.." "..self.z.."), rot: ("..self.rotX.." "..self.rotY.." "..self.rotZ.."), veh: "..tostring(self.veh))
	
	self.id = #Playback.map + 1
	Playback.map[self.id] = self
	Playback.count = Playback.count + 1
	if(Playback.count == 1) then
		addEventHandler("onClientRender", g_Root, Playback.renderTitle)
	end
	
	return self
end

-- Used by RPC
function Playback.stop()
	--outputDebugString("Playback.stop", 3)
	if(g_Playback) then
		g_Playback:destroy()
		g_Playback = false
	end
end

-- Used by RPC
function Playback.startAfterCountdown(playback, title)
	--outputDebugString("Playback.startAfterCountdown", 3)
	if(g_Playback) then
		g_Playback:destroy()
	end
	
	g_Playback = Playback.create(playback, title)
	g_Playback:startAfterCountdown()
end
