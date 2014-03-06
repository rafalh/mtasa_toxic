namespace('TopTimePlayback')

local g_Playback
local g_TraceCoded, g_Title, g_StartTime

-- Used by RPC
function destroy()
	--Debug.info('TopTimePlayback.destroy')
	
	g_TraceCoded, g_Title = false, false
	
	if(g_Playback) then
		g_Playback:destroy()
		g_Playback = false
	end
	
	if(g_Waiting) then
		removeEventHandler('onClientPreRender', g_Root, Playback.preRender)
	end
end

-- Used by RPC
function start()
	--Debug.info('TopTimePlayback.start')
	
	assert(g_TraceCoded)
	g_StartTime = getTickCount()
	
	if(g_Playback) then
		g_Playback:start()
	end
end

-- Used by RPC
function init(traceCoded, title)
	--Debug.info('TopTimePlayback.init')
	assert(traceCoded and title)
	
	if(g_Playback) then
		g_Playback:destroy()
		g_Playback = false
	end
	
	g_TraceCoded = traceCoded
	g_Title = title
	
	if(Settings.playback) then
		local trace = RcDecodeTrace(g_TraceCoded)
		g_Playback = Playback(trace, g_Title)
	end
end

Settings.register
{
	name = 'playback',
	default = true,
	cast = tobool,
	createGui = function(wnd, x, y, w, onChange)
		local cb = guiCreateCheckBox(x, y, w, 20, "Top Time Playback", Settings.playback, false, wnd)
		if(onChange) then
			addEventHandler('onClientGUIClick', cb, onChange, false)
		end
		return 20, cb
	end,
	acceptGui = function(cb)
		Settings.playback = guiCheckBoxGetSelected(cb)
	end,
}
