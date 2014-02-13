function VipCreateNeon(player, veh)
	local pdata = g_Players[player]
	local settings = pdata and pdata.settings
	if(not isElement(veh) or not settings) then return end
	
	local r, g, b = getColorFromString(settings.neon_clr)
	if(not pdata.neon) then
		pdata.neon = {}
		pdata.neon.obj = createMarker(0, 0, 0, "corona", 2, r, g, b, 128, g_Root)
		if(not pdata.neon.obj) then
			pdata.neon = nil
			outputDebugString('[VIP] Failed to create neon marker: '..tostring(settings.neon_clr), 1)
			return
		end
		
		addEventHandler('onElementDestroy', pdata.neon.obj, function()
			-- Note: attached object is destroyed when parent is destroyed
			pdata.neon = nil
		end)
	else
		setMarkerColor(pdata.neon.obj, r, g, b, 128)
	end
	pdata.neon.veh = veh
	attachElements(pdata.neon.obj, veh, 0, 0, -1.5)
	--outputDebugString("VipCreateNeon("..getPlayerName(player)..")")
end

function VipDestroyNeon(player)
	local pdata = g_Players[player]
	if(not pdata.neon) then return end
	
	local neon = pdata.neon
	pdata.neon = nil
	
	if(not isElement(neon.obj)) then
		outputDebugString('[VIP] Neon marker is invalid: '..tostring(neon.obj), 2)
		DbgTraceBack()
	else
		destroyElement(neon.obj)
	end
	
	--outputDebugString("VipDestroyNeon("..getPlayerName(player)..")")
end
