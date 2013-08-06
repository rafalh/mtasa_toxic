local function CmdChangeLogin(message, arg)
	local oldAccount = getPlayerAccount(source)
	if(isGuestAccount(oldAccount)) then
		privMsg(source, "You have to be logged in to use this command.")
		return
	end
	
	local player = Player.fromEl(source)
	local oldAccName = getAccountName(oldAccount)
	local newAccName, passwd = arg[2], arg[3]
	if(newAccName and passwd and getAccount(oldAccName, passwd)) then
		local newAccount = addAccount(newAccName, passwd)
		if(newAccount and copyAccountData(newAccount, oldAccount)) then
			for i, aclGroup in ipairs(aclGroupList()) do
				if(isObjectInACLGroup('user.'..oldAccName, aclGroup) and aclGroupAddObject(aclGroup, 'user.'..newAccName)) then
					aclGroupRemoveObject(aclGroup, 'user.'..oldAccName)
				end
			end
			
			local playerId = player.id
			logOut(source)
			AccountData.create(playerId):set('account', newAccName)
			logIn(source, newAccount, passwd)
			removeAccount(oldAccount)
			
			privMsg(source, "Login has been changed successfully!")
		else
			privMsg(source, "Unknown error! Failed to change login.")
		end
	else privMsg(source, "Usage: %s", arg[1]..' <new login> <password>') end
end

CmdRegister('changelogin', CmdChangeLogin, true)
CmdRegisterAlias('chglogin', 'changelogin')
