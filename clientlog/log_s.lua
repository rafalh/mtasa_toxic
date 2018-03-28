local LEVEL_NAMES = { 'ERROR', 'WARNING', 'INFO' }

local g_resName = getResourceName(resource)

addEvent('onPlayerDebugMessage', true)
addEvent('onReady', true)

addEventHandler('onPlayerDebugMessage', resourceRoot, function (message, level, file, line, num)
    local levelStr = LEVEL_NAMES[level] or 'CUSTOM'
    local playerName = getPlayerName(client)
    local location = file and line and tostring(file)..':'..tostring(line)..': ' or ''
    
    local debugConsoleSetting = get('*'..g_resName..'.debugConsole')
    local logMsg = 'CLIENT_'..levelStr..' ('..playerName..'): '..location..tostring(message)
    if num > 1 then
        logMsg = logMsg..' [DUP x'..num..']'
    end
    if debugConsoleSetting == 'true' then
        outputDebugString(logMsg, level)
    else
        outputServerLog(logMsg)
    end
end)

addEventHandler('onReady', resourceRoot, function (message, level, file, line)
    local settings = {
        maxLevel = get('*'..g_resName..'.maxLevel'),
        msgIncludeFilter = get('*'..g_resName..'.msgIncludeFilter'),
        msgExcludeFilter = get('*'..g_resName..'.msgExcludeFilter'),
        locationIncludeFilter = get('*'..g_resName..'.locationIncludeFilter'),
        locationExcludeFilter = get('*'..g_resName..'.locationExcludeFilter'),
    }
    triggerClientEvent(client, 'onClientInit', resourceRoot, settings)
end)
