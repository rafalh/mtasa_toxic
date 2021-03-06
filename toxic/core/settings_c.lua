Settings = {}
Settings.__mt = {}
Settings.localMap = {}
Settings.globalMap = {}
Settings.localSorted = {}

function Settings.sortLocal(item1, item2)
	return item1.priority < item2.priority
end

function Settings.register(item)
	item.value = item.default
	if(not item.priority) then
		item.priority = 100
	end
	assert(not rawget(Settings, 'localMap')[item.name])
	rawget(Settings, 'localMap')[item.name] = item
	
	local localSorted = rawget(Settings, 'localSorted')
	table.insert(localSorted, item)
	table.sort(localSorted, rawget(Settings, 'sortLocal'))
end

function Settings.setGlobal(data)
	rawset(Settings, 'globalMap', data)
end

function Settings.getShared()
	local ret = {}
	local localSorted = rawget(Settings, 'localSorted')
	for i, item in ipairs(localSorted) do
		ret[item.name] = item.value
	end
	return ret
end

Settings.__mt.__index = function(self, key)
	local v = rawget(self, key)
	if(v) then return v end
	
	local item = rawget(Settings, 'localMap')[key]
	if(item) then
		return item.value
	end
	
	local val = rawget(Settings, 'globalMap')[key]
	if(val ~= nil) then
		return val
	end
	
	Debug.warn('Cannot get unknown setting '..tostring(key))
	Debug.printStackTrace()
	return nil
end

function Settings.__mt.__newindex(self, key, val)
	local item = rawget(Settings, 'localMap')[key]
	if(not item) then
		Debug.warn('Cannot set unknown setting '..tostring(key))
		Debug.printStackTrace()
	elseif(item.validate and not item.validate(val)) then
		Debug.warn('Invalid setting value '..tostring(val))
	else
		local oldVal = item.value
		if(item.cast) then
			val = item.cast(val)
		end
		
		if(val ~= oldVal) then
			item.value = val
			if(item.onChange) then
				item.onChange(oldVal, val)
			end
			if(item.shared and not g_Init) then
				RPC('Settings.clientSettingChanged', item.name, val):exec()
				--Debug.info('clientSettingChanged [C] '..tostring(item.name)..' '..tostring(val))
			end
		end
	end
end

function Settings.load()
	local prof = DbgPerf()
	
	local node = xmlLoadFile('settings.xml')
	if(not node) then return false end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local attr = xmlNodeGetAttributes(subnode)
		if(attr.name and attr.value) then
			Settings[attr.name] = attr.value
		else
			Debug.warn('Invalid setting '..tostring(attr.name))
		end
	end
	
	xmlUnloadFile(node)
	prof:cp('Settings loading')
	return true
end

function Settings.save()
	local node = xmlCreateFile('settings.xml', 'settings')
	if(not node) then return false end
	
	for name, item in pairs(Settings.localMap) do
		local subnode = xmlCreateChild(node, 'setting')
		xmlNodeSetAttribute(subnode, 'name', name)
		xmlNodeSetAttribute(subnode, 'value', tostring(item.value))
	end
	
	xmlSaveFile(node)
	xmlUnloadFile(node)
	return true
end

setmetatable(Settings, Settings.__mt)
