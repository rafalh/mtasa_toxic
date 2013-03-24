
#include "include/internal_events.lua"

g_ProfileFields = {}
local g_ProfileCats = {}

addEvent("main_onPlayerProfileReq", true)

local function PfSyncCallback(id)
	if(not id) then return {} end -- guest
	
	id = touint(id)
	if (not id) then
		outputDebugString("Wrong id", 2)
		return false
	end
	
	local rows = DbQuery("SELECT field, value FROM rafalh_profiles WHERE player=?", id)
	local ret = {}
	for i, data in ipairs(rows) do
		ret[data.field] = data.value
	end
	
	ret.email = PlayerAccountData.create(id):get("email")
	
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

local function PfLoadFields()
	local node, i = xmlLoadFile("conf/profile_fields.xml"), 0
	if(not node) then return false end
	while(true) do
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
	return true
end

-- HTTP Export
function getPlayerProfile ( player_id )
	-- Validate parameters
	player_id = touint ( player_id )
	if ( not player_id ) then
		return false
	end
	
	-- Query database
	local rows = DbQuery ( "SELECT * FROM rafalh_profiles WHERE player=?", player_id )
	if ( rows ) then
		local result = {}
		
		for i, data in ipairs ( rows ) do
			local prof_field = g_ProfileFields[data.field]
			if ( prof_field ) then
				result[prof_field.longname] = data.value
			end
		end
		
		return result
	end
	
	return false
end

function setPlayerProfile(id, data)
	if(not id) then return end
	
	for field, value in pairs(data) do
		local fieldInfo = g_ProfileFields[field]
		if(fieldInfo) then
			value = tostring(value or "")
			if(value == "") then
				-- empty field - ok
			elseif(fieldInfo.type == "num") then
				value = value:match("^%d+%.?%d?%d?$") and tofloat(value)
			elseif(fieldInfo.type == "int") then
				value = value:match("^%d+$") and toint(value)
			elseif(fieldInfo.type == "email") then
				value = value:match("^[%w%._-]+@[%w_-]+%.[%w%._-]+$") and value
			else
				value = value:sub(1, 128)
			end
			data[field] = value
			if(value) then
				if(field == "email") then
					PlayerAccountData.create(id):set("email", value)
				else
					DbQuery("DELETE FROM rafalh_profiles WHERE player=? AND field=?", id, field)
					if(value ~= "") then
						DbQuery("INSERT INTO rafalh_profiles (player, field, value) VALUES(?, ?, ?)", id, field, value)
					end
				end
			end
		else
			data[field] = nil
		end
	end
	
	notifySyncerChange("profile", id, data)
	return data
end

local function PfOnGetProfileReq(id)
	local data = getPlayerProfile(id)
	triggerClientEvent(client, "main_onPlayerProfile", g_ResRoot, id, data)
end

local function PfOnSetProfileRequest(data)
	local pdata = Player.fromEl(client)
	if(data and type(data) == "table" and pdata.id) then
		setPlayerProfile(pdata.id, data)
	end
end

local function PfInit()
	PfLoadFields()
	
	addSyncer("profile", PfSyncCallback)
	addSyncer("profile_fields", PfFieldsSyncCallback)
	
	addInternalEventHandler($(EV_SET_PROFILE_REQUEST), PfOnSetProfileRequest)
	addEventHandler("main_onPlayerProfileReq", g_ResRoot, PfOnGetProfileReq)
end

addInitFunc(PfInit)
