local TITLE_COLOR = tocolor(196, 196, 196, 96)
local VEH_ALPHA = 102
local BLIP_SIZE = 1
local BLIP_COLOR = {150, 150, 150, 50}
#USE_INTERPOLATION = true
#DEBUG = false

#if(DEBUG) then
	VEH_ALPHA = 0
#end

Playback = Class('Playback')
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

-- Render title for each created playback
function Playback.renderTitle()
	local cx, cy, cz = getCameraMatrix()
	for id, playback in pairs(Playback.map) do
		if(not playback.hidden) then
			local x, y, z = getElementPosition(playback.veh)
			local scale = 18/getDistanceBetweenPoints3D(cx, cy, cz, x, y, z)
			if(scale > 0.3) then
				local scrX, scrY = getScreenFromWorldPosition(x, y, z + 1)
				if(scrX) then
					dxDrawText(playback.title, scrX, scrY, scrX, scrY, TITLE_COLOR, scale, 'default', 'center')
				end
			end
		end
	end
end

-- Sums rot and dr scaled by a (normalize dr to [-180, 180] before)
function Playback.calcAngle(rot, dr, a)
	if(dr > 180) then
		dr = dr - 360
	elseif(dr < -180) then
		dr = dr + 360
	end
	
	return rot + dr*a
end

--[[local function getBezierControlPoints(pt0, pt1, pt2, t)
	-- Based on: http://scaledinnovation.com/analytics/splines/aboutSplines.html
    local d01 = pt1.dist(pt0)
    local d12 = pt1.dist(pt2)
    local fa = t*d01 / (d01 + d12)   -- scaling factor for triangle Ta
    local fb = t*d12 / (d01 + d12)   -- ditto for Tb, simplifies to fb=t-fa
	
	local cp1 = pt1 - fa*(pt2-pt0) -- x2-x0 is the width of triangle T
	local cp2 = pt1 + fb*(pt2-pt0) -- y2-y0 is the height of T
    return cp1, cp2
end

local function bezierCurve(pt1, pt2, cp1, cp2, t)
	local t2 = 1 - t
	return (t2^3)*pt1 + 3*(t2^2)*t*cp1 + 3*t2*(t^2)*cp2 + (t^3)*pt2
end]]

function Playback.__mt.__index:loadNextFrame()
	self.curFrameIdx = self.curFrameIdx + 1
	local frame = self.data[self.curFrameIdx]
	if(self.nextPos) then
		self.pos = self.nextPos
	else
		self.pos = self.pos + Vector3(frame[$(RD_X)], frame[$(RD_Y)], frame[$(RD_Z)])/100
	end
	self.rot = self.rot + Vector3(frame[$(RD_RX)], frame[$(RD_RY)], frame[$(RD_RZ)])
	
	local nextFrame = self.data[self.curFrameIdx + 1]
	if(nextFrame) then
		self.nextPos = self.pos + Vector3(nextFrame[$(RD_X)], nextFrame[$(RD_Y)], nextFrame[$(RD_Z)])/100
	end
end

function Playback.__mt.__index:setProgress(ms)
	self.curFrameIdx = 0
	self.nextPos = false
	self.pos = Vector3()
	self.rot = Vector3()
	self:loadNextFrame()
	self.dt = 0
	
	self:addProgress(ms)
	
	if(self.ticks) then
		self.ticks = getTickCount()
	end
end

function Playback.__mt.__index:addProgress(ms)
	self.dt = self.dt + ms
	
	while(true) do
		local nextFrame = self.data[self.curFrameIdx + 1]
		if(not nextFrame or self.dt < nextFrame[$(RD_TIME)]) then break end
		self.dt = self.dt - nextFrame[$(RD_TIME)]
		self:loadNextFrame()
	end
end

function Playback.__mt.__index:setVisible(vis)
	self.hidden = not vis
	setElementAlpha(self.veh, vis and VEH_ALPHA or 0)
	setBlipColor(self.blip, BLIP_COLOR[1], BLIP_COLOR[2], BLIP_COLOR[3], vis and BLIP_COLOR[4] or 0)
end

function Playback.__mt.__index:update()
	local ticks = getTickCount()
	local dt = (ticks - self.ticks)*self.speed
	self.ticks = ticks
	
	self:addProgress(dt)
	
	local frame = self.data[self.curFrameIdx]
	local nextFrame = self.data[self.curFrameIdx + 1]
	
	if(not nextFrame) then
		-- Playback has finished
		--Debug.info('Playback has finished')
		return false
	end
	
	-- Calculate interpolation factor
	local a = self.dt / nextFrame[$(RD_TIME)]
	--assert(a >= 0 and a <= 1)
	
	-- Change model if needed
	if(frame[$(RD_MODEL)]) then
		setElementModel(self.veh, frame[$(RD_MODEL)])
	end
	
	-- Update position and rotation
	--[[local cp1 = self.pos
	local cp2 = self.nextPos
	local pos = bezierCurve(self.pos, self.nextPos, cp1, cp2, a)]]
	local pos = self.pos*(1-a) + self.nextPos*a
	local rx = Playback.calcAngle(self.rot[1], nextFrame[$(RD_RX)], a)
	local ry = Playback.calcAngle(self.rot[2], nextFrame[$(RD_RY)], a)
	local rz = Playback.calcAngle(self.rot[3], nextFrame[$(RD_RZ)], a)
	setElementPosition(self.veh, pos[1], pos[2], pos[3])
	setElementRotation(self.veh, rx, ry, rz)
	
	-- Save temporary position for debugging purposes
	self.curPos = pos
	
	-- Update velocity if position interpolation is not used
	#if(not USE_INTERPOLATION) then
		local vx = frame[$(RD_X)]/100/frame[$(RD_TIME)]
		local vy = frame[$(RD_Y)]/100/frame[$(RD_TIME)]
		local vz = frame[$(RD_Z)]/100/frame[$(RD_TIME)]
		setElementVelocity(self.veh, vx*20.7, vy*20.7, vz*20.7)
		--setVehicleTurnVelocity(self.veh, vrx/10, vry/10, vrz/10)
	#end
	
	-- Return time left to new frame
	local msToNextFrame = nextFrame[$(RD_TIME)] - self.dt
	return msToNextFrame
