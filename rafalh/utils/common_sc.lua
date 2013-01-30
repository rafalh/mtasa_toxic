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

local _assert = assert
function assert ( val, str )
	if ( not val ) then
		DbgTraceBack ()
		_assert ( val, str )
	end
end

function ifElse ( condition, trueReturn, falseReturn )
	if ( condition ) then
		return trueReturn
	end
	return falseReturn
end

function toint ( var, nan_r )
	local r = var and tonumber ( var )
	return ( r and r < math.huge and r > -math.huge and math.floor ( r ) ) or nan_r  -- nan ~= nan
end

function touint ( var, nan_r )
	local r = var and tonumber ( var )
	return ( r and r < math.huge and r > -math.huge and r >= 0 and math.floor ( r ) ) or nan_r -- nan ~= nan
end

function tofloat ( var, nan_r )
	local r = var and tonumber ( var )
	return ( r and r < math.huge and r > -math.huge and r ) or nan_r -- nan ~= nan
end

function tonum ( var )
	return ( var and tonumber ( var ) ) or 0
end

function tostr ( var )
	return ( var and tostring ( var ) ) or ""
end

function table.size ( t )
	local n = 0
	
	for i, v in pairs ( t ) do
		n = n + 1
	end
	
	return n
end

function table.empty ( t )
	for i, v in pairs ( t ) do
		return false
	end
	
	return true
end

function table.find ( t, v )
	for i, val in ipairs ( t ) do
		if ( val == v ) then
			return i
		end
	end
	
	return false
end

function table.copy(tbl, full)
	local ret = {}
	for k, v in pairs(tbl) do
		if(type(v) == "table" and full) then
			ret[k] = table.copy(v)
		else
			ret[k] = v
		end
	end
	return ret
end

function formatTimePeriod(t, decimals)
	assert(t)
	local dec = touint(decimals, 2)
	local h = math.floor(t / 3600)
	local m = math.floor((t % 3600) / 60)
	local s = t % 60
	
	return (( h > 0 and h..":" ) or "")..( "%"..( ( h > 0 and "02" ) or "" ).."u:%0"..( 2 + ( ( dec > 0 and dec + 1 ) or 0 ) ).."."..dec.."f"):format(m, s)
end

function formatNumber ( num, decimals )
	num = tonumber ( num )
	assert ( num )
	local n1, n2 = math.modf ( num )
	n1 = tostring ( n1 )
	local buf = ""
	
	while ( n1 ~= "" ) do
		buf = n1:sub ( -3 ).." "..buf
		n1 = n1:sub ( 1, -4 )
	end
	buf = buf:sub ( 1, -2 )
	if ( decimals ) then
		return buf.."."..( n2..( "0" ):rep ( decimals ) ):sub ( 1, decimals )
	end
	return buf
end

function formatMoney ( money )
	assert ( money )
	local str = tostring ( math.floor ( math.abs ( money ) ) )
	local buf = ""
	
	while ( str ~= "" ) do
		buf = str:sub ( -3 )..","..buf
		str = str:sub ( 1, -4 )
	end
	return ( ( tonumber ( money ) < 0 and "-" ) or "" )..buf:sub ( 1, -2 ).." €"
end

local _isPedDead = isPedDead
function isPedDead ( player )
	if ( g_Players and g_Players[player] and g_Players[player].is_console ) then
		return false -- console
	end
	local state = getElementData ( player, "state" )
	if ( state and state ~= "alive" ) then
		return true
	end
	return ( state and state ~= "alive" ) or _isPedDead ( player )
end

#if ( false ) then -- perf debug
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
