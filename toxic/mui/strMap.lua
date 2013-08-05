MuiStringMap = Class('MuiStringMap')

function MuiStringMap.__mt.__index:init(path)
	self.path = path
	self.list = false
end

function MuiStringMap.__mt.__index:getList()
	if(self.list) then return self.list end
	
	local node = xmlLoadFile(self.path)
	if(not node) then return false end
	
	self.list = {}
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local entry = {}
		entry.id = xmlNodeGetAttribute(subnode, 'id')
		entry.val = xmlNodeGetValue(subnode)
		if(entry.id and entry.val) then
			table.insert(self.list, entry)
		end
	end
	
	xmlUnloadFile(node)
	return self.list
end

function MuiStringMap.__mt.__index:remove(id)
	local node = xmlLoadFile(self.path)
	if(not node) then return false end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local curId = xmlNodeGetAttribute(subnode, 'id')
		if(curId == id) then
			xmlDestroyNode(subnode)
			break
		end
	end
	
	xmlSaveFile(node)
	xmlUnloadFile(node)
	
	-- Invalidate cache
	self.list = false
end

function MuiStringMap.__mt.__index:set(id, value)
	local node = xmlLoadFile(self.path)
	if(not node) then return false end
	
	local found = false
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local curId = xmlNodeGetAttribute(subnode, 'id')
		if(curId == id) then
			xmlNodeSetValue(subnode, value)
			found = true
			break
		end
	end
	
	if(not found) then
		local subnode = xmlCreateChild(node, 'msg')
		xmlNodeSetAttribute(subnode, 'id', id)
		xmlNodeSetValue(subnode, value)
	end
	
	xmlSaveFile(node)
	xmlUnloadFile(node)
	
	-- Invalidate cache
	self.list = false
end
