local g_RegTimeStamp = 0

PlayersTable:addColumns{
	{'passwordRecoveryKey', 'VARCHAR(32)', null = true, default = false},
}

addEvent('main.onLogin', true)
addEvent('main.onRegisterReq', true)

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
			triggerClientEvent(self.el, 'main.onLoginStatus', g_ResRoot, false)
		end
	else -- play as guest
		triggerClientEvent(self.el, 'main.onLoginStatus', g_ResRoot, true)
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
			self.accountData:set('email', email)
		end
	else
		privMsg(self.el, "Wait a moment...")
	end
	triggerClientEvent(self.el, 'main.onRegStatus', g_ResRoot, account and true)
end

RPC.allow('logOutReq')
function logOutReq()
	logOut(client)
end

RPC.allow('changeAccountPassword')
function changeAccountPassword(oldPw, pw)
	local account = getPlayerAccount(client)
	if(isGuestAccount(account) or pw:len() < 3) then return false end
	
	-- Check if password is correct
	if(not getAccount(getAccountName(account), oldPw)) then return false end
	
	-- Change password
	return setAccountPassword(account, pw)
end

RPC.allow('changeAccountEmail')
function changeAccountEmail(email, pw)
	local player = Player.fromEl(client)
	local account = getPlayerAccount(player.el)
	if(isGuestAccount(account) or not email or not pw or pw:len() < 3) then return end
	
	local success = getAccount(getAccountName(account), pw) and true
	if(success) then
		success = email:match('^[%w%._-]+@[%w_-]+%.[%w%._-]+$') and true
	end
	
	if(success) then
		player.accountData.email = email
	end
	return success
end

RPC.allow('getAccountEmail')
function getAccountEmail()
	local player = Player.fromEl(client)
	return player.accountData.email
end

RPC.allow('passwordRecoveryReq')
function passwordRecoveryReq(email)
	local rows = DbQuery('SELECT player FROM '..PlayersTable..' WHERE email=?', email)
	local data = rows and rows[1]
	if(not data) then return false end -- account not found
	
	local key = md5(generateRandomStr(10)):sub(1, 16)
	local accountData = AccountData.create(data.player)
	local player = Player.fromEl(client)
	accountData.passwordRecoveryKey = key
	
	local mail = Mail()
	mail.to = email
	mail.subject = 'Password recovery'
	mail.body = 'Your key for reseting password: '..key..'\nUse /resetpw <key> to reset your password'
	mail.callback = function(status)
		if(status) then
			privMsg(player.el, "E-Mail has been sent!")
		else
			privMsg(player.el, "Failed to send E-Mail!")
		end
	end
	
	privMsg(player.el, "Sending email to %s...", email)
	if(not mail:send()) then
		privMsg(player.el, "Failed to send E-Mail!")
		return false
	end
	
	return true
end

local function CmdResetPw(message, arg)
	local sourcePlayer = Player.fromEl(source)
	local key = arg[2]
	
	if(key) then
		local rows = DbQuery('SELECT player, account FROM '..PlayersTable..' WHERE passwordRecoveryKey=? AND serial=?', key, sourcePlayer:getSerial())
		local data = rows and rows[1]
		if(data) then
			local newPw = md5(generateRandomStr(8)):sub(1, 8)
			local account = getAccount(data.account)
			local success = account and setAccountPassword(account, newPw)
			if(success) then
				local accountData = AccountData.create(data.player)
				accountData.passwordRecoveryKey = false
				privMsg(source, "Your account has been found: %s. Password has been changed to: %s", data.account, newPw)
			else
				privMsg(source, "Failed to reset password!")
			end
		else
			privMsg(source, "This key is invalid! Please generate new and try again.")
		end
	else privMsg(source, "Usage: %s", arg[1]..' <key_from_email>') end
end

CmdRegister('resetpw', CmdResetPw, false, "Allows to reset your password")

addInitFunc(function()
	addEventHandler('main.onLogin', g_ResRoot, onLoginReq)
	addEventHandler('main.onRegisterReq', g_ResRoot, onRegisterReq)
end)
