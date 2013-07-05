local POS = Vector3(2489.6, -1668.5, 13.3)
local VEH_OFFSETS = {
	Vector3(0, 0, 0),
	Vector3(5, -1, 0),
	Vector3(-5, -1, 0),
}
local CAMERA_OFFSET = Vector3(30, 50, 30)
local MIN_DIST_A = 0.2
local ANIM_TIME = 1500
local VEHICLE_MODEL = 411 -- Infernus
local INFO_W = 180
local INFO_BG = tocolor(0, 0, 0, 128)
local TITLES = {"1st", "2nd", "3rd"}
local TITLE_CLRS = {tocolor(255, 196, 0), tocolor(196, 196, 196), tocolor(140, 64, 0)}
local FONT = "sans"
local TITLE_SCALE = 1.5
local NAME_SCALE = 2

local g_StartTicks
local g_Vehicles
local g_Winners

local function PodiumRender()
	-- Setup camera first
	local pos = table.copy(POS)
	local lookAt = table.copy(POS)
	local dt = getTickCount() - g_StartTicks
	local a = MIN_DIST_A + (ANIM_TIME/(ANIM_TIME + dt))
	pos = pos + CAMERA_OFFSET*a
	setCameraMatrix(pos[1], pos[2], pos[3], lookAt[1], lookAt[2], lookAt[3])
	
	-- Draw infoboxes over vehicles
	for i, veh in ipairs(g_Vehicles) do
		local vehPos = Vector3(getElementPosition(veh))
		vehPos[3] = vehPos[3] + 3
		local x, y = getScreenFromWorldPosition(vehPos[1], vehPos[2], vehPos[3])
		if(x) then
			local scale = 0.4/a
			local name = g_Winners[i]
			
			local titleH = dxGetFontHeight(scale*TITLE_SCALE, FONT)
			local nameH = dxGetFontHeight(scale*NAME_SCALE, FONT)
			local nameW = dxGetTextWidth(name:gsub("#%x%x%x%x%x%x", ""), scale*NAME_SCALE, FONT)
			local w, h = math.max(scale*INFO_W, nameW), titleH + nameH
			x, y = x - w/2, y - h/2
			
			dxDrawRectangle(x, y, w, h, INFO_BG)
			dxDrawText(TITLES[i], x, y, x + w, titleH, TITLE_CLRS[i],
				scale*TITLE_SCALE, FONT, "center")
			dxDrawText(name, x, y + titleH, x + w, nameH, TITLE_CLRS[i],
				scale*NAME_SCALE, FONT, "center", "top",
				false, false, false,
				true)
		end
	end
end

-- Called by RPC
function PodiumStart(winners)
	g_Winners = winners
	g_Vehicles = {}
	for i, player in ipairs(winners) do
		local pos = POS + VEH_OFFSETS[i]
		local veh = createVehicle(VEHICLE_MODEL, pos[1], pos[2], pos[3])
		table.insert(g_Vehicles, veh)
	end
	g_StartTicks = getTickCount()
	addEventHandler("onClientRender", root, PodiumRender)
end

-- Called by RPC
function PodiumStop()
	if(not g_StartTicks) then return end
	
	removeEventHandler("onClientRender", root, PodiumRender)
	for i, veh in ipairs(g_Vehicles) do
		destroyElement(veh)
	end
	g_StartTicks = false
	g_Winners = {}
	g_Vehicles = {}
end
