local g_Counter = 0

local _showCursor = showCursor
function showCursor(visible)
	if(visible) then
		g_Counter = g_Counter + 1
		if(g_Counter > 0) then
			_showCursor(true)
		end
	else
		g_Counter = g_Counter - 1
		if(g_Counter <= 0) then
			_showCursor(false)
		end
		
		assert(g_Counter >= 0, tostring(g_Counter))
	end
end

function guiSetInputEnabled()
	assert(false, "guiSetInputEnabled is deprecated")
end
