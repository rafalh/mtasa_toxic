local function updateAlpha()
	if(not Settings.hideNearbyCars) then return end
	
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

Settings.register
{
	name = "hideNearbyCars",
	default = true,
	cast = tobool,
	createGui = function(wnd, x, y, w)
		local cb = guiCreateCheckBox(x, y, w, 20, "Hide nearby cars", Settings.hideNearbyCars, false, wnd)
		return 20, cb
	end,
	acceptGui = function(cb)
		Settings.hideNearbyCars = guiCheckBoxGetSelected(cb)
	end,
}
