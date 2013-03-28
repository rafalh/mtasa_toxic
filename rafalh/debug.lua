local DEBUG = true
local PERF_DEBUG = false
local g_DbgPerfData = {}

if(DEBUG) then
	function DbgPrint(fmt, ...)
		outputDebugString(fmt:format ( ... ), 3)
	end
	
	function DbgDump(str, title)
		local len = str:len()
		local bytes = {str:byte(1, len)}
		local buf = ""
		for i, byte in ipairs(bytes) do
			buf = buf..(" %02X"):format (byte)
		end
		DbgPrint((title or "dump")..":"..buf)
	end
	
	function DbgPerfInit(channel)
		g_DbgPerfData[channel or 1] = getTickCount()
	end
	
	function DbgPerfCp(title, channel, ...)
		local ticks = getTickCount()
		if(PERF_DEBUG) then
			local dt = ticks - g_DbgPerfData[channel or 1]
			g_DbgPerfData[channel or 1] = ticks
			if(dt > 10) then
				local args = {...}
				args[#args + 1] = dt
				DbgPrint(title.." has taken %u ms", unpack(args))
				return true
			end
		end
		return false
	end
	
function DbgTraceBack(lvl, len, offset, ret)
	local trace = debug.traceback()
	trace = trace:gsub("\r", "")
	local lines = split(trace, "\n")
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
	
	if(PERF_DEBUG) then
		local _addEventHandler = addEventHandler
		local repeatEventHandler = {onClientRender = 10, onClientPreRender = 10}
		local g_Handlers = {}
		
		function addEventHandler(eventName, attachedTo, handlerFunction, ...)
			local trace = DbgTraceBack(-1, 1, 1)
			local func = function(...)
				DbgPerfInit()
				local cnt = repeatEventHandler[eventName] or 1
				for i = 1, cnt do
					if(g_Handlers[handlerFunction]) then
						handlerFunction(...)
					end
				end
				if(DbgPerfCp(eventName) and trace[1]) then
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
	DbgPerfInit = DbgDummy
	DbgPerfCp = DbgDummy
end

#if(false) then -- perf debug
local g_Handlers = {}

local _addEventHandler = addEventHandler
function addEventHandler ( eventName, attachedTo, handlerFunction, ... )
	local trace = ""--debug.traceback ()
	if ( not g_Handlers[handlerFunction] ) then
		g_Handlers[handlerFunction] = function ( ... )
			local start = getTickCount ()
			handlerFunction ( ... )
			local dt = getTickCount () - start
			if ( dt > 16 ) then
				outputDebugString ( eventName.." handler is too slow: "..dt.." "..trace, 2 )
			end
		end
	end
	_addEventHandler ( eventName, attachedTo, g_Handlers[handlerFunction], ... )
end

local _removeEventHandler = removeEventHandler
function removeEventHandler ( eventName, attachedTo, functionVar )
	if ( g_Handlers[functionVar] ) then
		functionVar = g_Handlers[functionVar]
		g_Handlers[functionVar] = nil
	end
	_removeEventHandler ( eventName, attachedTo, functionVar )
end
#end
