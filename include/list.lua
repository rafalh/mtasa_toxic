-- Include Guard
--#if(includeGuard()) then return end

-- Use single big table or many small tables?
#local LIST_IN_SINGLE_TBL = false

#local ENTRY_CACHE = false
#local LAST_REF = true

#if(LIST_IN_SINGLE_TBL) then

#local FIRST = 1
#local LAST = 2

local function listCreate(tbl)
	local lst = {false, false}
	if(not tbl) then return lst end
	for i = 1, #tbl do
		lst[i*2 - 1] = i*2 + 1
		lst[i*2 + 2] = tbl[i]
	end
#if(LAST_REF) then
	lst[$LAST] = #tbl*2 + 1
#end
	return lst
end

local function listInsert(lst, v, hint)
#if(LAST_REF) then
	local i = hint or lst[$LAST] or 1
#else
	local i = hint or 1
#end
	while(lst[i]) do
		i = lst[i]
	end
	local newIdx = #lst + 1
	lst[i] = newIdx
	lst[newIdx + 1] = v
#if(LAST_REF) then
	lst[$LAST] = newIdx
#end
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
#if(LAST_REF) then
		if(not lst[nextIdx]) then
			lst[$LAST] = i
		end
#end
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

#local LAST = VAL
#local FIRST = NEXT

#if(ENTRY_CACHE) then
	local g_ListEntryCache = {}
#end

local function listCreate(tbl)
	local head = {false, false}
	if(not tbl) then return head end
	local entry = head
	local newEntry
	for i = 1, #tbl do
#if(ENTRY_CACHE) then
		newEntry = table.remove(g_ListEntryCache)
		if(newEntry) then
			newEntry[$VAL], newEntry[$NEXT] = tbl[i], false
		else
			newEntry = {tbl[i], false}
		end
#else
		newEntry = {tbl[i], false}
#end
		entry[$NEXT] = newEntry
		entry = newEntry
	end
#if(LAST_REF) then
	head[$LAST] = newEntry
#end
	return head
end

local function listInsert(head, v, hint)
#if(LAST_REF) then
	local entry = hint or head[$LAST] or head
#else
	local entry = hint or head
#end
	while(entry[$NEXT]) do
		entry = entry[$NEXT]
	end
	local newEntry = {v, false}
	entry[$NEXT] = newEntry
#if(LAST_REF) then
	head[$LAST] = newEntry
#end
	return newEntry
end

local function listRemove(head, n)
	local entry = head
	while(n > 1 and entry) do
		entry = entry[$NEXT]
		n = n - 1
	end
	
	local nextEntry = entry[$NEXT]
	if(entry and nextEntry) then
		local v = nextEntry[$VAL]
#if(LAST_REF) then
		if(not nextEntry[$NEXT]) then
			head[$LAST] = entry
		end
#end
#if(ENTRY_CACHE) then
		table.insert(g_ListEntryCache, nextEntry)
#end
		entry[$NEXT] = nextEntry[$NEXT]
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

#local TEST = false
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
