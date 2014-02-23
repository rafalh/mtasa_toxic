-- Includes
#include 'include/config.lua'

local function onPlayerLoginFilter(prevAccount, account)
	local accountName = getAccountName(account)
	local data = DbQuerySingle('SELECT online FROM '..PlayersTable..' WHERE account=? LIMIT 1', account)
	if(data and data.online == 1) then return false end
	return true
end

local function onPlayerLogin(prevAccount, account, autoLogin)
	local self = Player.fromEl(source)
	if(not self) then return end
	
	if(isGuestAccount(account)) then
		Debug.warn('onPlayerLogin: login to guest')
	elseif(not self.guest) then
		Debug.warn('onPlayerLogin: no logout before login')
	end
	
	if(not self:setAccount(account)) then
		cancelEvent()
		Debug.err('Failed to set account for player')
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
	
#if(ASK_FOR_EMAIL) then
	if(self.accountData.email == '') then
		RPC('MsgBox.showInfo', MuiGetMsg("E-Mail address has not been set", self.el),
		MuiGetMsg("E-mail address has not been set in your profile. Please enter it in order to be able to recover password if necessary.", self.el)..'\n'..
		MuiGetMsg("Other players cannot see your e-mail address.", self.el)..'\n'..
		MuiGetMsg("To set up your e-mail open User Panel (F2), click 'Profile' and then 'Change e-mail'.", self.el)):setClient(self.el):exec()
	end
#end

end

local function onPlayerLogout()
	local self = Player.fromEl(source)
	if(not self) then return end
	
	if(self.guest) then
		Debug.warn('onPlayerLogout: guest tried to logout')
	end
	
	self:setAccount(false)
	triggerClientEvent(self.el, 'main.onAccountChange', g_ResRoot, false, false)
end

addInitFunc(function()
	Event('onPlayerLogin'):addFilter(onPlayerLoginFilter)
	Event('onPlayerLogin'):addHandler(onPlayerLogin)
	addEventHandler('onPlayerLogout', g_Root, onPlayerLogout)
end)
