ListView = {}
ListView.__mt = {__index = ListView}
ListView.elMap = {}

ListView.style = {}
ListView.style.normal = {clr = {196, 196, 196}, a = 0.8, fnt = 'default-normal'}
ListView.style.hover = {clr = {255, 255, 255}, a = 1, fnt = 'default-normal'}
ListView.style.active = {clr = {255, 255, 255}, a = 1, fnt = 'default-bold-small'}
ListView.style.iconPos = 'top'

function ListView:getImgTitleCoords(w, h)
	local imgX, imgY
	local titleX, titleY
	local titleW, titleH
	
	if(self.style.iconPos == 'top' or not self.style.iconPos) then
		imgX, imgY = (w - self.imgSize[1])/2, 5
		titleX, titleY = 0, 10 + self.imgSize[2]
		titleW, titleH = w, h - 10 - self.imgSize[2]
	elseif(self.style.iconPos == 'left') then
		imgX, imgY = 5, (self.itemSize[2] - self.imgSize[2])/2
		titleX, titleY = 10 + self.imgSize[2], 10
		titleW, titleH = w - titleX, h - 20
	else
		assert(false)
	end
	
	return Vector2(imgX, imgY), Rect(Vector2(titleX, titleY), Vector2(titleW, titleH))
end

function ListView:addItem(name, img, id, style)
	local idxX = #self.items % self.cols
	local idxY = math.floor(#self.items/self.cols)
	local x, y = idxX*self.itemSize[1], idxY*self.itemSize[2]
	local w, h = self.itemSize[1], self.itemSize[2]
	local item = {title = name, id = id, style = style or self.style}
	
	item.bgEl = guiCreateStaticImage(x, y, w, h, 'img/white.png', false, self.el)
	guiSetAlpha(item.bgEl, 0)
	
	local imgPos, titleRc = self:getImgTitleCoords(w, h)
	
	local imgPath = img or 'img/empty.png'
	--item.imgEl = guiCreateStaticImage(imgX, imgY, self.imgSize[1], self.imgSize[2], imgPath, false, item.el)
	item.imgEl = guiCreateStaticImage(x + imgPos[1], y + imgPos[2], self.imgSize[1], self.imgSize[2], imgPath, false, self.el)
	guiSetAlpha(item.imgEl, item.style.normal.a)
	
	--item.titleEl = guiCreateLabel(titleX, titleY, titleW, titleH, name, false, item.el)
	item.titleEl = guiCreateLabel(x + (titleRc:getOrigin()[1]), y + (titleRc:getOrigin()[2]), titleRc:getSize()[1], titleRc:getSize()[2], name, false, self.el)
	if(self.style.iconPos == 'top' or not self.style.iconPos) then
		guiLabelSetHorizontalAlign(item.titleEl, 'center', true)
	end
	guiLabelSetColor(item.titleEl, unpack(item.style.normal.clr))
	guiSetFont(item.titleEl, item.style.normal.fnt)
	
	self.itemsMap[item.bgEl] = item
	self.itemsMap[item.imgEl] = item
	self.itemsMap[item.titleEl] = item
	
	table.insert(self.items, item)
	if(item.id) then
		self.idToItem[item.id] = item
	end
end

function ListView:setActiveItem(id)
	if(self.activeItem) then
		guiSetAlpha(self.activeItem.imgEl, self.activeItem.style.normal.a)
		guiLabelSetColor(self.activeItem.titleEl, unpack(self.activeItem.style.normal.clr))
		guiSetFont(self.activeItem.titleEl, self.activeItem.style.normal.fnt)
	end
	
	local item = self.idToItem[id]
	self.activeItem = item
	if(item) then
		guiSetAlpha(item.imgEl, item.style.active.a)
		guiLabelSetColor(item.titleEl, unpack(item.style.active.clr))
		guiSetFont(item.titleEl, item.style.active.fnt)
	end
end

function ListView:getActiveItem()
	return self.activeItem and self.activeItem.id
end

function ListView:clear()
	for i, item in ipairs(self.items) do
		destroyElement(item.bgEl)
		destroyElement(item.imgEl)
		destroyElement(item.titleEl)
	end
	self.items = {}
	self.itemsMap = {}
	self.idToItem = {}
	self.activeItem = false
end

function ListView:setItemImg(id, img)
	local item = self.idToItem[id]
	local imgPath = img or 'img/empty.png'
	guiStaticImageLoadImage(item.imgEl, imgPath)
end

function ListView:setItemStyle(id, style)
	local item = self.idToItem[id]
	item.style = style or self.style
	
	local subStyle = self.activeItem == item and item.style.active or item.style.normal
	guiSetAlpha(item.imgEl, subStyle.a)
	guiLabelSetColor(item.titleEl, unpack(subStyle.clr))
	guiSetFont(item.titleEl, subStyle.fnt)
end

function ListView:setItemTooltip(id, tooltip)
	local item = self.idToItem[id]
	
	setElementData(item.imgEl, 'tooltip', tooltip)
	setElementData(item.titleEl, 'tooltip', tooltip)
	setElementData(item.bgEl, 'tooltip', tooltip)
end

function ListView:setFilter(filter)
	filter = (filter or ''):lower()
	local idx = 0
	for i, item in ipairs(self.items) do
		local visible = item.title:lower():find(filter, 1, true) and true or false
		--guiSetVisible(item.el, visible)
		guiSetVisible(item.bgEl, visible)
		guiSetVisible(item.imgEl, visible)
		guiSetVisible(item.titleEl, visible)
		
		if(visible) then
			local idxX = idx % self.cols
			local idxY = math.floor(idx/self.cols)
			local w, h = self.itemSize[1], self.itemSize[2]
			local x, y = idxX*self.itemSize[1], idxY*self.itemSize[2]
			local imgPos, titleRc = self:getImgTitleCoords(w, h)
			guiSetPosition(item.bgEl, x, y, false)
			guiSetPosition(item.imgEl, x + imgPos[1], y + imgPos[2], false)
			guiSetPosition(item.titleEl, x + titleRc:getOrigin()[1], y + titleRc:getOrigin()[2], false)
			idx = idx + 1
		else
			--guiSetPosition(item.el, 0, 0, false)
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
	
	addEventHandler('onClientElementDestroy', self.el, ListView.onElDestroy, false)
	addEventHandler('onClientMouseEnter', self.el, ListView.onMouseEnter, true)
	addEventHandler('onClientMouseLeave', self.el, ListView.onMouseLeave, true)
	addEventHandler('onClientGUIClick', self.el, ListView.onMouseClick, true)
	addEventHandler('onClientMouseWheel', self.el, ListView.onMouseWheel, true)
	
	ListView.elMap[self.el] = self
	return self
end

function ListView.getItemFromElement(el)
	local parent = getElementParent(el)
	local self = ListView.elMap[parent]
	if(not self) then return false end
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
	
	guiLabelSetColor(item.titleEl, unpack(item.style.hover.clr))
	guiSetAlpha(item.imgEl, item.style.hover.a)
	guiSetFont(item.titleEl, item.style.hover.fnt)
end

function ListView.onMouseLeave()
	local self, item = ListView.getItemFromElement(source)
	if(not self) then return end -- not a list item
	
	guiSetAlpha(item.bgEl, 0)
	
	if(self.activeItem == item) then return end -- nothing to do
	
	guiSetAlpha(item.imgEl, item.style.normal.a)
	guiLabelSetColor(item.titleEl, unpack(item.style.normal.clr))
	guiSetFont(item.titleEl, item.style.normal.fnt)
end

function ListView.onMouseClick()
	local self, item = ListView.getItemFromElement(source)
	if(not self) then return end
	if(self.onClickHandler) then
		if(type(self.onClickHandler) == 'table') then
			local obj = self.onClickHandler[1]
			local methodName = self.onClickHandler[2]
			obj[methodName](obj, item.id)
		else
			self.onClickHandler(item.id)
		end
	end
end

function ListView.onMouseWheel(upOrDown)
	local self, item = ListView.getItemFromElement(source)
	if(not self) then return end -- if mouse wheel is used over the scrollPane it is handled properly
	
	local pos = guiScrollPaneGetVerticalScrollPosition(self.el)
	pos = pos - upOrDown * 10
	guiScrollPaneSetVerticalScrollPosition(self.el, pos)
end
