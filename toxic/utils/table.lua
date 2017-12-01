function table.size(t)
	local n = 0
	
	for i, v in pairs(t) do
		n = n + 1
	end
	
	return n
end

function table.empty(tbl)
	return (next(tbl) == nil)
end

function table.find(tbl, v)
	for i, val in ipairs(tbl) do
		if(val == v) then
			return i
		end
	end
	
	return false
end

function table.keys(tbl)
	local ret = {}
	for k, v in pairs(tbl) do
		table.insert(ret, k)
	end
	return ret
end

function table.values(tbl)
	local ret = {}
	for k, v in pairs(tbl) do
		table.insert(ret, v)
	end
	return ret
end

function table.copy(tbl, full)
	local ret = {}
	for k, v in pairs(tbl) do
		if(type(v) == 'table' and full) then
			ret[k] = table.copy(v)
		else
			ret[k] = v
		end
	end
	setmetatable(ret, getmetatable(tbl))
	return ret
end

function table.removeValue(tbl, v)
	local i = table.find(tbl, v)
	if(i) then
		table.remove(tbl, i)
	end
end

function table.merge(tbl1, tbl2, _subst)
	-- Needed to fix overflow for tables with recursion
	if(not _subst) then
		_subst = {}
	end
	
	local ret = {}
	
	_subst[tbl1] = ret
	_subst[tbl2] = ret
	
	for k, v in pairs(tbl1) do
		ret[k] = v
		if(_subst[v]) then
			ret[k] = _subst[v]
		end
	end
	for k, v in pairs(tbl2) do
		if(_subst[v]) then
			ret[k] = _subst[v]
		elseif(type(v) == 'table' and type(ret[k]) == 'table') then
			ret[k] = table.merge(ret[k], v, _subst)
		else
			ret[k] = v
		end
	end
	
	_subst[tbl1] = nil
	_subst[tbl2] = nil
	
	return ret
end

function table.set(tbl, data)
	for k, v in pairs(data) do
		tbl[k] = v
	end
end

function table.dump(tbl, _stack)
	-- Stack is needed to fix overflow for tables with recursion
	if(not _stack) then
		_stack = {}
	end
	table.insert(_stack, tbl)
	
	local values = {}
	for k, v in pairs(tbl) do
		if(type(v) == 'table' and not table.find(_stack, v)) then
			v = table.dump(v, _stack)
		end
		table.insert(values, '['..tostring(k)..'] = '..tostring(v))
	end
	table.remove(_stack)
	return '{'..table.concat(values, ', ')..'}'
end

function table.foreach(tbl, fn)
	for k, v in pairs(tbl) do
		fn(v)
	end
end

function table.insertMultiple(tbl, pos, val, count)
	for i = 1, count do
		table.insert(tbl, pos, val)
		pos = pos + 1
	end
end

function table.removeMultiple(tbl, pos, count)
	--assert(pos + count <= #tbl + 1)
	for i = 1, count do
		table.remove(tbl, pos)
	end
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

function table.fromIter(iter)
	local tbl = {}
	for val in iter do
		table.insert(tbl, val)
	end
	return tbl
end
