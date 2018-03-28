local MAX_QUEUE_SIZE = 20
local DUP_DELAY_MS = 5000

local g_settings
local g_recentMsgs = {}
local g_queue = {}
local g_lastSendTicks
local g_queueTimer

local function isMsgFilteredOut(message, level, file, line)
    if not g_settings then return true end

    if level == 0 or level > tonumber(g_settings.maxLevel) then return true end

    if g_settings.msgIncludeFilter ~= '' and pregFind(message, g_settings.msgIncludeFilter) then return false end
    if g_settings.msgExcludeFilter ~= '' and pregFind(message, g_settings.msgExcludeFilter) then return true end

    local location = file and line and file..':'..line
    if location and g_settings.locationIncludeFilter ~= '' and pregFind(location, g_settings.locationIncludeFilter) then return false end
    if location and g_settings.locationExcludeFilter ~= '' and pregFind(location, g_settings.locationExcludeFilter) then return true end

    return false
end

local function flushQueue()
    local now = getTickCount()
    if #g_queue > 0 and (not g_lastSendTicks or now - g_lastSendTicks > 300) then
        local data = table.remove(g_queue, 1)
        g_lastSendTicks = now
        triggerServerEvent('onPlayerDebugMessage', resourceRoot, unpack(data))
    end
    if #g_queue > 0 and not g_queueTimer then
        g_queueTimer = setTimer(function ()
            g_queueTimer = nil
            flushQueue()
        end, 500, 1)
    end
end

local function sendDbgMsgToServer(message, level, file, line, num)
    if #g_queue < MAX_QUEUE_SIZE then
        table.insert(g_queue, {message, level, file, line, num})
    end
    flushQueue()
end

addEventHandler('onClientDebugMessage', root, function (message, level, file, line)
    if isMsgFilteredOut(message, level, file, line) then return end

    local msgKey = table.concat({level, file or '', line or 0, message}, '/')
    local num = g_recentMsgs[msgKey]
    
    if num then
        g_recentMsgs[msgKey] = num + 1
    else
        sendDbgMsgToServer(message, level, file, line, 1)
        g_recentMsgs[msgKey] = 0

        setTimer(function ()
            local num = g_recentMsgs[msgKey]
            g_recentMsgs[msgKey] = nil
            if num > 0 then
                sendDbgMsgToServer(message, level, file, line, num)
            end
        end, DUP_DELAY_MS, 1)
    end
end)

addEventHandler('onClientResourceStart', resourceRoot, function ()
    triggerServerEvent('onReady', resourceRoot)
end)

addEvent('onClientInit', true)
addEventHandler('onClientInit', resourceRoot, function (settings)
    g_settings = settings
end)

addCommandHandler('testerror', function ()
    nonExistingFunction()
end)
