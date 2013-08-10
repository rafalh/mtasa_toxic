AvatarView = Class('AvatarView')
AvatarView.elMap = {}

-- Events
addEvent("main.onAvatarChange", true)

function AvatarView.__mt.__index:init(x, y, w, h, target, allowChange, parent)
	self.target = target
	
	local avtPath = false
	if(self.target == g_Me) then
		avtPath = g_LocalAvatar and 'avatars/img/'..g_LocalAvatar
		if(avtPath and not fileExists(avtPath)) then avtPath = false end
	else
		RPC('AvtGetAccountAvatar', target):onResult(self.setAvatar, self):exec()
	end
	
	self.el = guiCreateStaticImage(x, y, w, h, avtPath or 'img/no_img.png', false, parent)
	
	if(allowChange and self.target == g_Me) then
		setElementData(self.el, 'tooltip', "Click to change your avatar")
		addEventHandler('onClientGUIClick', self.el, AvtOpenGUI, false)
	end
	
	addEventHandler('onClientElementDestroy', self.el, AvatarView.onDestroy, false)
	
	AvatarView.elMap[self.el] = self
end

function AvatarView.__mt.__index:setAvatar(filename)
	if(not self.el) then return end -- destroyed
	local path = filename and filename ~= '' and 'avatars/img/'..filename
	guiStaticImageLoadImage(self.el, path or 'img/no_img.png')
end

function AvatarView.__mt.__index:destroy(ignoreEl)
	AvatarView.elMap[self.el] = nil
	
	if(not ignoreEl) then
		destroyElement(self.el)
	end
	
	self.el = false
end

function AvatarView.onAvtChange(filename)
	for el, view in pairs(AvatarView.elMap) do
		if(view.target == source) then
			view:setAvatar(filename)
		end
	end
end

function AvatarView.onDestroy()
	local self = AvatarView.elMap[source]
	if(self) then
		self:destroy(true)
	end
end

addEventHandler("main.onAvatarChange", localPlayer, AvatarView.onAvtChange)
