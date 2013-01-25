-------------
-- Globals --
-------------

local function CmdChangePassword (message, arg)
	local account = getPlayerAccount (source)
	if (isGuestAccount (account)) then
		privMsg (source, "You have to be logged in to use this command.")
		return
	end
	
	if (#arg >= 4 and getAccount (getAccountName (account), arg[2]) and arg[3] == arg[4]) then
		if (arg[3]:len () >= 4) then
			if (setAccountPassword (account, arg[3])) then
				privMsg (source, "Password has been changed successfully!")
			else
				privMsg (source, "Unknown error! Failed to change password.")
			end
		else
			privMsg (source, "Password should be at least 4 characters long!")
		end
	else privMsg (source, "Usage: %s", arg[1].." <old password> <new password> <retry new password>") end
end

CmdRegister ("changepassword", CmdChangePassword, false)
CmdRegisterAlias ("chgpw", "changepassword")

--[[local function CmdChangeLogin(message, arg)
	local account = getPlayerAccount (source)
	if (isGuestAccount (account)) then
		privMsg(source, "You have to be logged in to use this command.")
		return
	end
	
	local account_name = getAccountName (account)
	if (#arg >= 3 and getAccount (account_name, arg[3])) then
		local new_account = addAccount (arg[2], arg[3])
		if (new_account and copyAccountData (new_account, account)) then
			for i, acl_group in ipairs (aclGroupList ()) do
				if (isObjectInACLGroup ("user."..account_name, acl_group) and aclGroupAddObject (acl_group, "user."..arg[2])) then
					aclGroupRemoveObject (acl_group, "user."..account_name)
				end
			end
			
			logOut (source)
			logIn (source, new_account, arg[3])
			removeAccount (account)
			
			privMsg(source, "Login has been changed successfully!")
		else
			privMsg(source, "Unknown error! Failed to change login.")
		end
	else privMsg(source, "Usage: %s", arg[1].." <new login> <password>") end
end

CmdRegister ("changelogin", CmdChangeLogin, false)
CmdRegisterAlias ("chglogin", "changelogin")]]
