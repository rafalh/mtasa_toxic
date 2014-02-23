g_ProfileFields = {}
local g_ProfileCats = {}

ProfilesTable = Database.Table{
	name = 'profiles',
	{'player', 'INT UNSIGNED', fk = {'players', 'player'}},
	{'field', 'VARCHAR(64)'},
	{'value', 'VARCHAR(255)'},
}

local function PfLoadCat(node, cat)
	local i = 0
	while (true) do
		local subnode = xmlFindChild(node, 'field', i)
		if(not subnode) then break end
		i = i + 1
		
		local data = {}
		data.name = xmlNodeGetAttribute(subnode, 'name')
		assert(data.name)
		data.longname = xmlNodeGetAttribute(subnode, 'longname') or data.name
		data.type = xmlNodeGetAttribute(subnode, 'type') or 'str'
		data.w = tonumber(xmlNodeGetAttribute(subnode, 'w'))
		
		g_ProfileFields[data.name] = data
		table.insert(cat, data)
	end
end

local function PfLoadFields()
	local node, i = xmlLoadFile('conf/profile_fields.xml'), 0
	if(not node) then return false end
	while(true) do
		local subnode = xmlFindChild(node, 'cat', i)
		if(not subnode) then break end
		i = i + 1
		
		local cat = {}
		cat.name = xmlNodeGetAttribute(subnode, 'name')
		if(cat.name) then
			PfLoadCat(subnode, cat)
			table.insert(g_ProfileCats, cat)
		end
	end
	xmlUnloadFile(node)
	return true
end

RPC.allow('getPlayerProfile')
function getPlayerProfile(playerId)
	-- Validate parameters
	playerId = touint(playerId)
	if(not playerId) then
		Debug.warn('Wrong id')
		return false
	end
	
	-- Query database
	local rows = DbQuery('SELECT * FROM '..ProfilesTable..' WHERE player=?', playerId)
	if(not rows) then return false end
	
	local result = {}
	for i, data in ipairs(rows) do
		local fieldInfo = g_ProfileFields[data.field]
		if(fieldInfo) then
			result[fieldInfo.longname] = data.value
		end
	end
	
	return result
end

RPC.allow('getProfileFields')
function getProfileFields()
	return g_ProfileCats
end

function setPlayerProfile(id, data)
	if(not id) then return end
	
	for field, value in pairs(data) do
		local fieldInfo = g_ProfileFields[field]
		if(fieldInfo) then
			value = tostring(value or '')
			if(value == '') then
				-- empty field - ok
			elseif(fieldInfo.type == 'num') then
				value = value:match('^%d+%.?%d?%d?$') and tofloat(value)
			elseif(fieldInfo.type == 'int') then
				value = value:match('^%d+$') and toint(value)
			else
				value = value:sub(1, 128)
			end
			data[field] = value
			if(value) then
				DbQuery('DELETE FROM '..ProfilesTable..' WHERE player=? AND field=?', id, field)
				if(value ~= '') then
					DbQuery('INSERT INTO '..ProfilesTable..' (player, field, value) VALUES(?, ?, ?)', id, field, value)
				end
			end
		else
			data[field] = nil
		end
	end
	
	return data
end

RPC.allow('setProfileReq')
function setProfileReq(data)
	local pdata = Player.fromEl(client)
	if(data and type(data) == 'table' and pdata.id) then
		setPlayerProfile(pdata.id, data)
	end
end

local function PfInit()
	PfLoadFields()
end

addInitFunc(PfInit)
