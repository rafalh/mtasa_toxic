---------------------
-- Local variables --
---------------------

local g_Root = getRootElement ()
local g_ResRoot = getResourceRootElement ()

-------------------
-- Custom events --
-------------------

addEvent ( "onClientPickUpNitro", true )
addEvent ( "onPlayerPickUpRacePickup" )

--------------------------------
-- Local function definitions --
--------------------------------

local function NitOnPlayerPickUpRacePickup ( pickup_id, pickup_type )
	if ( pickup_type == "nitro" ) then
		triggerClientEvent ( source, "onClientPickUpNitro", g_ResRoot )
	end
end

------------
-- Events --
------------

addEventHandler ( "onPlayerPickUpRacePickup", g_Root, NitOnPlayerPickUpRacePickup )
