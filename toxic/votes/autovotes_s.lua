local RIGHTS = {kick = "command.kick", map = "command.setmap"}
local SETTING_NAMES = {kick = "*votemanager.votekick_enabled", map = "*votemanager.votemap_enabled"}
local g_Votes = {kick = false, map = false}

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

local function AvOnPlayerLogout()
    if Settings.auto_votekick then
        local enabled = AvCheckAllPlayers("kick", source)
        AvSetVoteEnabled("kick", enabled)
    end
    if Settings.auto_votemap then
        local enabled = AvCheckAllPlayers("map", source)
        AvSetVoteEnabled("map", enabled)
    end
end

local function AvOnPlayerLogin()
    if Settings.auto_votekick and hasObjectPermissionTo(source, RIGHTS.kick, false) then
        AvSetVoteEnabled("kick", false)
    end
    if Settings.auto_votemap and hasObjectPermissionTo(source, RIGHTS.map, false) then
        AvSetVoteEnabled("map", false)
    end
end

local function AvInit()
    local prof = DbgPerf()

    if Settings.auto_votekick then
        local enabled = AvCheckAllPlayers("kick")
        AvSetVoteEnabled("kick", enabled)
    end
    if Settings.auto_votemap then
        local enabled = AvCheckAllPlayers("map")
        AvSetVoteEnabled("map", enabled)
    end

    Event("onPlayerLogin"):addHandler(AvOnPlayerLogin)
    addEventHandler("onPlayerLogout", g_Root, AvOnPlayerLogout)
    addEventHandler("onPlayerQuit", g_Root, AvOnPlayerLogout)

    prof:cp("AutoVotes init")
end

addInitFunc(AvInit)
