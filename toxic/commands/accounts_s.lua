-- TODO: move it to GUI
#if(false) then

CmdMgr.register{
	name = 'changelogin',
	desc = "Changes player username",
	aliases = {'chglogin'},
	args = {
		{'newAccountName', type = 'str'},
		{'password', type = 'str'},
	},
	func = function(ctx, newAccName, passwd)
		local oldAccount = getPlayerAccount(ctx.player.el)
		if(isGuestAccount(oldAccount)) then
			privMsg(ctx.player, "You have to be logged in to use this command.")
			return
		end
		
		local oldAccName = getAccountName(oldAccount)
		if(not getAccount(oldAccName, passwd)) then
			privMsg(ctx.player, "Wrong password!")
			return
		end
		
		local newAccount = addAccount(newAccName, passwd)
		if(not newAccount) then
			privMsg(ctx.player, "Failed to create new account!")
			return
		end
		
		if(not copyAccountData(newAccount, oldAccount)) then
			privMsg(ctx.player, "Failed to copy account data!")
			removeAccount(newAccount)
			return
		end
		
		for i, aclGroup in ipairs(aclGroupList()) do
			if(isObjectInACLGroup('user.'..oldAccName, aclGroup) and aclGroupAddObject(aclGroup, 'user.'..newAccName)) then
				aclGroupRemoveObject(aclGroup, 'user.'..oldAccName)
			end
		end
		
		local playerId = ctx.player.id
		logOut(ctx.player.el)
		AccountData.create(playerId):set('account', newAccName)
		logIn(ctx.player.el, newAccount, passwd)
		removeAccount(oldAccount)
		
		privMsg(ctx.player, "Login has been changed successfully!")
	end
}

#end
