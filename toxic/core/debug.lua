local DEBUG = true
local PERF_DEBUG_CHECKPOINTS = true
local PERF_DEBUG_EVENTS = false

Debug = {}

function Debug.print(str, lvl)
	while(str ~= '') do
		outputDebugString(str:sub(1, 511), lvl)
		str = str:sub(512)
	end
end

function Debug.info(str)
	Debug.print(str, 3)
end

function Debug.warn(str)
	Debug.print(str, 2)
end

function Debug.err(str)
	Debug.print(str, 1)
end

function Debug.getStackTrace(len, offset)
	local trace = debug.traceback('', (offset or 0) + 2)
	local lines = split(trace, '\n')
	local start, stop = 2, 1 + (len or #lines - 1)
	
	local tbl = {}
	for i = start, stop do
		local line = trimStr(lines[i])
		table.insert(tbl, line)
	end
	
	return tbl
end

function Debug.printStackTrace(lvl, len, offset)
	local trace = Debug.getStackTrace(len or false, (offset or 0) + 1)
	for i, str in ipairs(trace) do
		Debug.print(str, lvl or 2)
	end
end

local _assert = assert
function assert(val, str)
	if(not val) then
		Debug.printStackTrace(1, false, 1)
		_assert(val, str)
	end
end

local _addEventHandler = addEventHandler
function addEventHandler(...)
	local success = _addEventHandler(...)
	if(not success) then
		Debug.warn('addEventHandler failed')
		Debug.printStackTrace(2, false, 1)
	end
	return success
end

if(DEBUG) then
	function Debug.dump(str, title)
		local len = str:len()
		local bytes = {str:byte(1, len)}
		local buf = ''
		for i, byte in ipairs(bytes) do
			buf = buf..(' %02X'):format(byte)
		end
		Debug.info((title or 'dump')..':'..buf)
	end
	
	DbgPerf = Class('DbgPerf')
	
	function DbgPerf.__mt.__index:init(limit)
		self.ticks = getTickCount()
		self.limit = limit or 50
	end
	
	function DbgPerf.__mt.__index:cp(fmt, ...)
		local ticks = getTickCount()
		local dt = getTickCount() - self.ticks
		if(dt <= self.limit) then
			self.ticks = ticks
			return false
		elseif(PERF_DEBUG_CHECKPOINTS) then
			local name = fmt:format(...)
			if(name:len() > 128) then
				name = name:sub(1, 128)..'...'
			end
			Debug.info(name..' has taken '..math.floor(dt)..' ms')
		end
		
		self.ticks = getTickCount() -- get ticks again
		return true
	end
	
	if(PERF_DEBUG_EVENTS) then
		local _addEventHandler = addEventHandler
		local repeatEventHandler = {onClientRender = 10, onClientPreRender = 10}
		local g_Handlers = {}
		
		function addEventHandler(eventName, attachedTo, handlerFunction, ...)
			local trace = Debug.getStackTrace(1, 1)
			local func = function(...)
				local prof = DbgPerf()
				local cnt = repeatEventHandler[eventName] or 1
				for i = 1, cnt do
					-- Check if handler wasn't removed in this loop
					if(g_Handlers[handlerFunction]) then
						handlerFunction(...)
					end
				end
				if(prof:cp(eventName) and trace[1]) then
					Debug.info(trace[1], 3)
				end
			end
			g_Handlers[handlerFunction] = func -- what about different eventName/source
			return _addEventHandler(eventName, attachedTo, func, ...)
		end
		
		local _removeEventHandler = removeEventHandler
		function removeEventHandler(eventName, attachedTo, handlerFunction, ...)
			local func = g_Handlers[handlerFunction] or handlerFunction
			g_Handlers[handlerFunction] = nil
			return _removeEventHandler(eventName, attachedTo, func, ...)
		end
	end
else
	local function DbgDummy()
	end
	
	Debug.dump = DbgDummy
	DbgPerf = function() return {cp = DbgDummy} end
end

#local TEST = false
#if(TEST) then
	function funcA()
		Debug.printStackTrace(3)
		
		local trace = Debug.getStackTrace(2)
		assert(#trace == 2)
		assert(trace[1]:find('funcA', 1, true))
		assert(trace[2]:find('funcB', 1, true))
	end
	function funcB()
		funcA()
	end
	funcB()
#end
