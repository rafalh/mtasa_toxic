local g_Counter = 0

local _guiSetInputEnabled = guiSetInputEnabled
function guiSetInputEnabled ( enabled )
	if ( enabled ) then
		g_Counter = g_Counter + 1
		if ( g_Counter > 0 ) then
			_guiSetInputEnabled ( true )
		end
	else
		g_Counter = g_Counter - 1
		if ( g_Counter <= 0 ) then
			_guiSetInputEnabled ( false )
		end
	end
end
