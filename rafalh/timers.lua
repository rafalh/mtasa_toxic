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

local function TmMapTimerProc ( roomEl, timer_id, ... )
	local room = Room.elMap[roomEl]
	local func = room.mapTimers[timer_id].f
	room.mapTimers[timer_id] = nil
	func (room, ...)
end

function setMapTimer ( func, interval, timesToExecute, room, ... )
	assert(type(room) == "table")
	if(not room.mapTimers) then
		room.mapTimers = {}
	end
	local timer_id = #room.mapTimers + 1
	local timer = setTimer ( TmMapTimerProc, interval, timesToExecute, room.el, timer_id, ... )
	room.mapTimers[timer_id] = { t = timer, f = func }
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
