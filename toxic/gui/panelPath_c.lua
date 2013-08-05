PanelPath = Class('PanelPath')

function PanelPath.__mt.__index:insert(obj)
	table.insert(self, obj)
end

function PanelPath.__mt.__index:init(...)
	for i, arg in ipairs({...}) do
		self:insert(arg)
	end
end

function PanelPath.__mt.__index:hide()
	local last = self[#self]
	last:hide()
end

function PanelPath.__mt.__index:toggle()
	local last = self[#self]
	if(last:isVisible()) then
		last:hide()
	else
		last:show()
	end
end

function PanelPath.__mt.__index:back()
	if(#self > 1) then
		-- Hide last element and show previous
		local obj = table.remove(self)
		obj:hide()
		self[#self]:show()
	elseif(#self == 1) then
		-- Hide the only visible element
		self[#self]:hide()
	else
		-- Path is empty
		return false
	end
	return true
end

function PanelPath.__mt.__index:switchTo(obj)
	local i = table.find(self, obj)
	if(not i) then return false end
	
	if(i < #self) then
		self[#self]:hide()
		self[i + 1] = nil
		obj:show()
	end
end

PanelPathView = Class('PanelPathView')

function PanelPathView.__mt.__index:init(path, pos, parent)
	self.elements = {}
	for i, obj in ipairs(path) do
		local text = obj.pathName or obj.name
		local textW = GUI.getTestWidth(text)
		local btnW = textW + 20
		local btn = guiCreateButton(pos[1], pos[2], btnW, 25, text, false, parent)
		addEventHandler('onClientGUIClick', btn, function()
			path:switchTo(obj)
		end, false)
		table.insert(self.elements, btn)
		pos = pos + Vector2(btnW, 0)
	end
	
	pos = pos + Vector2(10, 0)
	
	if(#path > 1) then
		local back = guiCreateStaticImage(pos[1], pos[2], 25, 25, 'img/back.png', false, parent)
		table.insert(self.elements, back)
		addEventHandler('onClientGUIClick', back, function()
			path:back()
		end, false)
		
		pos = pos + Vector2(30, 0)
	end
	
	local close = guiCreateStaticImage(pos[1], pos[2], 25, 25, 'img/close.png', false, parent)
	table.insert(self.elements, close)
	addEventHandler('onClientGUIClick', close, function()
		path:hide()
	end, false)
end

function PanelPathView.__mt.__index:destroy()
	table.foreach(self.elements, destroyElement)
end
