local function onPlayerLogin(prevAccount, account, autoLogin)
	local self = Player.fromEl(source)
	if(not self) then return end
	
	if(isGuestAccount(account)) then
		outputDebugString('onPlayerLogin: login to guest', 2)
	elseif(not self.guest) then
		outputDebugString('onPlayerLogin: no logout before login', 2)
	end
	
	if(not self:setAccount(account)) then
		cancelEvent()
		return
	end
	
	local ticks = getTickCount()
	local joinMsg = self.accountData.joinmsg
	local joinMsgAllowed = not self.joinMsgTicks or (ticks - self.joinMsgTicks) > 5*1000
	if(joinMsg and joinMsg ~= '' and joinMsgAllowed) then
		local r, g, b = getPlayerNametagColor(self.el)
		outputChatBox('(JOINMSG) '..getPlayerName(self.el)..': #EBDDB2'..joinMsg, g_Root, r, g, b, true)
		self.joinMsgTicks = ticks
	end
	
	local accountName = not isGuestAccount(account) and getAccountName(account)
	triggerClientEvent(self.el, 'main.onLoginStatus', g_ResRoot, true)
	triggerClientEvent(self.el, 'main.onAccountChange', g_ResRoot, accountName, self.id)
end

local function onPlayerLogout()
	local self = Player.fromEl(source)
	if(not self) then return end
	
	if(self.guest) then
		outputDebugString('onPlayerLogout: guest tried to logout', 2)
	end
	
	self:setAccount(false)
	triggerClientEvent(self.el, 'main.onAccountChange', g_ResRoot, false, false)
end

addInitFunc(function()
	addEventHandler('onPlayerLogin', g_Root, onPlayerLogin)
	addEventHandler('onPlayerLogout', g_Root, onPlayerLogout)
end)
