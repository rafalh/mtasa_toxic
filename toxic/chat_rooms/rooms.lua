local g_ModChatRight = AccessRight('modchat')
ChatRoom.create{
	id = "mod",
	key = "u",
	inputPrefix = "Modsay:",
	chatPrefix = "(MOD) ",
	logPrefix = "MODSAY: ",
	cmd = "modsay",
	right = g_ModChatRight,
	getPlayers = function(self, sender)
		local recipients = {}
		for i, player in ipairs(getElementsByType("player")) do
			if(g_ModChatRight:check(player)) then
				table.insert(recipients, player)
			end
		end
		return recipients
	end
}

ChatRoom.create{
	id = "lang",
	key = "l",
	inputPrefix = function(player)
		local lang = getElementData(player, "country") or "EN"
		return lang..":"
	end,
	chatPrefix = function(player)
		local lang = getElementData(player, "country") or "EN"
		return "("..lang..") "
	end,
	logPrefix = function(player)
		local lang = getElementData(player, "country") or "EN"
		return lang.."SAY: "
	end,
	cmd = "langsay",
	getPlayers = function(sender)
		local lang = getElementData(sender, "country")
		local recipients = {}
		for i, player in ipairs(getElementsByType("player")) do
			if(getElementData(player, "country") == lang) then
				table.insert(recipients, player)
			--else
			--	assert(player ~= sender)
			end
		end
		
		return recipients
	end
}
