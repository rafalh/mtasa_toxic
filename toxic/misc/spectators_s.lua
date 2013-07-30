local function getPlayerSpectators(player)
	local ret = {}
	for player2, pdata in pairs(g_Players) do
		if(not pdata.is_console and player2 ~= player and getCameraTarget(player2) == player) then
			table.insert(ret, player2)
		end
	end
	return ret
end

local function updateSpectators()
	for player, pdata in pairs(g_Players) do
		local target = not pdata.is_console and getCameraTarget(player)
		if(target) then
			local spectators = getPlayerSpectators(target)
			--outputDebugString(getPlayerName(player)..' - '..getPlayerName(target)..' has '..#spectators..' spectators', 3)
			for i, player2 in ipairs(spectators) do
				local r, g, b = getPlayerNametagColor(player2)
				local name = getPlayerName(player2)
				spectators[i] = ('#%02X%02X%02X%s'):format(r, g, b, name)
			end
			local spectatorsStr = #spectators > 0 and table.concat(spectators, '#FFFFFF, ')
			if(pdata.lastSpecList ~= spectatorsStr) then
				pdata.lastSpecList = spectatorsStr
				triggerClientEvent(player, 'onClientSetSpectators', g_Root, spectatorsStr)
			end
		else
			--outputDebugString('no target', 3)
		end
	end
end

local function init()
	setTimer(updateSpectators, 1000, 0)
end

addInitFunc(init)
