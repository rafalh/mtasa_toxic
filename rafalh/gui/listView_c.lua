ListView = {}
ListView.__mt = {__index = ListView}
ListView.elMap = {}

ListView.style = {}
ListView.style.normal = {clr = {196, 196, 196}, a = 0.8, fnt = "default-normal"}
ListView.style.hover = {clr = {255, 255, 255}, a = 1, fnt = "default-normal"}
ListView.style.active = {clr = {255, 255, 255}, a = 1, fnt = "default-bold-small"}

function ListView:addItem(name, img, id)
	local idxX = #self.items % self.cols
	local idxY = math.floor(#self.items/self.cols)
	local x, y = idxX*self.itemSize[1], idxY*self.itemSize[2]
	local w, h = self.itemSize[1], self.itemSize[2]
	local item = {title = name, id = id}
	
	item.el = guiCreateLabel(x, y, w, h, "", false, self.el)
	self.itemsMap[item.el] = item
	
	item.bgEl = guiCreateStaticImage(0, 0, w, h, "img/white.png", false, item.el)
	guiSetAlpha(item.bgEl, 0)
	
	local imgX, imgY = (w - self.imgSize[1])/2, 5
	local imgPath = img or "img/empty.png"
	item.imgEl = guiCreateStaticImage(imgX, imgY, self.imgSize[1], self.imgSize[2], imgPath, false, item.el)
	guiSetAlpha(item.imgEl, self.style.normal.a)
	
	local titleX, titleY = 0, 10 + self.imgSize[2]
	local titleW, titleH = w, h - 10 - self.imgSize[2]
	item.titleEl = guiCreateLabel(titleX, titleY, titleW, titleH, name, false, item.el)
	guiLabelSetHorizontalAlign(item.titleEl, "center", true)
	guiLabelSetColor(item.titleEl, unpack(self.style.normal.clr))
	guiSetFont(item.titleEl, self.style.normal.fnt)
	
	table.insert(self.items, item)
	self.idToItem[item.id] = item
end

function ListView:setActiveItem(id)
	if(self.activeItem) then
		guiSetAlpha(self.activeItem.imgEl, self.style.normal.a)
		guiLabelSetColor(self.activeItem.titleEl, unpack(self.style.normal.clr))
		guiSetFont(self.activeItem.titleEl, self.style.normal.fnt)
	end
	
	local item = self.idToItem[id]
	self.activeItem = item
	if(item) then
		guiSetAlpha(item.imgEl, self.style.active.a)
		guiLabelSetColor(item.titleEl, unpack(self.style.active.clr))
		guiSetFont(item.titleEl, self.style.active.fnt)
	end
end

function ListView:getActiveItem()
	return self.activeItem and self.activeItem.id
end

function ListView:clear()
	for i, item in ipairs(self.items) do
		destroyElement(item.el)
	end
	self.items = {}
	self.itemsMap = {}
	self.idToItem = {}
	self.activeItem = false
end

function ListView:setFilter(filter)
	filter = (filter or ""):lower()
	local idx = 0
	for i, item in ipairs(self.items) do
		local visible = item.title:lower():find(filter, 1, true) and true or false
		guiSetVisible(item.el, visible)
		if(visible) then
			local idxX = idx % self.cols
			local idxY = math.floor(idx/self.cols)
			local x, y = idxX*self.itemSize[1], idxY*self.itemSize[2]
			guiSetPosition(item.el, x, y, false)
			idx = idx + 1
		else
			guiSetPosition(item.el, 0, 0, false)
		end
	end
end

function ListView:destroy(ignoreEl)
	ListView.elMap[self.el] = nil
	if(not ignoreEl) then
		destroyElement(self.el)
	end
end

function ListView.create(pos, size, parent, itemSize, imgSize, style)
	local self = setmetatable({}, ListView.__mt)
	self.el = guiCreateScrollPane(pos[1], pos[2], size[1], size[2], false, parent)
	self.items = {}
	self.itemsMap = {}
	self.idToItem = {}
	self.style = style or ListView.style
	self.itemSize = itemSize or {80, 80}
	self.imgSize = imgSize or {32, 32}
	self.cols = math.floor(size[1] / self.itemSize[1])
	
	addEventHandler("onClientElementDestroy", self.el, ListView.onElDestroy, false)
	addEventHandler("onClientMouseEnter", self.el, ListView.onMouseEnter, true)
	addEventHandler("onClientMouseLeave", self.el, ListView.onMouseLeave, true)
	addEventHandler("onClientGUIClick", self.el, ListView.onMouseClick, true)
	addEventHandler("onClientMouseWheel", self.el, ListView.onMouseWheel, true)
	
	ListView.elMap[self.el] = self
	return self
end

function ListView.getItemFromElement(el)
	local parent = getElementParent(el)
	local self = ListView.elMap[parent]
	if(not self) then -- allow two levels
		el = parent
		parent = getElementParent(el)
		self = ListView.elMap[parent]
		if(not self) then return false end
	end
	return self, self.itemsMap[el]
end

function ListView.onElDestroy()
	local self = ListView.elMap[source]
	self:destroy(true)
end

function ListView.onMouseEnter()
	local self, item = ListView.getItemFromElement(source)
	if(not self) then return end -- not a list item
	
	guiSetAlpha(item.bgEl, 0.1)
	
	if(self.activeItem == item) then return end -- nothing to do
	
	guiLabelSetColor(item.titleEl, unpack(self.style.hover.clr))
	guiSetAlpha(item.imgEl, self.style.hover.a)
	guiSetFont(item.titleEl, self.style.hover.fnt)
end

function ListView.onMouseLeave()
	local self, item = ListView.getItemFromElement(source)
	if(not self) then return end -- not a list item
	
	guiSetAlpha(item.bgEl, 0)
	
	if(self.activeItem == item) then return end -- nothing to do
	
	guiSetAlpha(item.imgEl, self.style.normal.a)
	guiLabelSetColor(item.titleEl, unpack(self.style.normal.clr))
	guiSetFont(item.titleEl, self.style.normal.fnt)
end

function ListView.onMouseClick()
	local self, item = ListView.getItemFromElement(source)
	if(not self) then return end
	if(self.onClickHandler) then
		self.onClickHandler(item.id)
	end
end

function ListView.onMouseWheel(upOrDown)
	local self, item = ListView.getItemFromElement(source)
	if(not self) then return end -- if mouse wheel is used over the scrollPane it is handled properly
	
	local pos = guiScrollPaneGetVerticalScrollPosition(self.el)
	pos = pos - upOrDown * 50
	guiScrollPaneSetVerticalScrollPosition(self.el, pos)
end
