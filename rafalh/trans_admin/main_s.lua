addEvent("main.onTransPanelReq", true)
addEvent("main.onLocaleDataReq", true)
addEvent("main.onChangeLocaleReq", true)

local function checkPlayerAccess(player, code)
	return isPlayerAdmin(player) or hasObjectPermissionTo(player, "resource.rafalh.translate_"..code, false)
	
end

local function onTransPanelReq()
	local langCodes = {}
	for i, locale in LocaleList.ipairs() do
		if(locale.code ~= "en" and checkPlayerAccess(client, locale.code)) then
			table.insert(langCodes, locale.code)
		end
	end
	
	if(#langCodes > 0) then
		triggerClientEvent(client, "main.openTransPanel", g_ResRoot, langCodes)
	end
end

local function loadLocaleFile(path)
	local node = xmlLoadFile(path)
	if(not node) then return false end
	
	local tbl = {}
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local entry = {}
		entry.id = xmlNodeGetAttribute(subnode, "id")
		if(not entry.id) then
			entry.id = xmlNodeGetAttribute(subnode, "pattern")
			entry.pattern = true
		end
		entry.val = xmlNodeGetValue(subnode)
		if(entry.id and entry.val) then
			table.insert(tbl, entry)
		end
	end
	
	xmlUnloadFile(node)
	return tbl
end

local function onLocaleDataReq(localeCode)
	if(not LocaleList.exists(localeCode) or not checkPlayerAccess(client, localeCode)) then return end
	local tblS = loadLocaleFile("lang/"..localeCode..".xml")
	local tblC = loadLocaleFile("lang/"..localeCode.."_c.xml")
	triggerClientEvent(client, "main.onLocaleData", g_ResRoot, localeCode, tblS, tblC)
end

local function onChangeLocaleReq(localeCode, entry, oldId, clientSide)
	if(not LocaleList.exists(localeCode) or not checkPlayerAccess(client, localeCode)) then return end
	if(entry and ((entry.id or "") == "" or (entry.val or "") == "")) then return end
	
	local path = "lang/"..localeCode..(clientSide and "_c" or "")..".xml"
	local node = xmlLoadFile(path)
	if(not node) then return false end
	
	local isPattern = false
	
	local subnode
	if(oldId) then
		for i, curSubnode in ipairs(xmlNodeGetChildren(node)) do
			local id = xmlNodeGetAttribute(curSubnode, "id")
			local pattern = xmlNodeGetAttribute(curSubnode, "pattern")
			if(id == oldId or pattern == oldId) then
				subnode = curSubnode
				isPattern = pattern and true
				break
			end
		end
	else
		subnode = xmlCreateChild(node, "msg")
		isPattern = entry.pattern
	end
	
	if(subnode) then
		if(entry) then
			if(isPattern) then
				xmlNodeSetAttribute(subnode, "pattern", entry.id)
			else
				xmlNodeSetAttribute(subnode, "id", entry.id)
			end
			xmlNodeSetValue(subnode, entry.val)
		else
			xmlDestroyNode(subnode)
		end
		xmlSaveFile(node)
	end
	xmlUnloadFile(node)
end

addInitFunc(function()
	addEventHandler("main.onTransPanelReq", g_ResRoot, onTransPanelReq)
	addEventHandler("main.onLocaleDataReq", g_ResRoot, onLocaleDataReq)
	addEventHandler("main.onChangeLocaleReq", g_ResRoot, onChangeLocaleReq)
end)
