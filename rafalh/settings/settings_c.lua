Settings = {}
Settings.__mt = {}
Settings.items = {}
Settings.sorted = {}

function Settings.sort(item1, item2)
	return item1.priority < item2.priority
end

function Settings.register(item)
	item.value = item.default
	if(not item.priority) then
		item.priority = 100
	end
	Settings.items[item.name] = item
	table.insert(Settings.sorted, item)
	table.sort(Settings.sorted, Settings.sort)
end

Settings.__mt.__index = function(self, key)
	local v = rawget(self, key)
	if(v) then return v end
	
	local item = rawget(Settings, "items")[key]
	if(not item) then
		outputDebugString("Unknown setting "..tostring(key), 2)
		return nil
	end
	return item.value
end

function Settings.__mt.__newindex(self, key, val)
	local item = Settings.items[key]
	if(not item) then
		outputDebugString("Unknown setting "..tostring(key), 2)
	elseif(item.validate and not item.validate(val)) then
		outputDebugString("Invalid setting value "..tostring(val), 2)
	else
		local oldVal = item.value
		local newVal = item.cast and item.cast(val) or val
		if(newVal ~= oldVal) then
			item.value = newVal
			if(item.onChange) then
				item.onChange(oldVal, newVal)
			end
		end
	end
end

function Settings.load()
	local node = xmlLoadFile("settings.xml")
	if(not node) then return false end
	
	local start = getTickCount()
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local attr = xmlNodeGetAttributes(subnode)
		if(attr.name and attr.value) then
			Settings[attr.name] = attr.value
		else
			outputDebugString("Invalid setting "..tostring(attr.name), 2)
		end
	end
	
	local dt = getTickCount() - start
	if(dt > 1) then
		outputDebugString("Settings loaded in "..dt.." ms", 3)
	end
	xmlUnloadFile(node)
	return true
end

function Settings.save()
	local node = xmlCreateFile("settings.xml", "settings")
	if(not node) then return false end
	
	for name, item in pairs(Settings.items) do
		local subnode = xmlCreateChild(node, "setting")
		xmlNodeSetAttribute(subnode, "name", name)
		xmlNodeSetAttribute(subnode, "value", tostring(item.value))
	end
	
	xmlSaveFile(node)
	xmlUnloadFile(node)
	return true
end

function Settings.getDescr(name)
	return Settings.items[name]
end

function Settings.iterator(self, name)
	local nextName, item = next(Settings.items, name)
	if(not nextName) then return end
	return nextName, item.value
end

function Settings.pairs()
	return Settings.iterator, Settings, nil
end

setmetatable(Settings, Settings.__mt)
