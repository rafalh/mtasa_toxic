--[[local g_Me = getLocalPlayer()
local g_Root = getRootElement()


local function TmUpdateAlpha()
	for i, player in ipairs(getElementsByType('player')) do
		if(player ~= g_Me and getElementData(player, 'respawn.playing')) then
			setElementAlpha(player, 0)
			for i, el in ipairs(getAttachedElements(player)) do
				setElementAlpha(el, 0)
			end
			
			local veh = getPedOccupiedVehicle(player)
			if(veh) then
				setElementAlpha(veh, 0)
				for i, el in ipairs(getAttachedElements(veh)) do
					setElementAlpha(el, 0)
				end
			end
			
		end
	end
end

addEventHandler('onClientPreRender', g_Root, TmUpdateAlpha)]]
