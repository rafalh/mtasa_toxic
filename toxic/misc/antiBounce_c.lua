function onVehCol(hitElement)
	if(hitElement ~= nil) then
		if(getElementType(hitElement) ~= 'object') then 
			return 
		end
	end
	
	if(getElementType(source) ~= 'vehicle') then return end
	
	local player = getVehicleOccupant(source)
	if(player ~= localPlayer) then return end
	
	-- FIXME: check if this is DM
	
	local tx, ty, tz = getVehicleTurnVelocity(source) 
	if(ty > 0.1 and tz > 0.1) then
		local vx, vy, vz = getElementVelocity(source)
		setVehicleTurnVelocity(source, 0, 0, 0) 
		setElementVelocity(source, vx, vy, vz)
		Debug.info('Anti-Bounce!')
	end
end

addEventHandler('onClientVehicleCollision', g_Root, onVehCol)
