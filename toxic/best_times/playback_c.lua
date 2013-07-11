local TITLE_COLOR = tocolor(196, 196, 196, 96)
local USE_INTERPOLATION = true

local g_Waiting, g_Playback

Playback = {}
Playback.__mt = {__index = {cls = Playback}}
Playback.count = 0
Playback.map = {}

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

function Playback.renderTitle()
	local cx, cy, cz = getCameraMatrix()
	for id, playback in pairs(Playback.map) do
		local x, y, z = getElementPosition(playback.veh)
		local scale = 18/getDistanceBetweenPoints3D(cx, cy, cz, x, y, z)
		if(scale > 0.3) then
			local scrX, scrY = getScreenFromWorldPosition(x, y, z + 1)
			if(scrX) then
				dxDrawText(playback.title, scrX, scrY, scrX, scrY, TITLE_COLOR, scale, "default", "center")
			end
		end
	end
end

function Playback.calcAngle(rot, dr, a)
	if(dr > 180) then
		dr = dr - 360
	elseif(dr < -180) then
		dr = dr + 360
	end
	
	return rot + dr*a
end

function Playback.__mt.__index:update()
	local ticks = getTickCount()
	local dt = ticks - self.ticks
	self.ticks = ticks
	
	dt = dt + self.dt
	local frame = self.data[self.curFrameIdx]
	local nextFrame = self.data[self.curFrameIdx + 1]
	while(nextFrame and dt >= nextFrame[$(RD_TIME)]) do
		self.x = self.x + nextFrame[$(RD_X)]/100
		self.y = self.y + nextFrame[$(RD_Y)]/100
		self.z = self.z + nextFrame[$(RD_Z)]/100
		self.rotX = self.rotX + nextFrame[$(RD_RX)]
		self.rotY = self.rotY + nextFrame[$(RD_RY)]
		self.rotZ = self.rotZ + nextFrame[$(RD_RZ)]
		
		dt = dt - nextFrame[$(RD_TIME)]
		self.curFrameIdx = self.curFrameIdx + 1
		frame = self.data[self.curFrameIdx]
		nextFrame = self.data[self.curFrameIdx + 1]
	end
	self.dt = dt
	
	if(not nextFrame) then
		-- Playback has finished
		return false
	end
	
	if(frame[$(RD_MODEL)]) then
		setElementModel(self.veh, frame[$(RD_MODEL)])
	end
	
	local a = dt / nextFrame[$(RD_TIME)]
	--assert(a >= 0 and a <= 1)
	
	local x = self.x + nextFrame[$(RD_X)]/100*a
	local y = self.y + nextFrame[$(RD_Y)]/100*a
	local z = self.z + nextFrame[$(RD_Z)]/100*a
	local rx = Playback.calcAngle(self.rotX, nextFrame[$(RD_RX)], a)
	local ry = Playback.calcAngle(self.rotY, nextFrame[$(RD_RY)], a)
	local rz = Playback.calcAngle(self.rotZ, nextFrame[$(RD_RZ)], a)
	setElementPosition(self.veh, x, y, z)
	setElementRotation(self.veh, rx, ry, rz)
	
	--self.curPos = Vector3(x, y, z)
	
	if(not USE_INTERPOLATION) then
		local vx = frame[$(RD_X)]/100/frame[$(RD_TIME)]
		local vy = frame[$(RD_Y)]/100/frame[$(RD_TIME)]
		local vz = frame[$(RD_Z)]/100/frame[$(RD_TIME)]
		setElementVelocity(self.veh, vx*20.7, vy*20.7, vz*20.7)
		--setVehicleTurnVelocity(self.veh, vrx/10, vry/10, vrz/10)
	end
	
	local msToNextFrame = nextFrame[$(RD_TIME)] - self.dt
	return msToNextFrame
end

function Playback.timerProc(id)
	assert(false)
	local self = Playback.map[id]
	--outputDebugString("pos = "..self.x.." "..self.y.." "..self.z..", rot: "..self.rotX.." "..self.rotY.." "..self.rotZ)
	
	local msToNextFrame = self:update()
	if(msToNextFrame) then
		msToNextFrame = math.max(msToNextFrame, 50)
		self.timer = setTimer(Playback.timerProc, msToNextFrame, 1, self.id)
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
	self.curFrameIdx = 1
	
	-- Update vehicle
	if(not USE_INTERPOLATION) then
		Playback.timerProc(self.id)
	end
end

