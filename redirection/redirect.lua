local g_ResName = getResourceName(getThisResource())

addEvent("redirect.onReq", true)
addEvent("redirect.onReady", true)

local function onRedirectRequest()
	redirectPlayer(client, get("ip"), tonumber(get("port")))
end

local function findPlayer(str)
	if(not str) then
		return false
	end
	
	local player = getPlayerFromName(str) -- returns player or false
	if(player) then
		return player
	end
	
	str = str:upper()
	for i, player in ipairs(getElementsByType("player")) do
		if(getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):upper():find(str, 1, true) ) then
			return player
		end
	end
	return false
end

local function cmdRedirect(source, cmd, name)
	local player = source
	if(hasObjectPermissionTo(player, "resource."..g_ResName, false)) then
		player = name:len() > 1 and findPlayer(name)
	end
	if(player) then
		redirectPlayer(player, get("ip"), tonumber(get("port")))
	end
end

local function onPlayerReady()
	if(get("redirect_all") == "true") then
		triggerClientEvent(client, "redirect.onDisplayWndReq", resourceRoot, get("ip")..":"..get("port"))
	end
end

addEventHandler("redirect.onReq", resourceRoot, onRedirectRequest)
addEventHandler("redirect.onReady", resourceRoot, onPlayerReady)
addCommandHandler(get("redirect_cmd") or "redirect", cmdRedirect, false, false)
