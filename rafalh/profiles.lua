
#include "include/internal_events.lua"

g_ProfileFields = {}
local g_ProfileCats = {}

local function PfSyncCallback(id)
	id = touint(id)
	if (not id) then
		outputDebugScript("Wrong id", 2)
		return false
	end
	
	local rows = DbQuery("SELECT field, value FROM rafalh_profiles WHERE player=?", id)
	local ret = {}
	for i, data in ipairs(rows) do
		ret[data.field] = data.value
	end
	
	return ret
end

local function PfFieldsSyncCallback()
	return g_ProfileCats
end

local function PfLoadCat(node, cat)
	local i = 0
	while (true) do
			local subnode = xmlFindChild(node, "field", i)
			if(not subnode) then break end
			i = i + 1
			
			local data = {}
			data.name = xmlNodeGetAttribute(subnode, "name")
			assert(data.name)
			data.longname = xmlNodeGetAttribute(subnode, "longname") or data.name
			data.type = xmlNodeGetAttribute(subnode, "type") or "str"
			data.w = tonumber(xmlNodeGetAttribute(subnode, "w"))
			
			g_ProfileFields[data.name] = data
			table.insert(cat, data)
	end
end

local function PfInit()
	local node, i = xmlLoadFile("conf/profile_fields.xml"), 0
	if(node) then
		while (true) do
			local subnode = xmlFindChild(node, "cat", i)
			if(not subnode) then break end
			i = i + 1
			
			local cat = {}
			cat.name = xmlNodeGetAttribute(subnode, "name")
			if(cat.name) then
				PfLoadCat(subnode, cat)
				table.insert(g_ProfileCats, cat)
			end
		end
		xmlUnloadFile(node)
	end
	
	addSyncer("profile", PfSyncCallback)
	addSyncer("profile_fields", PfFieldsSyncCallback)
end

function setPlayerProfile(id, data)
	for field, value in pairs(data) do
		local fieldInfo = g_ProfileFields[field]
		if(fieldInfo) then
			if(fieldInfo.type == "num") then
				value = value:match("^%d+%.?%d?%d?$") and tofloat(value)
			elseif(fieldInfo.type == "int") then
				value = value:match("^%d+$") and toint(value)
			else
				value = tostring(value):sub(1, 128)
			end
			data[field] = value
			if(value) then
				DbQuery("DELETE FROM rafalh_profiles WHERE player=? AND field=?", id, field)
				DbQuery("INSERT INTO rafalh_profiles (player, field, value) VALUES(?, ?, ?)", id, field, value)
			end
		else
			data[field] = nil
		end
	end
	
	notifySyncerChange("profile", id, data)
	return data
end

local function PfOnSetProfileRequest(data)
	if(data and type(data) == "table") then
		setPlayerProfile(g_Players[client].id, data)
	end
end

addEventHandler ("onResourceStart", g_ResRoot, PfInit)
addInternalEventHandler($(EV_SET_PROFILE_REQUEST), PfOnSetProfileRequest)