end

function Playback.timerProc(id)
	assert(false)
	local self = Playback.map[id]
	--Debug.info('pos = '..self.pos..', rot = '..self.rot)
	
	local msToNextFrame = self:update()
	if(msToNextFrame) then
		msToNextFrame = math.max(msToNextFrame, 50)
		self.timer = setTimer(Playback.timerProc, msToNextFrame, 1, self.id)
	else
		self.timer = false
		self:destroy()
	end
end

function Playback.__mt.__index:start(ms)
	assert(not self.ticks)
	
	-- Setup object state
	self.ticks = getTickCount()
	self:setProgress(ms or 0)
	assert((ms and ms > 0) or (self.curFrameIdx == 1 and self.dt == 0))
	
	-- Update vehicle
	self:setVisible(true)
	
	#if(not USE_INTERPOLATION) then
		Playback.timerProc(self.id)
	#end
end

function Playback.__mt.__index:stop()
	self.ticks = false
	self:setVisible(false)
end

#if(USE_INTERPOLATION) then
	function Playback.preRender()
		for id, playback in pairs(Playback.map) do
			if(playback.ticks) then
				if(not playback:update()) then
					playback:stop()
				end
			end
		end
	end
#end

#if(DEBUG) then
	-- Render full playback trace
	function Playback.__mt.__index:render()
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
	end
#end

function Playback.__mt.__index:destroy()
	if(self.timer) then
		killTimer(self.timer)
		self.timer = false
	end
	
	destroyElement(self.blip)
	destroyElement(self.veh)
	self.data = false
	
	Playback.map[self.id] = nil
	Playback.count = Playback.count - 1
	assert(Playback.count >= 0)
	
	-- Remove event handlers if this is the last playback object
	if(Playback.count == 0) then
		removeEventHandler('onClientRender', g_Root, Playback.renderTitle)
		
		#if(USE_INTERPOLATION) then
			removeEventHandler('onClientPreRender', g_Root, Playback.preRender)
		#end
	end
	
	self.destroyed = true
end

function Playback.__mt.__index:init(data, title)
	self.data = data
	self.title = title
	self.speed = 1
	self.dt = 0
	
	local firstFrame = data[1]
	local x, y, z = firstFrame[$(RD_X)]/100, firstFrame[$(RD_Y)]/100, firstFrame[$(RD_Z)]/100
	local rx, ry, rz = firstFrame[$(RD_RX)], firstFrame[$(RD_RY)], firstFrame[$(RD_RZ)]
	
	self.pos = Vector3(x, y, z)
	self.rot = Vector3(rx, ry, rz)
	
	self.veh = createVehicle(firstFrame[$(RD_MODEL)], x, y, z, rx, ry, rz)
	setElementAlpha(self.veh, VEH_ALPHA)
	#if(USE_INTERPOLATION) then
		setElementFrozen(self.veh, true)
	#else
		setVehicleGravity(self.veh, 0, 0, -0.1)
		setElementCollisionsEnabled(self.veh, false)
		setElementPosition(self.veh, x, y, z) -- reposition again after disabling collisions
	#end
	
	self.blip = createBlipAttachedTo(self.veh, 0, BLIP_SIZE, unpack(BLIP_COLOR))
	setElementParent(self.blip, self.veh)
	
	Debug.info('Playback: frames = '..#data..', pos = ('..x..' '..y..' '..z..'), rot: ('..rx..' '..ry..' '..rz..')')
	
	self.id = #Playback.map + 1
	Playback.map[self.id] = self
	Playback.count = Playback.count + 1
	
	-- Add event handlers if this is the first playback object
	if(Playback.count == 1) then
		addEventHandler('onClientRender', g_Root, Playback.renderTitle)
		#if(USE_INTERPOLATION) then
			addEventHandler('onClientPreRender', g_Root, Playback.preRender)
		#end
	end
	
	return self
end

#if(DEBUG) then
	addCommandHandler('testrec', function()
		outputChatBox('Testing recording!')
		local veh = getPedOccupiedVehicle(g_Me)
		local x, y, z = getElementPosition(veh)
		local rec = Recorder.create()
		rec:start()
		setTimer(function()
			outputChatBox('Recording finished ('..#rec.data..' frames)...')
			local playback = Playback(rec.data, 'TEST')
			rec:destroy()
			playback.speed = 0.2
			playback:start()
			setElementPosition(veh, x, y, z)
			if(playback.render) then
				addEventHandler('onClientRender', root, function()
					playback:render()
				end)
			end
		end, 5000, 1)
	end)
#end
