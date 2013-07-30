local TIMER_INTERVAL = 100

Worker = {}
Worker.__mt = {__index = Worker}
Worker.map = {}

function Worker:start()
	assert(not self.co)
	self.co = coroutine.create(Worker.mainProc)
	local success, msg = coroutine.resume(self.co, self.id)
	if(not success) then
		outputDebugString('Worker failed: '..msg, 2)
	elseif(coroutine.status(self.co) ~= 'dead') then
		self.timer = setTimer(Worker.onTick, TIMER_INTERVAL, 0, self.id)
	end
end

function Worker:destroy()
	if(self.timer) then
		killTimer(self.timer)
	end
	Worker.map[self.id] = nil
end

function Worker:init(info)
	self.info = info
	self.index = 1
	self.id = #Worker.map + 1
	self.ctx = {}
	self.startTicks = getTickCount()
	Worker.map[self.id] = self
end

function Worker.create(info)
	assert(type(info) == 'table')
	local self = setmetatable({}, Worker.__mt)
	self:init(info)
	return self
end

function Worker.onTick(id)
	local self = Worker.map[id]
	
	local success, msg = coroutine.resume(self.co)
	if(not success) then
		outputDebugString('Worker failed: '..msg, 2)
		self:destroy()
	end
	
	-- Note: if we succeeded and corountine has ended current object is already destroyed
end

function Worker.mainProc(id)
	local self = Worker.map[id]
	
	local loopStart = getTickCount()
	while(true) do
		local dt = getTickCount() - loopStart
		if(dt > 1000) then
			if(self.info.fnSleep) then
				self.info.fnSleep(self)
			elseif(self.info.player and self.info.count) then
				privMsg(self.info.player, self.index..'/'..self.info.count)
			end
			coroutine.yield()
			loopStart = getTickCount()
		end
		
		if(self.info.fnWork(self) == false) then break end
		self.index = self.index + 1
		if(self.info.count and self.index > self.info.count) then break end
	end
	
	local dt = getTickCount() - self.startTicks
	if(self.info.fnFinish) then
		self.info.fnFinish(self, dt)
	elseif(self.info.player) then
		privMsg(self.info.player, "Finished in %u ms.", dt)
	end
	self:destroy()
end
