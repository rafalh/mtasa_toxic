-- Use single big table or many small tables?
#local LIST_IN_SINGLE_TBL = false

#local ENTRY_CACHE = false

#if(LIST_IN_SINGLE_TBL) then

local function listCreate(tbl)
	local lst = {false, false}
	if(not tbl) then return lst end
	for i = 1, #tbl do
		lst[i*2 - 1] = i*2 + 1
		lst[i*2 + 2] = tbl[i]
	end
	return lst
end

local function listInsert(lst, v, hint)
	local i = hint or 1
	while(lst[i]) do
		i = lst[i]
	end
	local newIdx = #lst + 1
	lst[i] = newIdx
	lst[newIdx + 1] = v
	return newIdx
end

local function listRemove(lst, n)
	local i = 1
	while(n > 1 and lst[i]) do
		i = lst[i]
		n = n - 1
	end
	
	if(lst[i]) then
		local nextIdx = lst[i]
		local v = lst[nextIdx + 1]
		lst[i] = lst[nextIdx]
		--lst[nextIdx] = nil
		--lst[nextIdx + 1] = nil
		return v
	end
end

local function listGetSize(lst)
	local i, size = 1, 0
	while(lst[i]) do
		i = lst[i]
		size = size + 1
	end
	return size
end

local function listIsEmpty(lst)
	return not lst[1]
end

#else -- LIST_IN_SINGLE_TBL

#local VAL = 1
#local NEXT = 2

#if(ENTRY_CACHE) then
	local g_ListEntryCache = {}
#end

local function listCreate(tbl)
	local head = {}
	if(not tbl) then return head end
	local entry = head
	for i = 1, #tbl do
#if(ENTRY_CACHE) then
		local newEntry = table.remove(g_ListEntryCache)
		if(newEntry) then
			newEntry[$VAL], newEntry[$NEXT] = tbl[i], false
		else
			newEntry = {tbl[i], false}
		end
#else
		local newEntry = {tbl[i], false}
#end
		entry[$NEXT] = newEntry
		entry = newEntry
	end
	return head
end

local function listInsert(head, v, hint)
	local entry = hint or head
	while(entry[$NEXT]) do
		entry = entry[$NEXT]
	end
	entry[$NEXT] = {v, false}
	return entry[$NEXT]
end

local function listRemove(head, n)
	local entry = head
	while(n > 1 and entry) do
		entry = entry[$NEXT]
		n = n - 1
	end
	
	if(entry and entry[$NEXT]) then
		local v = entry[$NEXT][$VAL]
#if(ENTRY_CACHE) then
		table.insert(g_ListEntryCache, entry[$NEXT])
#end
		entry[$NEXT] = entry[$NEXT][$NEXT]
		return v
	end
end

local function listGetSize(head)
	local entry = head
	local size = 0
	while(entry[$NEXT]) do
		size = size + 1
		entry = entry[$NEXT]
	end
	return size
end

local function listIsEmpty(head)
	return not head[$NEXT]
end

#end

#local TEST = true
#if(TEST) then
#	print('List test is active!')
	local function test(val1, val2, ln)
		if(val1 == val2) then return end
		print('Test failed: '..tostring(val1)..'<>'..tostring(val2)..' (line '..ln..')')
		os.exit(-1)
	end
	local l = listCreate{1, 2, 3, 4}
	test(listGetSize(l), 4, $__LINE__)
	test(listRemove(l, 1), 1, $__LINE__)
	test(listGetSize(l), 3, $__LINE__)
	test(listRemove(l, 2), 3, $__LINE__)
	test(listGetSize(l), 2, $__LINE__)
	test(listIsEmpty(l), false, $__LINE__)
	test(listRemove(l, 1), 2, $__LINE__)
	test(listRemove(l, 1), 4, $__LINE__)
	test(listIsEmpty(l), true, $__LINE__)
#end
