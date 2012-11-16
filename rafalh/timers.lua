local g_MapTimers = {}

local function TmPlayerTimerProc ( timer_id, player, ... )
	local pdata = g_Players[player]
	assert ( pdata )
	
	local func = pdata.timers[timer_id].f
	pdata.timers[timer_id] = nil
	func ( player, ... )
end

function setPlayerTimer ( func, interval, timesToExecute, player, ... )
	local timer_id = #g_Players[player].timers + 1
	assert ( func and player )
	local timer = setTimer ( TmPlayerTimerProc, interval, timesToExecute, timer_id, player, ... )
	if ( timer ) then
		g_Players[player].timers[timer_id] = { t = timer, f = func }
	end
	return timer
end

local function TmMapTimerProc ( timer_id, ... )
	local func = g_MapTimers[timer_id].f
	g_MapTimers[timer_id] = nil
	func ( ... )
end

function setMapTimer ( func, interval, timesToExecute, ... )
	local timer_id = #g_MapTimers + 1
	local timer = setTimer ( TmMapTimerProc, interval, timesToExecute, timer_id, ... )
	g_MapTimers[timer_id] = { t = timer, f = func }
end

local function TmPlayerQuit ()
	local pdata = g_Players[source]
	assert ( pdata )
	
	for id, data in pairs ( pdata.timers ) do -- ipair is wrong here
		killTimer ( data.t )
	end
	pdata.timers = {}
end

local function TmMapStop ()
	for id, data in pairs ( g_MapTimers ) do -- ipair is wrong here
		killTimer ( data.t )
	end
	g_MapTimers = {}
end

addEventHandler ( "onGamemodeMapStop", g_Root, TmMapStop )
addEventHandler ( "onPlayerQuit", g_Root, TmPlayerQuit )
