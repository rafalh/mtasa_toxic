-------------------
-- Custom events --
-------------------

addEvent("onClientWinnerAnim", true)

--------------------------------
-- Local function definitions --
--------------------------------

local function WePlayerWinDD()
	triggerClientEvent(g_Root, "onClientWinnerAnim", source)
end

------------
-- Events --
------------

addEventHandler("onPlayerWinDD", g_Root, WePlayerWinDD)
