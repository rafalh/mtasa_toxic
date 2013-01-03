--------------
-- Includes --
--------------

#include "..\\include\\serv_verification.lua"

-------------------
-- Custom events --
-------------------

addEvent ( "onRafalhSharedStart", true )
addEvent ( "onClientRafalhSharedInit", true )

-------------
-- Globals --
-------------

g_Root = getRootElement ()

------------
-- Events --
------------

addEventHandler ( "onRafalhSharedStart", g_Root, function ()
	triggerClientEvent ( client, "onClientRafalhSharedInit", g_Root, $(SERV_VERIFICATION_KEY) )
end )
