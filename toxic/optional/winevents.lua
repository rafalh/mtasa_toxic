--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

---------------------
-- Local variables --
---------------------

g_CreatedObjects = {} -- fixme: used by shop.lua

--------------------------------
-- Local function definitions --
--------------------------------

local function WeMapStop ( map )
	for i, object in ipairs ( g_CreatedObjects ) do
		destroyElement ( object )
		g_CreatedObjects[i] = nil
	end
	g_CreatedObjects = {}
	
	AcAllowHighSpeed ( false )
end

local function WePlayerWinDD ()
	local event = math.random ( 1, 7 )
	local el = getPedOccupiedVehicle ( source ) or source
	local x, y, z = getElementPosition ( el )
	if ( event == 1 ) then
		setGravity ( 0 )
		RPC('setGravity', 0):exec()
	elseif ( event == 2 ) then
		local vx, vy, vz = math.random (), math.random (), math.random ()
		setElementVelocity ( el, vx, vy, vz )
	elseif ( event == 3 ) then
		for x2 = x-1, x+1, 1 do
			for y2 = y-1, y+1, 1 do
				local obj = createObject ( 1305, x2, y2, z + 1.2 )
				table.insert ( g_CreatedObjects, obj )
			end
		end
	elseif ( event == 4 ) then
		createExplosion ( x, y, z, 1 )
	elseif ( event == 5 ) then
		local ped = createPed ( 87, x, y, z + 1.5 )
		table.insert ( g_CreatedObjects, ped )
		attachElements ( ped, el, 0, 0, 1.5 )
		setPedAnimation ( ped, 'DANCING', 'dnce_M_a' )
	elseif ( event == 6 ) then
		GmSetEnabled ( false )
		AcAllowHighSpeed ( true )
		local rhino = createVehicle ( 432, x, y, z + 2 )
		table.insert ( g_CreatedObjects, rhino )
		setElementData ( rhino, 'race.collideothers', '1', true )
	elseif ( event == 7 ) then
		setVehicleWheelStates ( el, 1, 1, 1, 1 )
	end
end

------------
-- Events --
------------

addEventHandler ( 'onGamemodeMapStop', g_Root, WeMapStop )
addEventHandler ( 'onPlayerWinDD', g_Root, WePlayerWinDD )
