--------------
-- Includes --
--------------

addEvent("onPlayerChatting", true)
addEvent("onClientPlayerChatting", true)

--------------------------------
-- Local function definitions --
--------------------------------

local function ChtOnPlayerChatting(chatting)
	for player, pdata in pairs(g_Players) do
		if(pdata.sync) then
			triggerClientEvent(player, "onClientPlayerChatting", client, chatting)
		end
	end
end

------------
-- Events --
------------

addInitFunc(function()
	addEventHandler("onPlayerChatting", g_Root, ChtOnPlayerChatting)
end)
