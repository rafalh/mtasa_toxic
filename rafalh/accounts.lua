local function onPlayerLogin(prevAccount, account, autoLogin)
	local self = Player.fromEl(source)
	if(not self) then return end
	
	if(isGuestAccount(account)) then
		outputDebugString("onPlayerLogin: login to guest", 2)
	elseif(not self.guest) then
		outputDebugString("onPlayerLogin: no logout before login", 2)
	end
	
	if(not self:setAccount(account)) then
		cancelEvent()
		return
	end
	
	local accountName = not isGuestAccount(account) and getAccountName(account)
	triggerClientEvent(self.el, "main.onLoginStatus", g_ResRoot, true)
	triggerClientEvent(self.el, "main.onAccountChange", g_ResRoot, accountName, self.id)
end

local function onPlayerLogout()
	local self = Player.fromEl(source)
	if(not self) then return end
	
	if(self.guest) then
		outputDebugString("onPlayerLogout: guest tried to logout", 2)
	end
	
	self:setAccount(false)
	triggerClientEvent(self.el, "main.onAccountChange", g_ResRoot, false, false)
end

addInitFunc(function()
	addEventHandler("onPlayerLogin", g_Root, onPlayerLogin)
	addEventHandler("onPlayerLogout", g_Root, onPlayerLogout)
end)
