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
			local specList = getPlayerSpectators(target)
			--outputDebugString(getPlayerName(player)..' - '..getPlayerName(target)..' has '..#specList..' spectators', 3)
			
			local specNameList = {}
			for i, player2 in ipairs(specList) do
				local r, g, b = getPlayerNametagColor(player2)
				local name = getPlayerName(player2)
				table.insert(specNameList, ('#%02X%02X%02X%s'):format(r, g, b, name))
			end
			
			local spectatorsStr = #specNameList > 0 and table.concat(specNameList, '#FFFFFF, ')
			if(pdata.lastSpecList ~= spectatorsStr) then
				pdata.lastSpecList = spectatorsStr
				triggerClientEvent(player, 'onClientSetSpectators', g_Root, spectatorsStr)
				triggerClientEvent(player, 'toxic.onSpecListChange', g_Root, specList)
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
