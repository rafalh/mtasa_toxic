local function IvTimerProc ( player )
	-- give award for player who invited
	local pdata = Player.fromEl(player)
	
	local invitedby = pdata.accountData:get("invitedby")
	if(invitedby > 0) then
		pdata.accountData:set("invitedby", 0)
		PlayerAccountData.create(invitedby):add("cash", 1000000)
		
		local invitedbyPlayer = Player.fromId(invitedby)
		if(invitedbyPlayer) then
			privMsg(invitedbyPlayer.el, "You get %s for inviting %s!", formatMoney(1000000), getPlayerName(player))
		end
	end
end

local function IvNewPlayer(player)
	local pdata = Player.fromEl(player)
	local playtime = pdata:getPlayTime()
	
	if(playtime < 10*3600) then
		setPlayerTimer(IvTimerProc, (10*3600 - playtime) * 1000, 1, player)
	end
end

local function IvOnPlayerJoin()
	IvNewPlayer(source)
end

local function IvInit()
	for player, pdata in pairs(g_Players) do
		IvNewPlayer(player)
	end
	
	addEventHandler("onPlayerJoin", g_Root, IvOnPlayerJoin)
end

addInitFunc(IvInit)
