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

function table.compare(tbl1, tbl2, deep)
	if(type(tbl1) ~= 'table' or type(tbl2) ~= 'table') then return false end
	
	for i, v in pairs(tbl1) do
		if(deep and type(tbl2[i]) == 'table' and type(v) == 'table') then
			if(not table.compare(tbl2[i], v, deep)) then return false end
		elseif(tbl2[i] ~= v) then
			return false
		end
	end
	
	for i, v in pairs(tbl2) do
		if(deep and type(tbl1[i]) == 'table' and type(v) == 'table') then
			if(not table.compare(tbl1[i], v, deep)) then return false end
		elseif(tbl1[i] ~= v) then
			return false
		end
	end
	
	return true
end

