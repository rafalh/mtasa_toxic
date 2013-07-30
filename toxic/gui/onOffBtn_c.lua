OnOffBtn = {}
OnOffBtn.__mt = {__index = OnOffBtn}
OnOffBtn.elMap = {}

function OnOffBtn.onClick()
	local self = OnOffBtn.elMap[source]
	self.enabled = not self.enabled
	local path = self.enabled and 'img/on.png' or 'img/off.png'
	guiStaticImageLoadImage(self.el, path)
	if(self.onChange) then
		self.onChange(self)
	end
end

function OnOffBtn.onDestroy()
	local self = OnOffBtn.elMap[source]
	self:destroy(true)
end

function OnOffBtn:destroy(ignoreEl)
	if(not ignoreEl) then
		destroyElement(self.el)
	end
end

function OnOffBtn.create(x, y, parent, enabled)
	local self = setmetatable({}, OnOffBtn.__mt)
	self.enabled = enabled
	local w, h = 72, 25
	local path = enabled and 'img/on.png' or 'img/off.png'
	self.el = guiCreateStaticImage(x, y, w, h, path, false, parent)
	addEventHandler('onClientGUIClick', self.el, OnOffBtn.onClick, false)
	addEventHandler('onClientElementDestroy', self.el, OnOffBtn.onDestroy, false)
	local horMargin = 4
	local onW = math.floor((w - 2 * horMargin) / 2)
	local onLabel = guiCreateLabel(horMargin, 0, onW, h, "On", false, self.el)
	guiSetFont(onLabel, 'default-bold-small')
	guiLabelSetHorizontalAlign(onLabel, 'center')
	guiLabelSetVerticalAlign(onLabel, 'center')
	guiSetProperty(onLabel, 'MousePassThroughEnabled', 'True')
	local offLabel = guiCreateLabel(horMargin + onW, 0, w - onW - 2 * horMargin, h, "Off", false, self.el)
	guiLabelSetHorizontalAlign(offLabel, 'center')
	guiLabelSetVerticalAlign(offLabel, 'center')
	guiSetFont(offLabel, 'default-bold-small')
	guiSetProperty(offLabel, 'MousePassThroughEnabled', 'True')
	OnOffBtn.elMap[self.el] = self
	return self
end
