local g_RegTimeStamp = 0
local g_LastMailTicks = 0

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
	
	local ticks = getTickCount()
	if(ticks - g_LastMailTicks < 10*1000) then
		privMsg(client, "SPAM protection! Please try again later.")
		return false
	end
	g_LastMailTicks = ticks
	
	local key = md5(generateRandomStr(10)):sub(1, 16)
	local accountData = AccountData.create(data.player)
	local player = Player.fromEl(client)
	accountData.passwordRecoveryKey = key
	
	local serverNameFiltered = trimStr(getServerName():gsub('[^%w%s%p]', ''))
	
	local playerName = accountData.name:gsub('#%x%x%x%x%x%x', '')
	local mail = Mail()
	mail.to = email
	mail.toTitle = playerName
	mail.subject = 'Password recovery - '..serverNameFiltered
	mail.body =
		'Hello '..playerName..',\n\n'..
		'You are receiving this notification because you have (or someone pretending to be you has) requested a new password '..
		'to be sent for your account on MTA Server "'..serverNameFiltered..'". If you did not request this notification then please ignore it. If you keep receiving it please contact the server administrator.\n\n'..
		'To use the new password you need to activate it. To do this execute command provided below in server chat:\n'..
		'/resetpw '..key..'\n\n'..
		'If successful new password will be shown in chatbox. You can of course change this password yourself via the profile page in User Panel.\n\n'..
		'*** This is an automatically generated email - please do not reply to it. ***'
	mail.callback = function(status)
		if(status) then
			outputMsg(player, Styles.green, "E-Mail has been sent to %s! Check your mail box and follow instructions given to you in message.", email)
		else
			outputMsg(player, Styles.red, "Failed to send E-Mail!")
		end
	end
	
	if(not mail:send()) then
		outputMsg(player, Styles.red, "Failed to send E-Mail!")
		return false
	end
	
	return true
end

CmdMgr.register{
	name = 'resetpw',
	desc = "Allows you to reset your password in case you forgot it",
	args = {
		{'key', type = 'string'},
	},
	func = function(ctx, key)
		local rows = DbQuery('SELECT player, account FROM '..PlayersTable..' WHERE passwordRecoveryKey=? AND serial=?', key, ctx.player:getSerial())
		local data = rows and rows[1]
		if(not data) then
			outputMsg(ctx.player, Styles.red, "Failed to reset password. Please generate a new key and try again.")
			return
		end
		
		local newPw = md5(generateRandomStr(8)):sub(1, 8)
		local account = getAccount(data.account)
		local success = account and setAccountPassword(account, newPw)
		if(success) then
			local accountData = AccountData.create(data.player)
			accountData.passwordRecoveryKey = false
			outputMsg(ctx.player, Styles.green, "Password has been successfully changed. Your login credentials: username \"%s\", password \"%s\".", 
				data.account, newPw)
		else
			outputMsg(ctx.player, Styles.red, "Failed to reset password. Please contact administrator.")
		end
	end
}

addInitFunc(function()
	addEventHandler('main.onLogin', g_ResRoot, onLoginReq)
	addEventHandler('main.onRegisterReq', g_ResRoot, onRegisterReq)
end)
