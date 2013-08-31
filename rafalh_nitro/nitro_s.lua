---------------------
-- Local variables --
---------------------

local g_Root = getRootElement()
local g_ResRoot = getResourceRootElement()

-------------------
-- Custom events --
-------------------

addEvent("nitro.onPickUp", true)
addEvent("onPlayerPickUpRacePickup")

--------------------------------
-- Local function definitions --
--------------------------------

local function NitOnPlayerPickUpRacePickup(pickup_id, pickup_type)
	if(pickup_type == "nitro") then
		triggerClientEvent(source, "nitro.onPickUp", g_ResRoot)
	end
end

------------
-- Events --
------------

addEventHandler("onPlayerPickUpRacePickup", g_Root, NitOnPlayerPickUpRacePickup)
