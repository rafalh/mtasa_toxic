ProfileView = {}
ProfileView.__mt = {__index = ProfileView}

local g_WndToObj = {}
local g_IdToObj = {}

function ProfileView.onClose()
	local wnd = getElementParent(source) -- source = btn
	local self = g_WndToObj[wnd]
	
	guiSetEnabled(self.wnd, false)
	GaFadeOut(self.wnd, 200)
	setTimer(destroyElement, 200, 1, self.wnd)
end

function ProfileView.onDestroy()
	local self = g_WndToObj[source]
	self:destroy(true)
end

function ProfileView:destroy(ignoreEl)
	self.statsView:destroy(ignoreEl)
	showCursor(false)
	g_WndToObj[self.wnd] = nil
	g_IdToObj[self.id] = nil
	
	if(not ignoreEl) then
		destroyElement(self.wnd)
	end
end

function ProfileView.create(id, name)
	assert(id)
	
	local self = setmetatable({}, ProfileView.__mt)
	self.id = id
	
	local w, h = 420, 100 + StatsView.getHeight()
	local x, y = ( g_ScreenSize[1] - w ) / 2, ( g_ScreenSize[2] - h ) / 2
	self.wnd = guiCreateWindow(x, y, w, h, "Player profile", false)
	guiSetVisible(self.wnd, false)
	addEventHandler('onClientElementDestroy', self.wnd, ProfileView.onDestroy, false)
	
	self.nameLabel = guiCreateLabel(10, 25, w - 20, 20, name or "Unknown", false, self.wnd)
	guiSetFont(self.nameLabel, 'default-bold-small')
	
	local statsLabel = guiCreateLabel(10, 45, 100, 15, "Statistics", false, self.wnd)
	guiSetFont(statsLabel, 'default-bold-small')
	guiLabelSetColor(statsLabel, 255, 255, 128)
	
	self.statsView = StatsView.create(id, self.wnd, 10, 60, 240, h - 80)
	
	local infoLabel = guiCreateLabel(250, 45, 100, 15, "Information", false, self.wnd)
	guiSetFont(infoLabel, 'default-bold-small')
	guiLabelSetColor(infoLabel, 128, 128, 255)
	
	local btn = guiCreateButton(w - 70, h - 35, 60, 25, "Close", false, self.wnd)
	addEventHandler('onClientGUIClick', btn, ProfileView.onClose, false)
	
	self.statsView:show()
	GaFadeIn(self.wnd, 200)
	showCursor(true)
	
	RPC('getPlayerProfile', id):onResult(ProfileView.onProfile):setCallbackArgs(id):exec()
	g_WndToObj[self.wnd] = self
	g_IdToObj[self.id] = self
	
	return self
end

function ProfileView.onProfile(id, data)
	local self = g_IdToObj[id]
	if(not self) then return end
	
	local y = 60
	for key, val in pairs(data) do
		key = key:sub(1, 1):upper()..key:sub(2)
		guiCreateLabel(250, y, 80, 15, key..':', false, self.wnd)
		guiCreateLabel(330, y, 100, 15, val, false, self.wnd)
		y = y + 15
	end
end
