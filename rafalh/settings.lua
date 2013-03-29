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

function Settings.loadMeta()
	local node, i = xmlLoadFile("meta.xml"), 0
	if(not node) then return false end
	
	local settingsNode = xmlFindChild(node, "settings", 0)
	if(not settingsNode) then
		xmlUnloadFile(node)
		return false
	end
	
	for i, subnode in ipairs(xmlNodeGetChildren(settingsNode)) do
		local attr = xmlNodeGetAttributes(subnode)
		local item = {}
		if(attr.accept) then
			local min, max = attr.accept:match("^(%d+)%-(%d+)$")
			if(min and max) then
				item.validate = validateInt
				item.valArgs = {tonumber(min), tonumber(max)}
			elseif(attr.accept == "true,false" or attr.accept == "false,true") then
				item.validate = tobool
				item.valArgs = {}
			else
				item.validate = tostring
				item.valArgs = {}
			end
		end
		item.client = (attr.type == "client")
		item.default = item.validate and item.validate(attr.value, unpack(item.valArgs)) or attr.value
		
		if(attr.name) then
			local ch1 = attr.name:sub(1, 1)
			if(ch1 == "*" or ch1 == "@") then
				attr.name = attr.name:sub(2)
			end
			
			item.name = attr.name
			if(Settings.items[item.name]) then
				outputDebugString("Ignoring meta setting "..item.name, 2)
			else
				Settings.items[item.name] = item
			end
		end
	end
	
	xmlUnloadFile(node)
	return true
end

function Settings.createDbTbl()
	local fields, defValues = {}, {}
	for key, item in pairs(Settings.items) do
		if(item.priv) then
			table.insert(fields, item.name.." "..item.type.." DEFAULT ? NOT NULL")
			table.insert(defValues, item.default)
		end
	end
	
	local success = DbQuery("CREATE TABLE IF NOT EXISTS "..DbPrefix.."settings "..
		"("..table.concat(fields, ",")..")", unpack(defValues))
	return success
end

function Settings.loadPrivate()
	if(not DbIsReady()) then
		outputDebugString("Database is not ready yet", 2)
		return false
	end
	
	local rows = DbQuery("SELECT * FROM rafalh_settings LIMIT 1")
	if(not rows[1]) then
		DbQuery("INSERT INTO rafalh_settings DEFAULT VALUES") -- Note: DEFAULT VALUES is sqlite only
		rows = DbQuery("SELECT * FROM rafalh_settings LIMIT 1")
	end
	for key, val in pairs(rows[1]) do
		local item = Settings.items[key]
		assert(item)
		
		if(item.type == "BOOL" or item.type == "BOOLEAN") then
			val = tobool(val)
		end
		item.value = val
	end
	
	return true
end

Settings.__mt.__index = function(self, key)
	local v = rawget(self, key)
	if(v) then return v end
	
	local item = rawget(Settings, "items")[key]
	if(not item) then
		outputDebugString("Unknown setting "..tostring(key), 2)
		return nil
	end
	if(item.value == nil) then
		local val = get(key)
		if(item.validate) then
			val = item.validate(val, unpack(item.valArgs))
			if(val == nil) then
				outputDebugString("Invalid setting value: "..key, 2)
				val = item.default
			end
		end
		item.value = val
	end
	return item.value
end

function Settings.__mt.__newindex(self, key, val)
	local item = Settings.items[key]
	if(not item) then
		outputDebugString("Unknown setting "..tostring(key), 2)
		return
	end
	
	local newVal = item.validate and item.validate(val, unpack(item.valArgs)) or val
	if(newVal == nil) then
		outputDebugString("Invalid setting value "..tostring(newVal), 2)
		return
	end
	
	local oldVal = Settings[key]
	if(newVal ~= oldVal) then
		item.value = newVal
		if(item.priv) then
			if(item.type == "BOOL") then
				newVal = newVal and 1 or 0
			end
			DbQuery("UPDATE "..DbPrefix.."settings SET "..key.."=?", newVal)
		elseif(not item._inSet) then
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
	
	outputServerLog("allow_rate_change "..tostring(Settings.allow_rate_change).." ("..type(Settings.allow_rate_change)..")")
	
	return true
end

function Settings.onChange(name, oldVal, newVal)
	local ch1 = name:sub(1, 1)
	if(ch1 == "*" or ch1 == "@") then
		name = name:sub(2)
	end
	
	-- Check if this is current resource setting
	if(name:sub(1, g_ResName:len () + 1) ~= g_ResName..".") then return end
	name = name:sub(g_ResName:len() + 2)
	
	local item = Settings.items[name]
	if(not item or item.priv) then
		outputDebugString("Unknown setting "..name, 2)
		return
	end
	
	if(item.validate) then
		newVal = item.validate(newVal, unpack(item.valArgs))
	end
	
	if(newVal == nil) then
		outputDebugString("Invalid setting value "..name, 2)
		cancelEvent()
		return
	end
	
	if(item.value ~= nil) then
		oldVal = item.value
	else
		oldVal = item.validate and item.validate(oldVal, unpack(item.valArgs)) or oldVal
		if(oldVal == nil) then oldVal = item.default end
	end
	
	item.value = newVal
	if(item.onChange and newVal ~= oldVal) then
		item.onChange(oldVal, newVal)
	end
end

setmetatable(Settings, Settings.__mt)

addInitFunc(function()
	addEventHandler("onSettingChange", g_Root, Settings.onChange)
end)
