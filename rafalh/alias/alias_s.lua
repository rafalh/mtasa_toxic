local function AlAddPlayerAlias(player, name)
	name = name:gsub("#%x%x%x%x%x%x", "")
	local pdata = Player.fromEl(player)
	if(not pdata.id) then return end -- guest
	
	local rows = DbQuery("SELECT player FROM rafalh_names WHERE player=? AND name=? LIMIT 1", pdata.id, name)
	if(not rows or not rows[1]) then
		DbQuery("INSERT INTO rafalh_names (player, name) VALUES (?, ?)", pdata.id, name)
	end
end

local function AlOnPlayerChangeNick(oldNick, newNick)
	if(wasEventCancelled()) then return end
	
	if(Player.fromEl(source)) then
		AlAddPlayerAlias(source, newNick)
	end
end

local function AlOnPlayerJoin()
	AlAddPlayerAlias(source, getPlayerName(source))
end

local function AlInit()
	for player, pdata in pairs(g_Players) do
		AlAddPlayerAlias(player, getPlayerName(player))
	end
	
	addEventHandler("onPlayerJoin", g_Root, AlOnPlayerJoin)
	addEventHandler("onPlayerChangeNick", g_Root, AlOnPlayerChangeNick)
end

addInitFunc(AlInit)