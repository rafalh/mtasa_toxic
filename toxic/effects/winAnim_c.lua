local ANIM_TIME = 12000
local FADE_TIME = 3000
local ANIM_ALPHA = 196
local LOCAL_ANIM_ALPHA = 64
local STARS_COUNT = 24
local DEBUG = false

local g_WinnerAnim = false
local g_WinnerAnimStart
local g_StarTexture

addEvent('main.onPlayerWinDD', true)
addEvent('onClientMapStopping')

local function starsSortHelper(star1, star2)
	return star1.dist > star2.dist
end

local function renderWinnerAnim()
	local ticks = getTickCount()
	local dt = ticks - g_WinnerAnimStart
	local a = ANIM_ALPHA
	
	if(g_WinnerAnim == g_Me) then
		a = LOCAL_ANIM_ALPHA
	end
	
	if(dt > ANIM_TIME or not isElement(g_WinnerAnim)) then
		removeEventHandler('onClientRender', g_Root, renderWinnerAnim)
		g_WinnerAnim = false
		return
	elseif(dt > ANIM_TIME - FADE_TIME) then
		a = (ANIM_TIME - dt) / (ANIM_TIME - (ANIM_TIME - FADE_TIME)) * a
	end
	local color = tocolor(255, 255, 255, a)
	
	local veh = getPedOccupiedVehicle(g_WinnerAnim)
	if(not veh) then return end
	
	local cx, cy, cz = getCameraMatrix()
	local px, py, pz = getElementPosition(veh or g_WinnerAnim)
	--local mat = getElementMatrix ( veh or g_WinnerAnim )
	--local min_x, min_y, min_z, max_x, max_y, max_z = getElementBoundingBox ( veh or g_WinnerAnim )
	local y = 1.5 -- fixme
	local dt = ticks / 1000
	local stars = {}
	
	for i = 0, STARS_COUNT - 1 do
		local a = (i / STARS_COUNT) * (2 * math.pi) + dt
		local a2 = (i % (STARS_COUNT/2)) / (STARS_COUNT/2) * 2*math.pi + dt*0.8
		local c, s = math.cos(a), math.sin(a)
		local c2, s2 = math.cos(a2), math.sin(a2)
		local sx, sy, sz = px, py, pz
		local size = (math.cos(dt*0.9) + 2.5)*1.2
		
		--sx, sy, sz = sx + y * mat[3][1], sy + y * mat[3][2], sz + y * mat[3][3] -- add up vector
		--sx, sy, sz = sx + c * mat[1][1], sy + c * mat[1][2], sz + c * mat[1][3] -- add cos * left vector
		--sx, sy, sz = sx + s * mat[2][1], sy + s * mat[2][2], sz + s * mat[2][3] -- add sin * forward vector
		sx, sy, sz = sx + c*c2*size, sy + s*c2*size, sz + s2*size
		
		if(isLineOfSightClear(cx, cy, cz, sx, sy, sz)) then
			local star = {}
			star.x, star.y = getScreenFromWorldPosition(sx, sy, sz, 0.2)
			if(star.x) then
				star.dist = getDistanceBetweenPoints3D(cx, cy, cz, sx, sy, sz)
				table.insert(stars, star)
			end
		end
	end
	
	table.sort(stars, starsSortHelper)
	
	for i, star in ipairs(stars) do
		local size = 500 / star.dist
		dxDrawImage(star.x - size / 2, star.y - size / 2, size, size, g_StarTexture, 0, 0, 0, color)
	end
end

local function startWinnerAnim()
	if(g_WinnerAnim or not Settings.winAnim) then return end
	
	g_WinnerAnimStart = getTickCount()
	g_WinnerAnim = source
	addEventHandler('onClientRender', g_Root, renderWinnerAnim)
end

local function stopWinnerAnim()
	if(g_WinnerAnim) then
		removeEventHandler('onClientRender', g_Root, renderWinnerAnim)
		g_WinnerAnim = false
	end
end

local function onPlayerQuit()
	if(g_WinnerAnim == source) then
		stopWinnerAnim()
	end
end

local function init()
	g_StarTexture = dxCreateTexture('img/star.png')
	if(DEBUG) then
		source = g_Me
		startWinnerAnim()
	end
end

addEventHandler('main.onPlayerWinDD', g_Root, startWinnerAnim)
addEventHandler('onClientMapStopping', g_Root, stopWinnerAnim)
addEventHandler('onClientPlayerQuit', g_Root, onPlayerQuit)
addEventHandler('onClientResourceStart', g_ResRoot, init)

Settings.register
{
	name = 'winAnim',
	default = true,
	cast = tobool,
	createGui = function(wnd, x, y, w, onChange)
		local cb = guiCreateCheckBox(x, y, w, 20, "Show stars animation above winner car", Settings.winAnim, false, wnd)
		if(onChange) then
			addEventHandler('onClientGUIClick', cb, onChange, false)
		end
		return 20, cb
	end,
	acceptGui = function(cb)
		Settings.winAnim = guiCheckBoxGetSelected(cb)
	end,
}
