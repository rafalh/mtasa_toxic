local DEBUG = true
local PERF_DEBUG_CHECKPOINTS = true
local PERF_DEBUG_EVENTS = false

function DbgTraceBack(lvl, len, offset)
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
		table.insert(tbl, lines[i])
		if(lvl ~= -1) then
			outputDebugString(lines[i], lvl or 2)
		end
	end
	
	return tbl
end

local _assert = assert
function assert(val, str)
	if(not val) then
		DbgTraceBack()
		_assert(val, str)
	end
end

if(DEBUG) then
	function DbgPrint(fmt, ...)
		outputDebugString(fmt:format ( ... ), 3)
	end
	
	function DbgDump(str, title)
		local len = str:len()
		local bytes = {str:byte(1, len)}
		local buf = ''
		for i, byte in ipairs(bytes) do
			buf = buf..(' %02X'):format (byte)
		end
		DbgPrint((title or 'dump')..':'..buf)
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
			local args = {...}
			table.insert(args, dt)
			DbgPrint(fmt..' has taken %u ms', unpack(args))
		end
		
		self.ticks = getTickCount() -- get ticks again
		return true
	end
	
	if(PERF_DEBUG_EVENTS) then
		local _addEventHandler = addEventHandler
		local repeatEventHandler = {onClientRender = 10, onClientPreRender = 10}
		local g_Handlers = {}
		
		function addEventHandler(eventName, attachedTo, handlerFunction, ...)
			local trace = DbgTraceBack(-1, 1, 1)
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
					outputDebugString(trace[1], 3)
				end
			end
			g_Handlers[handlerFunction] = func -- what about different eventName/source
			_addEventHandler(eventName, attachedTo, func, ...)
		end
		
		local _removeEventHandler = removeEventHandler
		function removeEventHandler(eventName, attachedTo, handlerFunction, ...)
			local func = g_Handlers[handlerFunction] or handlerFunction
			g_Handlers[handlerFunction] = nil
			_removeEventHandler(eventName, attachedTo, func, ...)
		end
	end
else
	local function DbgDummy()
	end
	
	DbgPrint = DbgDummy
	DbgDump = DbgDummy
	DbgPerf = function() return {cp = DbgDummy} end
end