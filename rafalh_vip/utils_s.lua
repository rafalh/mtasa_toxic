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

function formatDateTime(timestamp)
	local tm = getRealTime(timestamp)
	return ("%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute)
end

function isPlayer(val)
	return isElement(val) and (getElementType(val) == 'player' or getElementType(val) == 'console')
end

function urlEncode(str)
	return str:gsub('[^%w%.%-_ ]', function(ch)
		return ('%%%02X'):format(ch:byte())
	end):gsub(' ', '+')
end
