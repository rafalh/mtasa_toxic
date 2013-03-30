local g_RegTimeStamp = 0

addEvent("main.onLogin", true)
addEvent("main.onRegisterReq", true)
addEvent("main.onEmailReq", true)
addEvent("main.onChgPwReq", true)
addEvent("main.onChgEmailReq", true)
addEvent("main.onLogoutReq", true)

local function onLoginReq(name, passwd)
	local self = Player.fromEl(client)
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
	
	local self = Player.fromEl(client)
	local account = false
	local ticks = getTickCount()
	if(ticks - g_RegTimeStamp >= 1000) then
		account = addAccount(name, passwd)
		if(account) then
			g_RegTimeStamp = ticks
			self.accountData:set("email", email)
		end
	else
		privMsg(self.el, "Wait a moment...")
	end
	triggerClientEvent(self.el, "main.onRegStatus", g_ResRoot, account and true)
end

local function onChgPwReq(oldPw, pw)
	local account = getPlayerAccount(client)
	if(isGuestAccount(account) or pw:len() < 3) then return end
	
	local success = getAccount(getAccountName(account), oldPw) and true
	if(success) then
		success = setAccountPassword(account, pw)
	end
	triggerClientEvent(client, "main.onChgPwResult", g_ResRoot, success)
end

local function onEmailReq()
	local player = Player.fromEl(client)
	triggerClientEvent(client, "main.onEmail", g_ResRoot, player.accountData.email)
end

local function onChgEmailReq(email, pw)
	local player = Player.fromEl(client)
	local account = getPlayerAccount(player.el)
	if(isGuestAccount(account) or not email or not pw or pw:len() < 3) then return end
	
	local success = getAccount(getAccountName(account), pw) and true
	if(success) then
		success = email:match("^[%w%._-]+@[%w_-]+%.[%w%._-]+$") and true
	end
	
	if(success) then
		player.accountData.email = email
	end
	triggerClientEvent(client, "main.onChgEmailResult", g_ResRoot, success)
end

local function onLogoutReq()
	logOut(client)
end

addInitFunc(function()
	addEventHandler("main.onLogin", g_ResRoot, onLoginReq)
	addEventHandler("main.onRegisterReq", g_ResRoot, onRegisterReq)
	addEventHandler("main.onChgPwReq", g_ResRoot, onChgPwReq)
	addEventHandler("main.onChgEmailReq", g_ResRoot, onChgEmailReq)
	addEventHandler("main.onEmailReq", g_ResRoot, onEmailReq)
	addEventHandler("main.onLogoutReq", g_ResRoot, onLogoutReq)
end)
