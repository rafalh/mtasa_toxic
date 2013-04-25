local g_FadeInFinTimer = false

local function onFadeInFinish()
	triggerEvent('onClientScreenFadedIn', root)
	g_FadeInFinTimer = false
end

local _fadeCamera = fadeCamera
function fadeCamera(fadeIn, timeToFade, ...)
	_fadeCamera(fadeIn, timeToFade, ...)
	
	if(not fadeIn) then
		if(g_FadeInFinTimer) then
			killTimer(g_FadeInFinTimer)
			g_FadeInFinTimer = false
		end
		triggerEvent('onClientScreenFadedOut', root)
	else
		local ticksToFade = (not timeToFade or timeToFade < 1) and 0 or timeToFade * 1000
		g_FadeInFinTimer = setTimer(onFadeInFinish, math.max(50, ticksToFade/8), 1)
	end
end

function resAdjust(num)
	if not g_ScrW then
		g_ScrW, g_ScrH = guiGetScreenSize()
	end
	if g_ScrW < 1280 then
		return math.floor(num*g_ScrW/1280)
	else
		return num
	end
end

function math.clamp(low, value, high)
    return math.max(low, math.min(value,high))
end

function showHUD(show)
	for i,name in ipairs({ 'ammo', 'area_name', 'armour', 'breath', 'clock', 'health', 'money', 'vehicle_name', 'weapon' }) do
		showPlayerHudComponent(name, show)
	end
end

function showGUIComponents(...)
	for i,name in ipairs({...}) do
		if g_dxGUI[name] then
			g_dxGUI[name]:visible(true)
		elseif type(g_GUI[name]) == 'table' then
			g_GUI[name]:show()
		else
			guiSetVisible(g_GUI[name], true)
		end
	end
end

function hideGUIComponents(...)
	for i,name in ipairs({...}) do
		if g_dxGUI[name] then
			g_dxGUI[name]:visible(false)
		elseif type(g_GUI[name]) == 'table' then
			g_GUI[name]:hide()
		else
			guiSetVisible(g_GUI[name], false)
		end
	end
end

function setGUIComponentsVisible(settings)
	for name,visible in pairs(settings) do
		if type(g_GUI[name]) == 'table' then
			g_GUI[name][visible and 'show' or 'hide'](g_GUI[name])
		else
			guiSetVisible(g_GUI[name], visible)
		end
	end
end

function msToTimeStr(ms)
	if not ms then
		return ''
	end
	local centiseconds = tostring(math.floor(math.fmod(ms, 1000)/10))
	if #centiseconds == 1 then
		centiseconds = '0' .. centiseconds
	end
	local s = math.floor(ms / 1000)
	local seconds = tostring(math.fmod(s, 60))
	if #seconds == 1 then
		seconds = '0' .. seconds
	end
	local minutes = tostring(math.floor(s / 60))
	return minutes .. ':' .. seconds .. ':' .. centiseconds
end
