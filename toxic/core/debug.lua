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

function Debug.traceBack(lvl, len, offset)
	local trace = debug.traceback()
	trace = trace:gsub('\r', '')
	local lines = split(trace, '\n')
	local start = 3 + (offset or 0)
	local stop = #lines
	if(len) then
		stop = math.min(stop, start+len-1)
	end
	local tbl = {}
	for i = start, stop do
		local line = trimStr(lines[i])
		table.insert(tbl, line)
		if(lvl ~= -1) then
			outputDebugString(line, lvl or 2)
		end
	end
	
	return tbl
end

local _assert = assert
function assert(val, str)
	if(not val) then
		Debug.traceBack()
		_assert(val, str)
	end
end

local _addEventHandler = addEventHandler
function addEventHandler(...)
	local success = _addEventHandler(...)
	if(not success) then
		Debug.warn(debug.traceback('addEventHandler failed', 2), 2)
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
			Debug.info(name..' has taken '..dt..' ms')
		end
		
		self.ticks = getTickCount() -- get ticks again
		return true
	end
	
	if(PERF_DEBUG_EVENTS) then
		local _addEventHandler = addEventHandler
		local repeatEventHandler = {onClientRender = 10, onClientPreRender = 10}
		local g_Handlers = {}
		
		function addEventHandler(eventName, attachedTo, handlerFunction, ...)
			local trace = Debug.traceBack(-1, 1, 1)
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
