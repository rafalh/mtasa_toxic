local LOCATIONS = {
	{ -- Grove street
		pos = Vector3(2495, -1668, 13.3),
		vehOff = {
			Vector3(0, 0, 0),
			Vector3(1, 5, 0),
			Vector3(1, -5, 0),
		},
		camOff = Vector3(-50, 50, 30),
		vehRotZ = 90,
	},
	{ -- sea
		pos = Vector3(1019.6, -2308.1, 13),
		vehOff = {
			Vector3(0, 0, 0),
			Vector3(-1, -5, 0),
			Vector3(-1, 5, 0),
		},
		camOff = Vector3(50, -50, 30),
		vehRotZ = 270,
	},
	{
		pos = Vector3(1135.3, -2037.0, 68.9),
		vehOff = {
			Vector3(0, 0, 0),
			Vector3(-1, -5, 0),
			Vector3(-1, 5, 0),
		},
		camOff = Vector3(50, -50, 30),
		vehRotZ = 270,
	},
	{ -- hill
		pos = Vector3(910, -592.6, 114.2),
		vehOff = {
			Vector3(0, 0, 0),
			Vector3(-5, -3, 0),
			Vector3(3, 5, 0),
		},
		camOff = Vector3(0, -70, 30),
		vehRotZ = 225,
	},
	{ -- parking
		pos = Vector3(2325.8, 1440.5, 42.6),
		vehOff = {
			Vector3(0, 0, 0),
			Vector3(-1, -5, 0),
			Vector3(-1, 5, 0),
		},
		camOff = Vector3(50, -50, 30),
		vehRotZ = 270,
	},
	{
		pos = Vector3(-789, 2427.2, 157),
		vehOff = {
			Vector3(0, 0, 0),
			Vector3(-5, 1, 0),
			Vector3(5, 1, 0),
		},
		camOff = Vector3(-50, -50, 30),
		vehRotZ = 180,
	},
}

local MIN_DIST_A = 0.2
local ANIM_TIME = 1500
local INFO_W = 180
local INFO_BG = tocolor(0, 0, 0, 128)
local TITLES = {'1st', '2nd', '3rd'}
local TITLE_CLRS = {tocolor(255, 196, 0), tocolor(196, 196, 196), tocolor(140, 64, 0)}
local FONT = 'sans'
local TITLE_SCALE = 1.5
local NAME_SCALE = 2

local g_StartTicks
local g_Vehicles, g_Peds
local g_Winners
local g_Loc = LOCATIONS[6]

local function PodiumRender()
	-- Setup camera first
	local dt = getTickCount() - g_StartTicks
	local a = MIN_DIST_A + (ANIM_TIME/(ANIM_TIME + dt))
	local q = Quaternion.fromRot(Vector3(0, 0, 1), 0.3/a)
	local offset = q:transform(g_Loc.camOff)
	local pos = g_Loc.pos + offset*a
	setCameraMatrix(pos[1], pos[2], pos[3], g_Loc.pos[1], g_Loc.pos[2], g_Loc.pos[3])
	
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
			local nameW = dxGetTextWidth(name:gsub('#%x%x%x%x%x%x', ''), scale*NAME_SCALE, FONT)
			local w, h = math.max(scale*INFO_W, nameW), titleH + nameH
			x, y = x - w/2, y - h/2
			
			dxDrawRectangle(x, y, w, h, INFO_BG)
			dxDrawText(TITLES[i], x, y, x + w, titleH, TITLE_CLRS[i],
				scale*TITLE_SCALE, FONT, 'center')
			dxDrawText(name, x, y + titleH, x + w, nameH, TITLE_CLRS[i],
				scale*NAME_SCALE, FONT, 'center', 'top',
				false, false, false,
				true)
		end
	end
end

-- Called by RPC
function PodiumStart(winners, n)
	if(g_StartTicks) then
		outputDebugString('Ignoring PodiumStart request', 2)
		return
	end
	
	g_Winners = winners
	g_Loc = LOCATIONS[n]
	g_Vehicles = {}
	g_Peds = {}
	for i, player in ipairs(winners) do
		local pos = g_Loc.pos + g_Loc.vehOff[i]
		local veh = createVehicle(Settings.podiumVeh, pos[1], pos[2], pos[3], 0, 0, g_Loc.vehRotZ)
		local ped = createPed(0, pos[1], pos[2], pos[3])
		warpPedIntoVehicle(ped, veh)
		setElementParent(ped, veh)
		table.insert(g_Vehicles, veh)
		table.insert(g_Peds, ped)
	end
	
	g_StartTicks = getTickCount()
	addEventHandler('onClientRender', root, PodiumRender)
end

-- Called by RPC
function PodiumStop()
	if(not g_StartTicks) then return end
	
	removeEventHandler('onClientRender', root, PodiumRender)
	for i, veh in ipairs(g_Vehicles) do
		destroyElement(veh)
	end
	for i, ped in ipairs(g_Peds) do
		assert(not isElement(ped))
	end
	g_StartTicks = false
	g_Winners = {}
	g_Vehicles = {}
end

#local TEST = false
#if(TEST) then

setTimer(function()
	if(Settings.debug) then
		PodiumStart({'test', 'test2', 'test3'}, math.random(1, 6))
	end
end, 1000, 1)

#end -- TEST
