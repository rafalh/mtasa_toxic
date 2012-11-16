local function updateAlpha ()
	local camera_pos = Vector.create(getCameraMatrix())
	local target = getCameraTarget()
	local target_pos = target and Vector.create(getElementPosition(target))
	
	for i, player in ipairs ( getElementsByType ( "player" ) ) do
		local veh = getPedOccupiedVehicle ( player )
		local a = getElementAlpha ( veh or player )
		if ( a < 255 and a > 0 ) then
			if(veh == target) then
				a = 254
			elseif(target_pos) then
				local pos = Vector.create(getElementPosition(veh or player))
				local dist = pos:distFromSeg(camera_pos, target_pos)
				a = math.min(1 + dist * 20, 112)
			else
				a = 112
			end
			
			if ( veh ) then
				setElementAlpha ( veh, a )
			end
			setElementAlpha ( player, a )
		end
	end
end

addEventHandler ( "onClientPreRender", g_Root, updateAlpha )
