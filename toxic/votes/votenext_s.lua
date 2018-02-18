local g_LastVotenext = 0
local g_VoteMgrRes = Resource('votemanager')

addEvent('toxic.onVotenextResult')
addEvent('onClientDisplayVotenextGuiReq', true)
addEvent('onVotenextReq', true)

local function onVotenextResult(roomEl, map_res)
    if (not map_res) then
        return
    end

    local room = Room(roomEl)
    local map = Map(map_res)
    if (not MqAdd(room, map, true)) then
        outputMsg(g_Root, Styles.red, "Map queue is full!")
    end
end

function VtnStart(pattern, player)
    if (not Settings.votenext_enabled) then
        privMsg(player, "Votenext is disabled!")
        return
    end

    local now = getTickCount()
    local votenext_locktime = Settings.votenext_locktime
    if (now - g_LastVotenext < votenext_locktime * 1000) then
        privMsg(player, "You have to wait %u seconds!", (votenext_locktime * 1000 - (now - g_LastVotenext)) / 1000)
        return
    end

    if (pattern == '') then
        triggerClientEvent(player, 'onClientDisplayVotenextGuiReq', g_ResRoot)
        return
    end

    local room = Player.fromEl(player).room
    local map = findMap(pattern)
    if (not map) then
        privMsg(player, 'Cannot find map "%s"!', pattern)
        return
    end

    if (MqGetMapPos(room, map)) then
        privMsg(player, "Next map is already set.")
        return
    end

    local forb_reason, arg = map:isForbidden(room)
    if (forb_reason) then
        privMsg(player, forb_reason, arg)
        return
    end

    local mapName = map:getName()
    if (not g_VoteMgrRes:isReady()) then
        return
    end

    -- Actual vote started here
    local pollDidStart =
        g_VoteMgrRes:call(
        'startPoll',
        {
            title = 'Set next map to ' .. mapName .. '?',
            percentage = Settings.votenext_percentage,
            timeout = Settings.votenext_timeout,
            allowchange = Settings.votenext_allowchange,
            visibleTo = g_Root,
            [1] = {'Yes', 'toxic.onVotenextResult', g_ResRoot, room.el, map.res},
            [2] = {'No', 'toxic.onVotenextResult', g_ResRoot, room.el, false, default = true}
        }
    )

    if (pollDidStart) then
        g_LastVotenext = now
        outputMsg(g_Root, Styles.maps, "%s started vote for next map: %s.", getPlayerName(player), mapName)
    else
        privMsg(player, "Error! Poll did not started.")
    end
end

local function onVotenextReq(map_res_name)
    VtnStart(map_res_name, client)
end

addInitFunc(
    function()
        addEventHandler('toxic.onVotenextResult', g_ResRoot, onVotenextResult)
        addEventHandler('onVotenextReq', g_ResRoot, onVotenextReq)
    end
)
