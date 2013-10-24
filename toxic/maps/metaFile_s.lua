MetaFile = Class('MetaFile')

function MetaFile.__mt.__index:init(path)
	self.path = path
end

function MetaFile.__mt.__index:setSetting(setting, value)
	if(not self.node and not self:open()) then return false end
	
	local subnode = xmlFindChild(self.node, 'settings', 0)
	if(not subnode) then
		subnode = xmlCreateChild(self.node, 'settings')
		if(not subnode) then
			return false
		end
	end
	
	local found, success = false, false
	local i = 0
	
	while(true) do
		local subnode2 = xmlFindChild(subnode, 'setting', i)
		if(not subnode2) then break end
		i = i + 1
		
		local name = xmlNodeGetAttribute(subnode2, 'name')
		if(name == setting or name == '#'..setting or name == '@'..setting or name == '*'..setting) then
			if(value) then
				success = xmlNodeSetAttribute(subnode2, 'value', toJSON(value))
			else
				success = xmlDestroyNode(subnode2)
				i = i - 1
			end
			found = true
		end
	end
	
	if(not found) then
		subnode2 = xmlCreateChild(subnode, 'setting')
		if(subnode2) then
			success =
				xmlNodeSetAttribute(subnode2, 'name', '#'..setting) and
				xmlNodeSetAttribute(subnode2, 'value', toJSON(value))
		else
			success = false
		end
	end
	
	return success
end

function MetaFile.__mt.__index:getSetting(setting)
	if(not self.node and not self:open()) then return false end
	
	local subnode = xmlFindChild(self.node, 'settings', 0)
	if(not subnode) then return nil end
	
	local i = 0
	while(true) do
		local subnode2 = xmlFindChild(subnode, 'setting', i)
		if(not subnode2) then break end
		i = i + 1
		
		local name = xmlNodeGetAttribute(subnode2, 'name')
		if(name == setting or name == '#'..setting or name == '@'..setting or name == '*'..setting) then
			local value = xmlNodeGetAttribute(subnode2, 'value')
			return fromJSON(value) or value
		end
	end
	
	return nil
end

function MetaFile.__mt.__index:setInfo(attr, value)
	if(not self.node and not self:open()) then return false end
	
	local subnode = xmlFindChild(self.node, 'info', 0)
	if(not subnode) then xmlUnloadFile(self.node) return false end
	
	local success = xmlNodeSetAttribute(subnode, attr, value)
	
	return success
end

function MetaFile.__mt.__index:open()
	if(self.node) then self:close() end
	self.node = xmlLoadFile(self.path)
	return self.node and true
end

function MetaFile.__mt.__index:save()
	return xmlSaveFile(self.node)
end

function MetaFile.__mt.__index:close()
	if(not self.node) then return end
	xmlUnloadFile(self.node)
	self.node = false
end
