----------------------
-- Global variables --
----------------------

local g_Root = getRootElement ()

-------------------
-- Custom events --
-------------------

addEvent ( "onClientRafalhConfigureParticles", true )
addEvent ( "onRafalhParticlesInit", true )
addEvent ( "onSettingChange" )

---------------------------------
-- Local function declarations --
---------------------------------

local onRafalhSnowInit
local onSettingChange

--------------------------------
-- Local function definitions --
--------------------------------

onRafalhParticlesInit = function ()
	triggerClientEvent ( client, "onClientRafalhConfigureParticles", g_Root, get ( "radius" ), get ( "density" ), get ( "speed" ), get ( "size" ), get ( "wind_x" ), get ( "wind_y" ) )
end

-- Called from the admin panel when a setting is changed
onSettingChange = function ()
	triggerClientEvent ( g_Root, "onClientRafalhConfigureParticles", g_Root, get ( "radius" ), get ( "density" ), get ( "speed" ), get ( "size" ), get ( "wind_x" ), get ( "wind_y" ) )
end

------------
-- Events --
------------

addEventHandler ( "onRafalhParticlesInit", g_Root, onRafalhParticlesInit )
addEventHandler ( "onSettingChange", getResourceRootElement ( getThisResource () ), onSettingChange )
