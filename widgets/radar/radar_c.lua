local g_Root = getRootElement ()
local g_ResRoot = getResourceRootElement ()
local g_Me = getLocalPlayer ()
local g_ScrSize = { guiGetScreenSize () }
local g_Size = { 196, 196 }
local g_Pos = { 50, g_ScrSize[2] - g_Size[2] - 50 }
local g_Texture = false
local g_MapSize

local function RdInit ()
	g_Texture = dxCreateTexture ( "radar.jpg" ) -- "dxt1"
	g_MapSize = { dxGetMaterialSize ( g_Texture ) }
	assert ( g_Texture )
	showPlayerHudComponent ( "radar", false )
end

local function RdCleanup ()
	showPlayerHudComponent ( "radar", true )
end

local function RdRender ()
	local veh = getPedOccupiedVehicle ( g_Me )
	local x, y, z = getElementPosition ( veh or g_Me )
	
	local cx, cy, cz, tx, ty, tz = getCameraMatrix ()
	local dx, dy, dz = tx - cx, ty - cy, tz - cz
	local a = math.atan2 ( dx, dy )
	
	local vx, vy, vz = getElementVelocity ( veh or g_Me )
	local speed = ( vx ^ 2 + vy ^ 2 + vz ^ 2 ) ^ 0.5
	local r = math.max ( 128, 192 * speed )
	
	local tex_center_x = g_MapSize[1] / 2 + x / 2
	local tex_center_y = g_MapSize[2] / 2 - y / 2
	local tex_r = r / 2 * ( 2 ^ 0.5 )
	
	dxDrawImageSection ( g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], tex_center_x - tex_r, tex_center_y - tex_r, 2 * tex_r, 2 * tex_r, g_Texture, 180 + math.deg ( a ) )
	
	for i, player in ipairs ( getElementsByType ( "blip" ) ) do
		local px, py, pz = getElementPosition ( player )
		
		local rel_x, rel_y = px - x, py - y
		--rel_x, rel_y = 2*r, 0
		local dist = math.min ( ( rel_x ^ 2 + rel_y ^ 2 ) ^ 0.5, r )
		local pa = math.atan2 ( rel_x, rel_y ) - a + math.pi / 2
		
		local scr_x = g_Pos[1] + ( 0.5 + math.cos ( pa ) * dist / r / 2 ) * g_Size[1]
		local scr_y = g_Pos[2] + ( 0.5 + math.sin ( pa ) * dist / r / 2 ) * g_Size[2]
		
		dxDrawRectangle ( scr_x - 3, scr_y - 3, 6, 6, 0x80000000 )
		dxDrawRectangle ( scr_x - 2, scr_y - 2, 4, 4, 0x80FFFFFF )
	end
	
	dxDrawLine ( g_Pos[1] + g_Size[1] / 2, g_Pos[2], g_Pos[1] + g_Size[1] / 2, g_Pos[2] + g_Size[2] )
	dxDrawLine ( g_Pos[1], g_Pos[2] + g_Size[2] / 2, g_Pos[1] + g_Size[1], g_Pos[2] + g_Size[2] / 2 )
	
	dxDrawText ( ( "Pos: %.2f %.2f %.2f" ):format ( x, y, z ), g_Pos[1], g_Pos[2] + g_Size[2] + 5 )
	dxDrawText ( ( "Dir: %.2f %.2f %.2f" ):format ( dx, dy, dz ), g_Pos[1], g_Pos[2] + g_Size[2] + 15 )
	dxDrawText ( ( "Speed: %.2f" ):format ( speed ), g_Pos[1], g_Pos[2] + g_Size[2] + 25 )
	dxDrawText ( ( "Rot: %.2f" ):format ( a ), g_Pos[1], g_Pos[2] + g_Size[2] + 35 )
end

addEventHandler ( "onClientRender", g_Root, RdRender )
addEventHandler ( "onClientResourceStart", g_ResRoot, RdInit )
addEventHandler ( "onClientResourceStop", g_ResRoot, RdCleanup )
