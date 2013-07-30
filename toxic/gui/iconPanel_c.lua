local g_ListStyle = {}
g_ListStyle.normal = {clr = {255, 255, 0}, a = 0.6, fnt = "default-bold-small"}
g_ListStyle.hover = {clr = {0, 255, 0}, a = 1, fnt = "default-bold-small"}
g_ListStyle.active = g_ListStyle.hover
g_ListStyle.iconPos = "top"

IconPanel = Class('IconPanel')

function IconPanel.__mt.__index:init(title, size, itemSize)
	self.items = {}
	self.title = title
	self.pathName = title
	self.size = size
	self.itemSize = itemSize or Vector2(96, 80)
	self.path = PanelPath()
	self.path:insert(self)
end

function IconPanel.__mt.__index:setPath(path)
	self.path = path
end

function IconPanel.__mt.__index:addItem(item)
	assert(item.name)
	table.insert(self.items, item)
end

function IconPanel.__mt.__index:back()
	
end

function IconPanel.__mt.__index:createGUI()
	local pos = (Vector2(unpack(g_ScreenSize)) - self.size)/2
	self.wnd = guiCreateWindow(pos[1], pos[2], self.size[1], self.size[2], self.title, false)
	guiSetVisible(self.wnd, false)
	guiWindowSetSizable(self.wnd, false)
	
	pos = Vector2(10, 25)
	if(self.path) then
		self.pathView = PanelPathView(self.path, pos, self.wnd)
		pos = pos + Vector2(0, 35)
	end
	
	local listSize = self.size - pos - Vector2(10, 45)
	local iconSize = Vector2(32, 32)
	
	self.list = ListView.create(pos, listSize, self.wnd, self.itemSize, iconSize, g_ListStyle)
	self.list.onClickHandler = {self, 'onItemClick'}
	
	for i, item in ipairs(self.items) do
		local img = item.img or "img/no_img.png"
		self.list:addItem(item.name, img, i)
		if(item.tooltip) then
			self.list:setItemTooltip(i, item.tooltip)
		end
	end
	
	pos = pos + listSize + Vector2(-90, 10)
	local btn = guiCreateButton(pos[1], pos[2], 90, 25, "Close", false, self.wnd)
	addEventHandler('onClientGUIClick', btn, function() self:hide() end, false)
end

function IconPanel.__mt.__index:onItemClick(i)
	local item = self.items[i]
	if(item.right and not item.right:check()) then
		outputChatBox("Access is denied!", 255, 0, 0)
		return
	end
	
	if(item:exec(self.path)) then
		self:hide()
	end
end

function IconPanel.__mt.__index:show()
	if(self:isVisible()) then return end
	
	if(not self.wnd) then
		self:createGUI()
	end
	guiSetVisible(self.wnd, true)
	
	showCursor(true)
end

function IconPanel.__mt.__index:hide()
	if(not self:isVisible()) then return end
	
	guiSetVisible(self.wnd, false)
	showCursor(false)
end

function IconPanel.__mt.__index:isVisible()
	return self.wnd and guiGetVisible(self.wnd)
end

function IconPanel.__mt.__index:toggle()
	if(self:isVisible()) then
		self:hide()
	else
		self:show()
	end
end

function IconPanel.__mt.__index:destroy()
	self:hide()
	if(self.wnd) then
		destroyElement(self.wnd)
	end
	self.items = false
end
