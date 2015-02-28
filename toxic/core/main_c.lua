-- Global variables
Styles = {
	joinQuit = {'#00BB00', '#EEEEEE'},
	help = {'#FF6464', '#EEEEEE'},
	pm = '#FF6060',
	red = {'#FF0000', '#EEEEEE'},
	green = {'#00FF00', '#EEEEEE'},
	yellow = {'#FFFF00', '#EEEEEE'},
}

-- Custom events
addEvent('main.onAccountChange', true)

-- Functions
local function onAccountChange(accountName, accountId)
	g_SharedState.accountId = accountId
	g_SharedState.accountName = accountName
end

addInitFunc(function()
	addEventHandler('main.onAccountChange', g_ResRoot, onAccountChange)
end)
