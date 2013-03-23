local g_MinFps = 0

local function AlCalcMinFps()
	g_MinFps = SmGetUInt("min_fps", 0)
	local min_fps_div = SmGetNum("min_fps_div", 0)
	
	if(min_fps_div > 0) then
		local fps_sum, c = 0, 0
		
		for player, p in pairs(g_Players) do
			local fps = tonumber(getElementData(player, "fps"))
			
			if(fps) then
				fps_sum = fps_sum + fps
				c = c + 1
			end
		end
		g_MinFps = math.min(g_MinFps, fps_sum/c/min_fps_div)
	end
end

local function AlCheckPlayer(player)
	local pdata = g_Players[player]
	local bGhostmode = GmIsEnabled(pdata.room)
	
	-- max ping
	local maxPing = SmGetUInt("max_ping", 0)
	local playerPing = getPlayerPing(player)
	local lags = pdata.lags
	
	if(maxPing > 0 and playerPing > maxPing) then -- lagger
		if(not bGhostmode and not isPedDead(player)) then -- player can collide
			local maxPingTime = SmGetUInt ( "max_ping_time", 0 )
			local ticks = getTickCount ()
			
			if (not lags) then
				lags = { ticks, nil, 0 }
			else
				lags[3] = lags[3] + ticks - lags[1]
				lags[1] = ticks
			end
			
			if(lags[3] > maxPingTime*1000) then
				scriptMsg("Kicking %s for lagging. His ping: %u. Maximal ping: %u.", getPlayerName(player), playerPing, maxPing)
				return kickPlayer ( player, "Too high ping" )
			elseif(lags[3] > maxPingTime*1000/2 and not lags[2]) then
				lags[2] = addScreenMsg("Warning! Your ping is to high!", player)
			end
		elseif(lags and lags[2]) then -- remove screen message
			removeScreenMsg(lags[2], player)
			lags[2] = nil
		end
	elseif(lags) then -- ping is ok
		if(lags[2]) then
			removeScreenMsg(lags[2], player)
		end
		lags = nil
	end
	pdata.lags = lags
	
	-- min fps
	if(g_MinFps > 0) then
		local lowfps = pdata.lowfps
		local fps = tonumber(getElementData(player, "fps"))
		
		if(fps and fps < g_MinFps) then -- lagger
			if(not bGhostmode and not isPedDead(player)) then -- player can collide
				local ticks = getTickCount()
				
				if(not lowfps) then
					lowfps = {ticks, nil, 0}
				else
					lowfps[3] = lowfps[3] + ticks - lowfps[1]
					lowfps[1] = ticks
				end
				
				if(lowfps[3] > 30000) then
					scriptMsg("Kicking %s for too low FPS. His FPS: %u. Minimal FPS: %.1f.", getPlayerName(player), fps, g_MinFps)
					return kickPlayer(player, "FPS is too low")
				elseif(lowfps[3] > 15000 and not lowfps[2]) then
					lowfps[2] = addScreenMsg("Warning! Your FPS is too low!", player)
				end
			elseif(lowfps and lowfps[2]) then -- remove screen message
				removeScreenMsg(lowfps[2], player)
				lowfps[2] = nil
			end
		elseif(lowfps) then -- fps is ok
			if(lowfps[2]) then
				removeScreenMsg(lowfps[2], player)
			end
			lowfps = nil
		end
		
		pdata.lowfps = lowfps
	end
	
	return false
end

local function AlCheckAllPlayers ()
	AlCalcMinFps()
	
	for player, pdata in pairs(g_Players) do
		if(not pdata.is_console) then
			AlCheckPlayer(player)
		end
	end
end

local function AlInit ()
	setTimer(AlCheckAllPlayers, 1000, 0)
end

local function CmdMinFps(message, arg)
	scriptMsg("Minimal FPS: %u.", g_MinFps)
end

CmdRegister("minfps", CmdMinFps, false)

local function CmdMaxPing(message, arg)
	local max_ping = SmGetUInt("max_ping", 0)
	if ( max_ping > 0 ) then
		scriptMsg("Maximal ping: %u.", max_ping)
	else
		scriptMsg("Maximal ping: disabled.")
	end
end

CmdRegister("maxping", CmdMaxPing, false)

addInitFunc(AlInit)
