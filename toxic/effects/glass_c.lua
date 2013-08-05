----------------------
-- Global variables --
----------------------

local g_BigDemageTime = false
local g_PrevHp = 1000
local g_PrevTarget = nil
local g_Size = 0
local g_Pos = 0
local g_Texture = false

--------------------------------
-- Local function definitions --
--------------------------------

local function renderGlass()
	local veh = getCameraTarget()
	local elType = veh and getElementType(veh)
	if(elType == 'player' or elType == 'ped') then
		veh = getPedOccupiedVehicle(veh)
	end
	if(veh ~= g_PrevTarget) then
		g_PrevTarget = veh
		g_PrevHp = 0 -- h will be > g_PrevHp so no image will be displayed
		g_BigDemageTime = false
	end
	
	-- is there any camera target?
	if(not veh) then return end
	
	local h = getElementHealth(veh)
	if(g_PrevHp - h > 100) then
		if(not g_BigDemageTime) then
			g_Size = math.random () / 2 + 0.25
			g_Pos = math.random () * (1 - g_Size)
		end
		g_BigDemageTime = getTickCount()
	elseif(h > g_PrevHp) then
		g_BigDemageTime = false
	end
	g_PrevHp = h
	
	-- anything to render?
	if(not g_BigDemageTime) then return end
	
	local ticks = getTickCount()
	local a = 255 - (ticks - g_BigDemageTime) / 15000 * 255
	if(a <= 0) then
		g_BigDemageTime = false
	else
		if(Settings.breakableGlass) then
			-- broken glass
			dxDrawImage(g_Pos * g_ScreenSize[1], g_Pos * g_ScreenSize[2], g_Size * g_ScreenSize[1], g_Size * g_ScreenSize[2], g_Texture, 0, 0, 0, tocolor(255, 255, 255, a))
		end
		
		-- red screen for 128 ms
		a = 128 - (ticks - g_BigDemageTime)
		if(a > 0 and Settings.redDmgScreen) then
			dxDrawRectangle(0, 0, g_ScreenSize[1], g_ScreenSize[2], tocolor(255, 0, 0, a))
		end
	end
end

------------
-- Events --
------------

local function init()
	local prof = DbgPerf(20)
	g_Texture = dxCreateTexture('effects/broken_glass.png')
	if(g_Texture) then
		addEventHandler('onClientRender', g_Root, renderGlass)
	end
	prof:cp('broken_glass loading')
end

Settings.register
{
	name = 'breakableGlass',
	default = true,
	cast = tobool,
	onChange = function(oldVal, newVal)
		if(not Settings.redDmgScreen) then
			if(newVal) then
				addEventHandler('onClientRender', g_Root, renderGlass)
			else
				removeEventHandler('onClientRender', g_Root, renderGlass)
			end
		end
	end,
	createGui = function(wnd, x, y, w, onChange)
		local cb = guiCreateCheckBox(x, y, w, 20, "Broken glass after huge damage", Settings.breakableGlass, false, wnd)
		if(onChange) then
			addEventHandler('onClientGUIClick', cb, function()
				onChange('breakableGlass')
			end, false)
		end
		return 20, cb
	end,
	acceptGui = function(cb)
		Settings.breakableGlass = guiCheckBoxGetSelected(cb)
	end,
}

Settings.register
{
	name = 'redDmgScreen',
	default = true,
	cast = tobool,
	onChange = function(oldVal, newVal)
		if(not Settings.breakableGlass) then
			if(newVal) then
				addEventHandler('onClientRender', g_Root, renderGlass)
			else
				removeEventHandler('onClientRender', g_Root, renderGlass)
			end
		end
	end,
	createGui = function(wnd, x, y, w, onChange)
		local cb = guiCreateCheckBox(x, y, w, 20, "Screen flashes red after huge damage", Settings.redDmgScreen, false, wnd)
		if(onChange) then
			addEventHandler('onClientGUIClick', cb, onChange, false)
		end
		return 20, cb
	end,
	acceptGui = function(cb)
		Settings.redDmgScreen = guiCheckBoxGetSelected(cb)
	end,
}

addEventHandler('onClientResourceStart', g_ResRoot, init)
