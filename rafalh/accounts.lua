--------------------------------
-- Local function definitions --
--------------------------------

local function onPlayerLogin ( prevAccount, account, autoLogin )
	if ( autoLogin and getAccountData ( account, "autologin_disabled" ) ) then
		cancelEvent ()
	end
end

------------
-- Events --
------------

addEventHandler ( "onPlayerLogin", g_Root, onPlayerLogin )
