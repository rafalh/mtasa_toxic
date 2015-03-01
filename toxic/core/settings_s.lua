Settings = {}
Settings.__mt = {}
Settings.items = {}

function Settings.register(item)
	assert(item.name and item.default and item.type)
	item.priv = true
	item.type = item.type:upper()
	Settings.items[item.name] = item
end

local function validateInt(val, min, max)
	val = toint(val)
	if(not val or val < min or val > max) then return nil
	else return val end
end

function Settings.registerMetaSetting(attr)
	if(not attr.name) then return end
	
	local ch1 = attr.name:sub(1, 1)
	if(ch1 == '*' or ch1 == '@') then
		attr.name = attr.name:sub(2)
	end
	
	if(Settings.items[attr.name]) then
		Debug.warn('Ignoring meta setting '..attr.name)
		return
	end
	
	local item = {}
	item.name = attr.name
	if(attr.accept) then
		local min, max = attr.accept:match('^(%d+)%-(%d+)$')
		if(min and max) then
			item.validate = validateInt
			item.valArgs = {tonumber(min), tonumber(max)}
		elseif(attr.accept == 'true,false' or attr.accept == 'false,true') then
			item.validate = tobool
			item.valArgs = {}
		else
			item.validate = tostring
			item.valArgs = {}
		end
	end
	
	item.client = (attr.type == 'client' or attr.type == 'shared')
	item.default = attr.value
	if(item.validate) then
		item.default = item.validate(item.default, unpack(item.valArgs))
	end
	
	Settings.items[item.name] = item
end

function Settings.loadMeta()
	local node = xmlLoadFile('meta.xml')
	if(not node) then return false end
	
	local settingsNode = xmlFindChild(node, 'settings', 0)
	if(not settingsNode) then
		xmlUnloadFile(node)
		return false
	end
	
	for i, subnode in ipairs(xmlNodeGetChildren(settingsNode)) do
		local attr = xmlNodeGetAttributes(subnode)
		Settings.registerMetaSetting(attr)
	end
	
	xmlUnloadFile(node)
	return true
end

function Settings.createDbTbl()
	local fields, defValues = {}, {}
	
	SettingsTable = Database.Table{
		name = 'settings',
	}
	
	for key, item in pairs(Settings.items) do
		if(item.priv) then
			SettingsTable:addColumns{
				{item.name, item.type, default = item.default},
			}
		end
	end
	
	return Database.createTable(SettingsTable)
end

function Settings.loadPrivate()
	if(not DbIsReady()) then
		Debug.warn('Database is not ready yet')
		return false
	end
	
	local rows = DbQuery('SELECT * FROM '..SettingsTable..' LIMIT 1')
	if(not rows[1]) then
		SettingsTable:insertDefault()
		rows = DbQuery('SELECT * FROM '..SettingsTable..' LIMIT 1')
	end
	for key, val in pairs(rows[1]) do
		local item = Settings.items[key]
		if(item) then
			if(item.type == 'BOOL' or item.type == 'BOOLEAN') then
				item.validate = tobool
				item.valArgs = {}
				val = tobool(val)
			elseif(item.type == 'INT' or item.type == 'INTEGER') then
				item.validate = toint
				item.valArgs = {}
			end
			item.value = val
		end
	end
	
	return true
end

function Settings.getClient()
	local ret = {}
	for name, item in pairs(Settings.items) do
		if(item.client) then
			ret[name] = Settings[name]
		end
	end
	return ret
end

Settings.__mt.__index = function(self, key)
	local v = rawget(self, key)
	if(v) then return v end
	
	local item = rawget(Settings, 'items')[key]
	if(not item) then
		Debug.warn('Unknown setting '..tostring(key))
		return nil
	end
	
	if(item.value ~= nil) then
		-- Already in cache
		return item.value
	end
	
	item.value = get(key)
	if(item.validate) then
		item.value = item.validate(item.value, unpack(item.valArgs))
	end
	if(item.value == nil) then
		Debug.warn('Invalid setting value: '..key)
		item.value = item.default
	end
	
	return item.value
end

function Settings.__mt.__newindex(self, key, val)
	local item = Settings.items[key]
	if(not item) then
		Debug.warn('Unknown setting '..tostring(key))
		return
	end
	
	local newVal = val
	if(item.validate) then
		newVal = item.validate(val, unpack(item.valArgs))
	end
	if(newVal == nil) then
		Debug.warn('Invalid setting value '..tostring(newVal))
		return
	end
	
	local oldVal = Settings[key]
	if(newVal ~= oldVal) then
		item.value = newVal
		if(item.priv) then
			local sqlVal = newVal
			if(type(sqlVal) == 'boolean') then
				sqlVal = sqlVal and 1 or 0
			end
			DbQuery('UPDATE '..SettingsTable..' SET '..key..'=?', sqlVal)
		else
			set(key, newVal)
		end
		
		if(item.onChange) then
			item.onChange(oldVal, newVal)
		end
	end
end

function Settings.init()
	local success = Settings.loadMeta() and Settings.createDbTbl() and Settings.loadPrivate()
	if(not success) then return false end
	return true
end

function Settings.onChange(name, oldVal, newVal)
	local startTicks = getTickCount()
	
	local ch1 = name:sub(1, 1)
	if(ch1 == '*' or ch1 == '@') then
		name = name:sub(2)
	end
	
	-- Check if this is current resource setting
	if(name:sub(1, g_ResName:len () + 1) ~= g_ResName..'.') then return end
	name = name:sub(g_ResName:len() + 2)
	
	local item = Settings.items[name]
	if(not item or item.priv) then
		Debug.warn('Unknown setting '..name)
		return
	end
	
	newVal = fromJSON(newVal) or newVal
	if(item.validate) then
		newVal = item.validate(newVal, unpack(item.valArgs))
	end
	
	if(newVal == nil) then
		Debug.warn('Invalid setting value '..name)
		cancelEvent()
		return
	end
	
	if(item.value ~= nil) then
		oldVal = item.value
	else
		oldVal = fromJSON(oldVal) or oldVal
		if(item.validate) then
			oldVal = item.validate(oldVal, unpack(item.valArgs))
		end
		if(oldVal == nil) then oldVal = item.default end
	end
	
	item.value = newVal
	if(item.onChange and newVal ~= oldVal) then
		item.onChange(oldVal, newVal)
	end

	local dt = getTickCount() - startTicks
	if(dt > 1) then
		Debug.warn('Too slow '..dt)
	end
end

-- RPC
function Settings.clientSettingChanged(name, val)
	local player = Player.fromEl(client)
	if(not player) then return end
	player.clientSettings[name] = val
	--Debug.info('clientSettingChanged [S] '..tostring(name)..' '..tostring(val))
end

setmetatable(Settings, Settings.__mt)

addInitFunc(function()
	addEventHandler('onSettingChange', g_Root, Settings.onChange)
	RPC.allow('Settings.clientSettingChanged')
end)
