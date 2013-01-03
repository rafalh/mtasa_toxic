--------------
-- Includes --
--------------

#include "..\\include\\serv_verification.lua"

-------------------
-- Custom events --
-------------------

addEvent ( "onRafalhSharedStart", true )
addEvent ( "onClientRafalhSharedInit", true )
addEvent ( $(EV_SERVER_VERIFICATION) )

-------------
-- Globals --
-------------

g_Root = getRootElement ()
g_ValidatorKey = nil
g_ValidationRequested = false

---------------------------------
-- Global function definitions --
---------------------------------

function $(VERIFY_SERVER_FUNC) ()
	if ( g_ValidatorKey ) then
		--outputChatBox ( "rafalh_shared: verify - event triggered!" )
		triggerEvent ( $(EV_SERVER_VERIFICATION), g_Root, md5 ( g_ValidatorKey..tostring ( getLocalPlayer () )..( getVersion () ).number..getPlayerName ( getLocalPlayer () )..getElementChildrenCount ( getRootElement () ) ) )
	else
		--outputChatBox ( "rafalh_shared: verify - wait!" )
		g_ValidationRequested = true
	end
	return true
end

------------
-- Events --
------------

addEventHandler ( "onClientRafalhSharedInit", g_Root, function ( key )
	g_ValidatorKey = key
	if ( g_ValidationRequested ) then
		g_ValidationRequested = false
		triggerEvent ( $(EV_SERVER_VERIFICATION), g_Root, md5 ( g_ValidatorKey..tostring ( getLocalPlayer () )..( getVersion () ).number..getPlayerName ( getLocalPlayer () )..getElementChildrenCount ( getRootElement () ) ) )
	end
end )

addEventHandler ( "onClientResourceStart", g_Root, function ()
	triggerServerEvent ( "onRafalhSharedStart", g_Root )
end )