Settings.register
{
	name = 'censorClient',
	default = true,
	cast = tobool,
	shared = true,
	createGui = function(wnd, x, y, w, onChange)
		-- Check if censor is disabled globally
		if(not Settings.censor) then return end
		
		local cb = guiCreateCheckBox(x, y, w, 20, "Censor chat messages", Settings.censorClient, false, wnd)
		if(onChange) then
			addEventHandler('onClientGUIClick', cb, onChange, false)
		end
		return 20, cb
	end,
	acceptGui = function(cb)
		Settings.censorClient = guiCheckBoxGetSelected(cb)
	end,
}
