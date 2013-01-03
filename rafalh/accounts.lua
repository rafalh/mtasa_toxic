addEvent("main_onLogin", true)
addEvent("main_onRegisterReq", true)

local g_RegTimeStamp = 0

--------------------------------
-- Local function definitions --
--------------------------------

local function onPlayerLogin(prevAccount, account, autoLogin)
	if(autoLogin and getAccountData(account, "autologin_disabled")) then
		cancelEvent()
		return
	end
	
	local self = g_Players[source]
	local accountName = not isGuestAccount(account) and getAccountName(account)
	if(self and accountName) then
		DbQuery("UPDATE rafalh_players SET account=NULL WHERE account=?", accountName)
		DbQuery("UPDATE rafalh_players SET account=? WHERE player=?", accountName, self.id)
	end
	
	triggerClientEvent(self.el, "main_onLoginStatus", g_ResRoot, true)
end

local function onLoginReq(name, passwd)
	local self = g_Players[client]
	if(name) then
		local account = getAccount(name, passwd)
		local success = false
		if(account) then
			success = logIn(self.el, account, passwd)
			if(not success) then
				success = (getPlayerAccount(self.el) == account)
			end
		end
		
		if(not success) then -- if we succeeded onLogin do the rest
			triggerClientEvent(self.el, "main_onLoginStatus", g_ResRoot, false)
		end
	else -- play as guest
		triggerClientEvent(self.el, "main_onLoginStatus", g_ResRoot, true)
	end
end

local function onRegisterReq(name, passwd)
	local self = g_Players[client]
	local account = false
	local ticks = getTickCount()
	if(ticks - g_RegTimeStamp >= 1000) then
		account = addAccount(name, passwd)
		g_RegTimeStamp = ticks
	else
		privMsg(self.el, "Wait a moment...")
	end
	triggerClientEvent(self.el, "main_onRegStatus", g_ResRoot, account and true)
end

------------
-- Events --
------------

addEventHandler("onPlayerLogin", g_Root, onPlayerLogin)
addEventHandler("main_onLogin", g_ResRoot, onLoginReq)
addEventHandler("main_onRegisterReq", g_ResRoot, onRegisterReq)
