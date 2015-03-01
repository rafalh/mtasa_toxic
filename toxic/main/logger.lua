Logger = Class('Logger')
Logger.bufferedList = {}

function Logger.__mt.__index:destroy()
	if(self.file) then
		-- Close file if this is a buffered logger
		fileClose(self.file)
		self.file = nil
	end
end

function Logger.__mt.__index:init(name, buffered)
	self.name = name
	
	if(buffered) then
		-- Use buffering - open file when logger is created and close when resource stops
		local path = 'runtime/'..self.name..'.log'
		self.file = fileExists(path) and fileOpen(path) or fileCreate(path)
		if(self.file) then
			fileSetPos(self.file, fileGetSize(self.file)) -- append to file
			self.saveTimestamp = getRealTime().timestamp
			table.insert(Logger.bufferedList, self)
		else
			Debug.warn('Failed to open log '..tostring(path))
		end
	end
end

function Logger.__mt.__index:print(str)
	local file = self.file
	if(not file) then
		-- This is not a buffered logger - open file
		local path = 'runtime/'..self.name..'.log'
		file = fileExists(path) and fileOpen(path) or fileCreate(path)
		if(not file) then
			Debug.warn('Failed to open log '..tostring(path))
			return
		end
		
		-- Set position to the end of log file
		fileSetPos(file, fileGetSize(file))
	end
	
	-- Append message to log
	local tm = getRealTime()
	local timeStr = ('[%04u-%02u-%02u %02u:%02u:%02u]'):format(tm.year + 1900, tm.month + 1, tm.monthday, tm.hour, tm.minute, tm.second)
	fileWrite(file, timeStr..' '..str..'\n')
	
	-- Close file if this is not a buffered logger
	if(not self.file) then
		fileClose(file)
	elseif(tm.timestamp - self.saveTimestamp > 300) then
		-- Allow flush every 5 minutes
		fileFlush(self.file)
		self.saveTimestamp = tm.timestamp
	end
end

addInitFunc(function()
	addEventHandler('onResourceStop', resourceRoot, function()
		for i, logger in ipairs(Logger.bufferedList) do
			logger:destroy()
		end
	end)
end)
