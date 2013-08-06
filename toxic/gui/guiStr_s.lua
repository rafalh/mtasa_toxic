GuiStringProvider = Class('GuiStringProvider')

function GuiStringProvider.__mt.__index:init(path)
	self.path = path
end

function GuiStringProvider.__mt.__index:loadNode(node)
	local text = xmlNodeGetAttribute(node, 'text')
	if(text and text ~= '') then
		table.insert(self.list, text)
	end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		self:loadNode(subnode)
	end
end

function GuiStringProvider.__mt.__index:load()
	local node = xmlLoadFile(self.path)
	if(not node) then
		outputDebugString('xmlLoadFile '..path..' failed', 2)
		return false
	end
	
	self.list = {}
	self:loadNode(node)
	
	xmlUnloadFile(node)
	return true
end

function GuiStringProvider.__mt.__index:getString(i)
	if(not self.list and not self:load()) then return false end
	return self.list[i], 'c'
end

function GuiStringProvider.__mt.__index:getStringCount()
	if(not self.list and not self:load()) then return 0 end
	return #self.list
end

addInitFunc(function()
	MuiStringList:registerProvider(GuiStringProvider('gui/gui.xml'))
end)
