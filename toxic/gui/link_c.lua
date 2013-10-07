Link = Class('Link')

local g_Map = {}
local DEFAULT_NORMAL_COLOR = {255, 255, 0}
local DEFAULT_HOVER_COLOR = {255, 0, 0}

local function onDestroy()
	g_Map[source] = nil
end

local function onMouseEnter()
	local self = g_Map[source]
	self.hover = true
	self:_updateColor()
end

local function onMouseLeave()
	local self = g_Map[source]
	self.hover = false
	self:_updateColor()
end

function Link.fromTpl(tpl, parent)
	local self = Link(0, 0, 0, 0, parent, tpl.text or '')
	if(tpl.align) then
		guiLabelSetHorizontalAlign(self.el, tpl.align)
	end
	return self.el
end

function Link.__mt.__index:init(x, y, width, height, parent, text)
	self.el = guiCreateLabel(x, y, width, height, text, false, parent)
	if(not self.el) then return false end
	addEventHandler('onClientElementDestroy', self.el, onDestroy, false)
	addEventHandler('onClientMouseEnter', self.el, onMouseEnter, false)
	addEventHandler('onClientMouseLeave', self.el, onMouseLeave, false)
	
	self.normalClr = DEFAULT_NORMAL_COLOR
	self.hoverClr = DEFAULT_HOVER_COLOR
	
	self.hover = false
	self:_updateColor()
	
	g_Map[self.el] = self
end

function Link.__mt.__index:_updateColor()
	if(self.hover) then
		guiLabelSetColor(self.el, unpack(self.hoverClr))
	else
		guiLabelSetColor(self.el, unpack(self.normalClr))
	end
end

function Link.__mt.__index:setNormalColor(clr)
	local r, g, b = getColorFromString(clr)
	if(not r) then return false end
	self.normalClr = {r, g, b}
	self:_updateColor()
end

function Link.__mt.__index:setHoverColor(clr)
	local r, g, b = getColorFromString(clr)
	if(not r) then return false end
	self.hoverClr = {r, g, b}
	self:_updateColor()
end
