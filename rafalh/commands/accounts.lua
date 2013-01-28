-------------
-- Globals --
-------------

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
