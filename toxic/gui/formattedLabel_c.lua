FormattedLabel = Class('FormattedLabel')

local g_Map = {}

local function onDestroy()
	g_Map[source] = nil
end

local function onLangChange()
	for el, label in pairs(g_Map) do
		label:updateText()
	end
end

function FormattedLabel.__mt.__index:init(x, y, width, height, parent, fmt, ...)
	local text = MuiGetMsg(fmt):format(...)
	self.el = guiCreateLabel(x, y, width, height, text, false, parent)
	if(not self.el) then return false end
	addEventHandler('onClientElementDestroy', self.el, onDestroy, false)
	self.fmt = fmt
	self.args = {...}
	g_Map[self.el] = self
end

function FormattedLabel.__mt.__index:updateText()
	local text = MuiGetMsg(self.fmt):format(unpack(self.args))
	guiSetText(self.el, text)
end

function FormattedLabel.__mt.__index:setText(fmt, ...)
	self.fmt = fmt
	self.args = {...}
	self:updateText()
end

addEventHandler('onClientLangChanged', root, onLangChange)
