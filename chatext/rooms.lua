local g_ReadyPlayers = {}

local g_ModRoom = ChatRoom.create{
	id = "mod",
	key = "u",
	inputPrefix = "Modsay:",
	chatPrefix = "(MOD) ",
	logPrefix = "MODSAY: ",
	cmd = "modsay",
	checkAccess = function(sender)
		return hasObjectPermissionTo(sender, "resource.rafalh_modchat", false)
	end,
	disabled = true,
	getPlayers = function(sender)
		local recipients = {}
		for i, player in ipairs(getElementsByType("player")) do
			if(hasObjectPermissionTo(player, "resource.rafalh_modchat", false)) then
				table.insert(recipients, player)
			end
		end
		return recipients
	end
}

local g_LangRoom = ChatRoom.create{
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

addEvent("chatext.onModVerified", true)
addEvent("chatext.onReady", true)

local function onPlayerReady()
	g_ReadyPlayers[client] = true
	if(hasObjectPermissionTo(client, "resource.rafalh_modchat", false)) then
		triggerClientEvent(client, "chatext.onModVerified", resourceRoot)
	end
end

local function onModVerified()
	g_ModRoom:enable()
end

local function onPlayerLogin()
	if(g_ReadyPlayers[source] and hasObjectPermissionTo(source, "resource.rafalh_modchat", false)) then
		triggerClientEvent(source, "chatext.onModVerified", resourceRoot)
	end
end

local function onPlayerQuit()
	g_ReadyPlayers[source] = nil
end

addEventHandler("chatext.onReady", resourceRoot, onPlayerReady)
addEventHandler("chatext.onModVerified", resourceRoot, onModVerified)
addEventHandler("onPlayerLogin", root, onPlayerLogin)
addEventHandler("onPlayerQuit", root, onPlayerQuit)