function Playback.preRender()
	if(g_Waiting) then
		local veh = getPedOccupiedVehicle(g_Me)
		if(veh and not isVehicleFrozen(veh)) then
			assert(g_Playback)
			g_Playback:start()
			g_Waiting = false
			
			if(not USE_INTERPOLATION) then
				removeEventHandler("onClientPreRender", g_Root, Playback.preRender)
			end
		end
	end
	
	if(USE_INTERPOLATION) then
		for id, playback in pairs(Playback.map) do
			if(playback.ticks) then
				if(not playback:update()) then
					playback:destroy()
				end
			end
		end
	end
end

--[[function Playback.__mt.__index:render()
	local myPos = Vector3(getElementPosition(localPlayer))
	local prevPos = false
	for i, frame in ipairs(self.data) do
		local curPos = (prevPos or Vector3()) + Vector3(frame[$(RD_X)], frame[$(RD_Y)], frame[$(RD_Z)])/100
		
		if(prevPos and myPos:dist(curPos) < 100) then
			dxDrawLine3D(prevPos[1], prevPos[2], prevPos[3], curPos[1], curPos[2], curPos[3], tocolor(255, 0, 0), 3)
			dxDrawLine3D(curPos[1], curPos[2], curPos[3]-0.1, curPos[1], curPos[2], curPos[3]+0.1, tocolor(0, 0, 255), 3)
		end
		prevPos = curPos
	end
	if(self.curPos) then
		dxDrawLine3D(self.curPos[1], self.curPos[2], self.curPos[3]-0.1, self.curPos[1], self.curPos[2], self.curPos[3]+0.1, tocolor(0, 255, 0), 3)
	end
end]]

function Playback.__mt.__index:destroy()
	if(self.timer) then
		killTimer(self.timer)
		self.timer = false
	end
	
	destroyElement(self.blip)
	destroyElement(self.veh)
	--self.data = false
	
	Playback.map[self.id] = nil
	Playback.count = Playback.count - 1
	assert(Playback.count >= 0)
	
	if(USE_INTERPOLATION and Playback.count == 0) then
		removeEventHandler("onClientPreRender", g_Root, Playback.preRender)
	end
	
	if(Playback.count == 0) then
		removeEventHandler("onClientRender", g_Root, Playback.renderTitle)
	end
end

function Playback.create(data, title)
	local self = setmetatable({}, Playback.__mt)
	self.data = data
	self.title = title
	self.dt = 0
	
	local firstFrame = data[1]
	local x, y, z = firstFrame[$(RD_X)]/100, firstFrame[$(RD_Y)]/100, firstFrame[$(RD_Z)]/100
	local rx, ry, rz = firstFrame[$(RD_RX)], firstFrame[$(RD_RY)], firstFrame[$(RD_RZ)]
	
	self.x, self.y, self.z = x, y, z
	self.rotX, self.rotY, self.rotZ = rx, ry, rz
	
	self.veh = createVehicle(firstFrame[$(RD_MODEL)], x, y, z, rx, ry, rz)
	setElementAlpha(self.veh, 102)
	if(USE_INTERPOLATION) then
		setElementFrozen(self.veh, true)
	else
		setVehicleGravity(self.veh, 0, 0, -0.1)
		setElementCollisionsEnabled(self.veh, false)
		setElementPosition(self.veh, x, y, z) -- reposition again after disabling collisions
	end
	
	self.blip = createBlipAttachedTo(self.veh, 0, 1, 150, 150, 150, 50)
	setElementParent(self.blip, self.veh)
	
	outputDebugString("Playback: frames = "..#data..", pos = ("..x.." "..y.." "..z.."), rot: ("..rx.." "..ry.." "..rz..")")
	
	--[[for i = 2, #data do
		data[i][$(RD_X)] = -1000
		data[i][$(RD_Y)] = 0
		data[i][$(RD_Z)] = 0
		data[i][$(RD_TIME)] = (i-1)*1000
	end]]
	
	self.id = #Playback.map + 1
	Playback.map[self.id] = self
	Playback.count = Playback.count + 1
	if(Playback.count == 1) then
		addEventHandler("onClientRender", g_Root, Playback.renderTitle)
		if(USE_INTERPOLATION) then
			addEventHandler("onClientPreRender", g_Root, Playback.preRender)
		end
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
	
	if(g_Waiting) then
		removeEventHandler("onClientPreRender", g_Root, Playback.preRender)
	end
end

-- Used by RPC
function Playback.startAfterCountdown(playback, title)
	--outputDebugString("Playback.startAfterCountdown", 3)
	if(g_Playback) then
		g_Playback:destroy()
	end
	
	g_Playback = Playback.create(playback, title)
	g_Waiting = true
	if(not USE_INTERPOLATION) then
		addEventHandler("onClientPreRender", g_Root, Playback.preRender)
	end
end
