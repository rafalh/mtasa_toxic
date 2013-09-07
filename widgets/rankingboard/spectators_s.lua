local g_Players = {}

local function getPlayerSpectators(player)
	local ret = {}
	for player2, pdata in pairs(g_Players) do
		if(player2 ~= player and getCameraTarget(player2) == player) then
			table.insert(ret, player2)
		end
	end
	return ret
end

local function tableCmp(tbl1, tbl2)
	if(#tbl1 ~= #tbl2) then return false end
	for i, v in ipairs(tbl1) do
		if(tbl2[i] ~= v) then return false end
	end
	return true
end

local function updateSpectators()
	for player, specList in pairs(g_Players) do
		local target = getCameraTarget(player)
		if(target) then
			local newSpecList = getPlayerSpectators(target)
			--outputDebugString(getPlayerName(player)..' - '..getPlayerName(target)..' has '..#newSpecList..' spectators', 3)
			
			if(not tableCmp(specList, newSpecList)) then
				g_Players[player] = newSpecList
				triggerClientEvent(player, 'rb.onSpecListChange', resourceRoot, newSpecList)
			end
		else
			--outputDebugString('no target', 3)
		end
	end
end

local function onPlayerJoin()
	g_Players[source] = {}
end

local function onPlayerQuit()
	g_Players[source] = nil
end

local function init()
	setTimer(updateSpectators, 1000, 0)
	for i, player in ipairs(getElementsByType('player')) do
		g_Players[player] = {}
	end
	
	addEventHandler('onPlayerJoin', root, onPlayerJoin)
	addEventHandler('onPlayerQuit', root, onPlayerQuit)
end

addEventHandler('onResourceStart', resourceRoot, init)
