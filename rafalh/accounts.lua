addEvent("main.onLogin", true)
addEvent("main.onRegisterReq", true)
addEvent("main.onChgPwReq", true)
addEvent("main.onLogoutReq", true)

local g_RegTimeStamp = 0

--------------------------------
-- Local function definitions --
--------------------------------

local function onPlayerLogin(prevAccount, account, autoLogin)
	local self = g_Players[source]
	local accountName = not isGuestAccount(account) and getAccountName(account)
	if(self and accountName) then
		DbQuery("UPDATE rafalh_players SET account=NULL WHERE account=?", accountName)
		DbQuery("UPDATE rafalh_players SET account=? WHERE player=?", accountName, self.id)
	end
	
	triggerClientEvent(self.el, "main.onLoginStatus", g_ResRoot, true)
	triggerClientEvent(self.el, "main.onAccountChange", g_ResRoot, accountName)
end

local function onPlayerLogout()
	local self = g_Players[source]
	triggerClientEvent(self.el, "main.onAccountChange", g_ResRoot, false)
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
			triggerClientEvent(self.el, "main.onLoginStatus", g_ResRoot, false)
		end
	else -- play as guest
		triggerClientEvent(self.el, "main.onLoginStatus", g_ResRoot, true)
	end
end

local function onRegisterReq(name, passwd, email)
	if(not name or name:len() < 3 or not passwd or passwd:len() < 3 or not email) then return end
	
	local self = g_Players[client]
	local account = false
	local ticks = getTickCount()
	if(ticks - g_RegTimeStamp >= 1000) then
		account = addAccount(name, passwd)
		if(account) then
			g_RegTimeStamp = ticks
			DbQuery("UPDATE rafalh_players SET email=? WHERE player=?", email, self.id)
		end
	else
		privMsg(self.el, "Wait a moment...")
	end
	triggerClientEvent(self.el, "main.onRegStatus", g_ResRoot, account and true)
end

local function onChgPwReq(oldPw, pw)
	local account = getPlayerAccount(client)
	if(isGuestAccount(account) or pw:len() < 3) then return end
	
	local status = getAccount(getAccountName(account), oldPw) and true
	if(status) then
		status = setAccountPassword(account, pw)
	end
	triggerClientEvent(client, "main.onChgPwResult", g_ResRoot, status)
end

local function onLogoutReq()
	logOut(client)
end

------------
-- Events --
------------

addEventHandler("onPlayerLogin", g_Root, onPlayerLogin)
addEventHandler("onPlayerLogout", g_Root, onPlayerLogout)
addEventHandler("main.onLogin", g_ResRoot, onLoginReq)
addEventHandler("main.onRegisterReq", g_ResRoot, onRegisterReq)
addEventHandler("main.onChgPwReq", g_ResRoot, onChgPwReq)
addEventHandler("main.onLogoutReq", g_ResRoot, onLogoutReq)

