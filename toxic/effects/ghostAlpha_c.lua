local function updateAlpha()
	if(not Settings.hideNearbyCars) then return end
	
	local cameraPos = Vector3(getCameraMatrix())
	local target = getCameraTarget()
	local targetPos = target and Vector3(getElementPosition(target))
	local targetDim = target and getElementDimension(target) or getElementDimension(g_Me)
	
	for i, player in ipairs(getElementsByType("player")) do
		local veh = getPedOccupiedVehicle(player)
		local a = getElementAlpha(veh or player)
		local dim = getElementDimension(player)
		if(a < 255 and a > 0 and dim == targetDim) then
			if(veh == target) then
				a = 254
			elseif(targetPos) then
				local pos = Vector3(getElementPosition(veh or player))
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
	onChange = function(oldVal, newVal)
		if(newVal) then
			addEventHandler("onClientPreRender", g_Root, updateAlpha)
		else
			removeEventHandler("onClientPreRender", g_Root, updateAlpha)
		end
	end,
	createGui = function(wnd, x, y, w, onChange)
		local cb = guiCreateCheckBox(x, y, w, 20, "Hide nearby cars", Settings.hideNearbyCars, false, wnd)
		if(onChange) then
			addEventHandler("onClientGUIClick", cb, onChange, false)
		end
		return 20, cb
	end,
	acceptGui = function(cb)
		Settings.hideNearbyCars = guiCheckBoxGetSelected(cb)
	end,
}
