local g_WndData = {}
local g_WndCount = 0

local function GaUpdate ( dt )
	for wnd, data in pairs ( g_WndData ) do
		local fade = data.fade
		if ( fade ) then
			fade.t1 = math.min ( fade.t1 + dt, fade.t2 )
			local a = ( fade.t1 / fade.t2 ) * fade.a2 + ( ( fade.t2 - fade.t1 ) / fade.t2 ) * fade.a1
			guiSetAlpha ( wnd, a )
			if ( a == fade.a2 and a <= 0 ) then
				guiSetVisible ( wnd, false )
			end
			
			if ( fade.t1 == fade.t2 ) then
				data.fade = nil
				data.c = data.c - 1
			end
		end
		
		local resize = data.resize
		if ( resize ) then
			resize.t1 = math.min ( resize.t1 + dt, resize.t2 )
			local w = ( resize.t1 / resize.t2 ) * resize.w2 + ( ( resize.t2 - resize.t1 ) / resize.t2 ) * resize.w1
			local h = ( resize.t1 / resize.t2 ) * resize.h2 + ( ( resize.t2 - resize.t1 ) / resize.t2 ) * resize.h1
			local x = resize.x - w / 2
			local y = resize.y - h / 2
			
			guiSetSize ( wnd, w, h, false )
			guiSetPosition ( wnd, x, y, false )
			
			if ( resize.t1 == resize.t2 ) then
				data.resize = nil
				data.c = data.c - 1
			end
		end
		
		if ( data.c <= 0 ) then
			g_WndData[wnd] = nil
			g_WndCount = g_WndCount - 1
			if ( g_WndCount <= 0 ) then
				removeEventHandler ( "onClientPreRender", g_Root, GaUpdate )
			end
		end
	end
end

local function GaFade ( wnd, delay, target_alpha )
	local a = guiGetVisible ( wnd ) and guiGetAlpha ( wnd ) or 0
	if ( a == target_alpha ) then return end
	
	if ( not g_WndData[wnd] ) then
		if ( g_WndCount == 0 ) then
			addEventHandler ( "onClientPreRender", g_Root, GaUpdate )
		end
		g_WndCount = g_WndCount + 1
		g_WndData[wnd] = { c = 0 }
	end
	
	local data = g_WndData[wnd]
	guiSetVisible ( wnd, true )
	guiSetAlpha ( wnd, a )
	if ( not data.fade ) then
		data.c = data.c + 1
	end
	data.fade = { t1 = 0, t2 = delay, a1 = a, a2 = target_alpha }
end

function GaFadeIn ( wnd, delay, target_alpha )
	if ( not target_alpha ) then
		target_alpha = 1
	end
	--outputDebugString ( "GaFadeIn "..g_WndCount.." "..guiGetAlpha ( wnd ).."-"..target_alpha, 2 )
	GaFade ( wnd, delay, target_alpha )
end

function GaFadeOut ( wnd, delay, target_alpha )
	if ( not target_alpha ) then
		target_alpha = 0
	end
	--outputDebugString ( "GaFadeOut "..g_WndCount.." "..guiGetAlpha ( wnd ).."-"..target_alpha, 2 )
	GaFade ( wnd, delay, target_alpha )
end

function GaResize ( wnd, delay, target_w, target_h )
	local w, h = guiGetSize ( wnd, false )
	local x, y = guiGetPosition ( wnd, false )
	
	if ( w == target_w and h == target_h ) then return end
	
	if ( not g_WndData[wnd] ) then
		if ( g_WndCount == 0 ) then
			addEventHandler ( "onClientPreRender", g_Root, GaUpdate )
		end
		g_WndCount = g_WndCount + 1
		g_WndData[wnd] = { c = 0 }
	end
	
	local data = g_WndData[wnd]
	if ( not data.resize ) then
		data.c = data.c + 1
	end
	
	x = x + w / 2
	y = y + h / 2
	data.resize = { t1 = 0, t2 = delay, w1 = w, w2 = target_w, h1 = h, h2 = target_h, x = x, y = y }
end

local function GaOnElementDestroy ()
	if ( g_WndData[source] ) then
		g_WndData[source] = nil
		g_WndCount = g_WndCount - 1
		if ( g_WndCount <= 0 ) then
			removeEventHandler ( "onClientPreRender", g_Root, GaUpdate )
		end
	end
end

addEventHandler ( "onClientElementDestroy", g_Root, GaOnElementDestroy )
