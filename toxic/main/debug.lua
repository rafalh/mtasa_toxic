local DEBUG = true
local PROFILE_CHECKPOINTS = true
local PROFILE_EVENT_HANDLERS = true
local PROFILE_EVENT_HANDLERS_LIMIT = 200
local REPEAT_EVENT_HANDLER = {} -- {onClientRender = 10, onClientPreRender = 10}

local debugMsgMaxLen = triggerClientEvent and 250

Debug = {}

function Debug.print(str, lvl)
	str = tostring(str)
	if debugMsgMaxLen then
		for part in str:wordWrapSplitIter(debugMsgMaxLen) do
			outputDebugString(part, lvl)
		end
	else
		outputDebugString(str, lvl)
	end
end

local function debugConcat(...)
	local tbl = { ... }
	for i, val in ipairs(tbl) do
		tbl[i] = tostring(val)
	end
	return table.concat(tbl, ' ')
end

function Debug.info(...)
	local str = debugConcat(...)
	Debug.print(str, 3)
end

function Debug.warn(...)
	local str = debugConcat(...)
	Debug.print(str, 2)
end

function Debug.err(...)
	local str = debugConcat(...)
	Debug.print(str, 1)
end

function Debug.getStackTrace(maxLen, trimTop, trimBottom)
	local trace = debug.traceback('', (trimTop or 0) + 2)
	local lines = split(trace, '\n')
	local start, stop = 2, math.min(1 + (maxLen or #lines - 1), (#lines - (trimBottom or 0)))
	
	local tbl = {}
	for i = start, stop do
		local line = trimStr(lines[i])
		table.insert(tbl, line)
	end
	
	return tbl
end

function Debug.printStackTrace(lvl, maxLen, trimTop, trimBottom)
	local trace = Debug.getStackTrace(maxLen, (trimTop or 0) + 1, trimBottom)
	for i, str in ipairs(trace) do
		Debug.print(str, lvl or 2)
	end
end

function Debug.dump(value, quote, undumpedTables)
	if not undumpedTables then
		undumpedTables = {}
	end
	if isElement(value) then
		local elType = getElementType(value)
		if elType == 'player' then
			return elType..'('..getPlayerName(value)..')'
		else
			return elType..'('..getElementID(value)..')'
		end
	elseif type(value) == 'string' then
		if value:match('[^%p%w%s]') then
			return 'bin('..Debug.dumpHex(value)..')'
		else
			local quoteMark = quote and '\'' or ''
			return quoteMark..value..quoteMark
		end
	elseif type(value) == 'table' then
		if undumpedTables[value] then
			return tostring(value)
		else
			-- make sure we don't have endless recursion
			undumpedTables[value] = true
			return Debug.dumpTbl(value, undumpedTables)
		end
	else
		return tostring(val)
	end
end

function Debug.dumpTbl(tbl, undumpedTables)
	local temp = {}
	for key, val in pairs(tbl) do
		if type(key) == 'number' and key <= #tbl then
			table.insert(temp, Debug.dump(val, true, undumpedTables))
		elseif type(key) == 'string' and key:match('^%a') then
			table.insert(temp, key..'='..Debug.dump(val, true, undumpedTables))
		else
			table.insert(temp, '['..Debug.dump(key, true, undumpedTables)..']='..Debug.dump(val, true, undumpedTables))
		end
	end
	return '{'..table.concat(temp, ', ')..'}'
end

function Debug.dumpHex(str)
	local len = str:len()
	local bytes = {str:byte(1, len)}
	local temp = {}
	for i, byte in ipairs(bytes) do
		table.insert(temp, ('%02X'):format(byte))
	end
	return table.concat(temp, ' ')
end

if DEBUG then
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
		elseif(PROFILE_CHECKPOINTS) then
			local name = fmt:format(...)
			if(name:len() > 128) then
				name = name:sub(1, 128)..'...'
			end
			Debug.info(name..' has taken '..math.floor(dt)..' ms')
		end
		
		self.ticks = getTickCount() -- get ticks again
		return true
	end

	local g_handlerWrappers = {}
	setmetatable(g_handlerWrappers, { __mode = 'v' })

	-- Note: we are using addInitFunc because addEventHandler during startup is overriden
	addInitFunc(function ()
		local _addEventHandler = addEventHandler
		function addEventHandler(eventName, attachedTo, handlerFunction, ...)
			local func = g_handlerWrappers[handlerFunction]
			if not func then
				func = function (...)
					local prof = PROFILE_EVENT_HANDLERS and DbgPerf(PROFILE_EVENT_HANDLERS_LIMIT)
					local cnt = (PROFILE_EVENT_HANDLERS and REPEAT_EVENT_HANDLER[eventName]) or 1
					local args = {...}
					for i = 1, cnt do
						-- Check if handler wasn't removed in this loop
						if g_handlerWrappers[handlerFunction] then
							xpcall(function ()
								handlerFunction(unpack(args))
							end, function (err)
								Debug.err(tostring(err))
								Debug.printStackTrace(2, 5, 3, 3)
							end)
						end
					end
					if PROFILE_EVENT_HANDLERS and prof:cp(eventName) then
						Debug.printStackTrace(3, 1, 3, 3)
					end
				end
				g_handlerWrappers[handlerFunction] = func
			end
			return _addEventHandler(eventName, attachedTo, func, ...)
		end
	end, -9999)
	
	local _removeEventHandler = removeEventHandler
	function removeEventHandler(eventName, attachedTo, handlerFunction, ...)
		local func = g_handlerWrappers[handlerFunction] or handlerFunction
		return _removeEventHandler(eventName, attachedTo, func, ...)
	end
else
	local function DbgDummy()
	end
	
	DbgPerf = function() return {cp = DbgDummy} end
end

#if(TEST) then
addInitFunc(function()
	Test.register('debug', function()
		function funcA()
			--Debug.printStackTrace(3)
			
			local trace = Debug.getStackTrace(2)
			Test.checkEq(#trace, 2)
			Test.check(trace[1]:find('funcA', 1, true))
			Test.check(trace[2]:find('funcB', 1, true))
		end
		function funcB()
			funcA()
		end
		funcB()
	end)
end)
#end
