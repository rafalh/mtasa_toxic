mui = {}
mui.right = AccessRight('mui') -- for client-side

local g_LocStateCache = {}
local g_MuiStringCount = false

local function checkPlayerAccess(player, code)
	return isPlayerAdmin(player) or hasObjectPermissionTo(player, 'resource.'..g_ResName..'.mui_'..code, false)
end

local function getLocaleState(code)
	local state = {}
	
	local serverMap = MuiStringMap('lang/'..code..'.xml')
	local clientMap = MuiStringMap('lang/'..code..'_c.xml')
	local tblS = serverMap:getList()
	local tblC = clientMap:getList()
	
	local map = {}
	for i, entry in ipairs(tblS) do
		map[entry.id] = 's'
	end
	for i, entry in ipairs(tblC) do
		if(map[entry.id] == 's') then
			map[entry.id] = '*'
		else
			map[entry.id] = 'c'
		end
	end
	
	state.missing = 0
	state.count = 0
	state.wrongType = 0
	for i, str, strType in MuiStringList:ipairs() do
		local curStrType = map[str]
		if(curStrType == nil) then
			state.missing = state.missing + 1
		elseif(curStrType) then
			if(curStrType ~= strType) then
				state.wrongType = state.wrongType + 1
			else
				state.count = state.count + 1
			end
			map[str] = false -- set to false if string has been counted
		end
	end
	
	state.unknown = 0
	for str, v in pairs(map) do
		if(v) then
			state.unknown = state.unknown + 1
		end
	end
	
	return state
end

function mui.getLocaleList()
	if(not mui.right:check(client)) then return false end
	
	MuiStringList:loadFromFile('strings.txt')
	
	local locales = {}
	for i, locale in LocaleList.ipairs() do
		if(locale.code ~= 'en') then
			local info = {}
			info.code = locale.code
			info.access = checkPlayerAccess(client, locale.code)
			if(not g_LocStateCache[locale.code]) then
				g_LocStateCache[locale.code] = getLocaleState(locale.code)
			end
			info.state = g_LocStateCache[locale.code]
			table.insert(locales, info)
		end
	end
	
	if(not g_MuiStringCount) then
		g_MuiStringCount = MuiStringList:count()
	end
	
	return locales, g_MuiStringCount
end
RPC.allow('mui.getLocaleList')

function mui.getLocaleData(localeCode)
	if(not LocaleList.exists(localeCode) or not checkPlayerAccess(client, localeCode)) then return end
	
	local serverMap = MuiStringMap('lang/'..localeCode..'.xml')
	local clientMap = MuiStringMap('lang/'..localeCode..'_c.xml')
	
	local validList, missingList, wrongTypeList, unknownList = {}, {}, {}, {}
	
	local map = {}
	for i, entry in ipairs(serverMap:getList()) do
		local e = table.copy(entry)
		e.t = 's'
		if(map[entry.id]) then
			Debug.warn('Duplicated key', e.id)
		else
			map[entry.id] = e
			table.insert(unknownList, e)
		end
	end
	for i, entry in ipairs(clientMap:getList()) do
		local e = map[entry.id]
		if(e and e.t == 's') then
			e.t = '*'
		elseif(e) then
			Debug.warn('Duplicated key', e.id)
		else
			e = table.copy(entry)
			e.t = 'c'
			map[entry.id] = e
			table.insert(unknownList, e)
		end
	end
	
	for i, str, strType in MuiStringList:ipairs() do
		local e = map[str]
		if(e) then
			map[str] = false
			table.removeValue(unknownList, e)
			if(e.t == strType) then
				table.insert(validList, e)
			else
				e.vt = strType
				table.insert(wrongTypeList, e)
			end
		elseif(e == nil) then
			local e = {id = str, t = strType}
			map[str] = false
			table.insert(missingList, e)
		end
	end
	
	return localeCode, validList, missingList, wrongTypeList, unknownList
end
RPC.allow('mui.getLocaleData')

function mui.setString(localeCode, id, value, strType)
	if(not LocaleList.exists(localeCode) or not checkPlayerAccess(client, localeCode)) then return end
	
	local locS = MuiStringMap('lang/'..localeCode..'.xml')
	local locC = MuiStringMap('lang/'..localeCode..'_c.xml')
	
	if(strType == 's') then
		locS:set(id, value)
		locC:remove(id)
	elseif(strType == 'c') then
		locS:remove(id)
		locC:set(id, value)
	else
		locS:set(id, value)
		locC:set(id, value)
	end
	
	g_LocStateCache[localeCode] = nil
end
RPC.allow('mui.setString')

function mui.removeString(localeCode, id)
	if(not LocaleList.exists(localeCode) or not checkPlayerAccess(client, localeCode)) then return end
	
	local locS = MuiStringMap('lang/'..localeCode..'.xml')
	local locC = MuiStringMap('lang/'..localeCode..'_c.xml')
	
	locS:remove(id)
	locC:remove(id)
	
	g_LocStateCache[localeCode] = nil
end
RPC.allow('mui.removeString')
