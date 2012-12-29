-------------------
-- Custom events --
-------------------

addEvent ( "particles_onConfig", true )
addEvent ( "particles_onPlayerReady", true )

--------------------------------
-- Local function definitions --
--------------------------------

local function onPlayerReady()
	triggerClientEvent(client, "particles_onConfig", resourceRoot, get ( "radius" ), get ( "density" ), get ( "speed" ), get ( "size" ), get ( "wind_x" ), get ( "wind_y" ))
end

local function onSettingChange()
	triggerClientEvent(root, "particles_onConfig", resourceRoot, get ( "radius" ), get ( "density" ), get ( "speed" ), get ( "size" ), get ( "wind_x" ), get ( "wind_y" ))
end

------------
-- Events --
------------

addEventHandler("particles_onPlayerReady", resourceRoot, onPlayerReady)
addEventHandler("onSettingChange", resourceRoot, onSettingChange)
