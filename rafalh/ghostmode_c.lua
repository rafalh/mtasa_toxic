local function updateAlpha()
	if(not g_LocalSettings.hideNearbyCars) then return end
	
	local cameraPos = Vector.create(getCameraMatrix())
	local target = getCameraTarget()
	local targetPos = target and Vector.create(getElementPosition(target))
	local targetDim = target and getElementDimension(target) or getElementDimension(g_Me)
	
	for i, player in ipairs(getElementsByType("player")) do
		local veh = getPedOccupiedVehicle(player)
		local a = getElementAlpha(veh or player)
		local dim = getElementDimension(player)
		if(a < 255 and a > 0 and dim == targetDim) then
			if(veh == target) then
				a = 254
			elseif(targetPos) then
				local pos = Vector.create(getElementPosition(veh or player))
				local dist = pos:distFromSeg(cameraPos, targetPos)
				a = math.min(1 + dist * 20, 112)
			else
				a = 112
			end
			
			if(veh) then
				setElementAlpha(veh, a)
			end
			setElementAlpha(player, a)
		end
	end
end

addEventHandler("onClientPreRender", g_Root, updateAlpha)
