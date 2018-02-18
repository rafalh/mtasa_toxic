local RIGHTS = {kick = 'command.kick', map = 'command.setmap'}
local SETTING_NAMES = {kick = '*votemanager.votekick_enabled', map = '*votemanager.votemap_enabled'}
local g_Votes = {kick = false, map = false}
local g_MinDurationPassed = false
local g_RaceRes = Resource('race')

local function AvSetVoteEnabled(voteType, enabled)
    if g_Votes[voteType] == enabled then
        return
    end
    g_Votes[voteType] = enabled
    set(SETTING_NAMES[voteType], enabled)
end

local function AvCheckAllPlayers(voteType, ignored)
    local vote = true
    local right = RIGHTS[voteType]

    for player, pdata in pairs(g_Players) do
        if not pdata.is_console and player ~= ignored and hasObjectPermissionTo(player, right, false) then
            return false
        end
    end

    return true
end

local function AvUpdateVotekick(ignored)
	if Settings.auto_votekick then
        local enabled = AvCheckAllPlayers('kick', ignored)
        AvSetVoteEnabled('kick', enabled)
    end
end

local function AvUpdateVotemap(ignored)
    if Settings.auto_votemap then
        local enabled = AvCheckAllPlayers('map', ignored) and g_MinDurationPassed
        AvSetVoteEnabled('map', enabled)
    end
end

local function AvOnPlayerLogout()
	AvUpdateVotekick(source)
	AvUpdateVotemap(source)
end

local function AvOnPlayerLogin()
    if Settings.auto_votekick and hasObjectPermissionTo(source, RIGHTS.kick, false) then
        AvSetVoteEnabled('kick', false)
    end
    if Settings.auto_votemap and hasObjectPermissionTo(source, RIGHTS.map, false) then
        AvSetVoteEnabled('map', false)
    end
end

local function AvAfterMapDuration()
	g_MinDurationPassed = true
	AvUpdateVotemap()
end

local function AvOnMapStart()
    g_MinDurationPassed = false
    local lockTimeSec = Settings.votemap_lock_time_sec
	setMapTimer(AvAfterMapDuration, lockTimeSec*1000, 1, g_RootRoom)
end

local function AvInit()
    local prof = DbgPerf()

    local ms = g_RaceRes:isReady() and g_RaceRes:call('getTimePassed')
    local lockTimeSec = Settings.votemap_lock_time_sec
	if ms and ms > lockTimeSec*1000 then
		g_MinDurationPassed = true
	end

	AvUpdateVotekick()
	AvUpdateVotemap()

    Event('onPlayerLogin'):addHandler(AvOnPlayerLogin)
    addEventHandler('onPlayerLogout', g_Root, AvOnPlayerLogout)
	addEventHandler('onPlayerQuit', g_Root, AvOnPlayerLogout)
	addEventHandler('onGamemodeMapStart', g_Root, AvOnMapStart)

    prof:cp('AutoVotes init')
end

addInitFunc(AvInit)
