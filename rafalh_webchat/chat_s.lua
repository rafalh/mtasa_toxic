---------------------
-- Local variables --
---------------------

local g_Msgs = {}
local g_MaxMsgs = 20
local g_Root = getRootElement ()
local g_MsgId = 0

---------------------------------
-- Local function declarations --
---------------------------------

local getTime
local onPlayerChatHandler
local onPlayerJoinHandler
local onPlayerQuitHandler
local onPlayerWastedHandler
local onPlayerChangeNickHandler

--------------------------------
-- Local function definitions --
--------------------------------

table.size = function ( tab )
    local n = 0
    for v in pairs( tab ) do n = n + 1 end
    return n
end

getTime = function ()
	local time = getRealTime ()
	return string.format ( "%02d:%02d:%02d", time.hour, time.minute, time.second )
end

onPlayerChatHandler = function ( msg, type )
	if ( type == 0 ) then
		local r, g, b = getPlayerNametagColor ( source )
		addChatStr ( string.format ( "#%02x%02x%02x", r, g, b )..getPlayerName ( source ).."#ffffff: "..msg )
	elseif ( type == 1 ) then
		addChatStr ( "#ff00ff* "..string.gsub ( getPlayerName ( source ), "#%x%x%x%x%x%x", "" ).." "..msg )
	end
end

onPlayerJoinHandler = function ( )
	addChatStr ( "#ff6060* "..getPlayerName ( source ).." joined the game!" )
end

onPlayerQuitHandler = function ( quitType )
	addChatStr ( "#ff6060* "..string.gsub ( getPlayerName ( source ), "#%x%x%x%x%x%x", "" ).." has left the game ("..quitType..")." )
end

onPlayerWastedHandler = function ( Ammo, killer, killerWeapon, bodypart )
	if ( killer and getElementType ( killer ) == "player" ) then
		addChatStr ( getPlayerName(killer).." killed "..getPlayerName(source).." using weapon "..getWeaponNameFromID(killerWeapon).."."	)
	else
		addChatStr ( "#ff6060* "..string.gsub ( getPlayerName ( source ), "#%x%x%x%x%x%x", "" ).." died." )
	end
end

onPlayerChangeNickHandler = function ( oldNick, newNick )
	oldNick = string.gsub ( oldNick, "#%x%x%x%x%x%x", "" )
	newNick = string.gsub ( newNick, "#%x%x%x%x%x%x", "" )
	if newNick ~= oldNick then
		addChatStr ( "#ff6060* "..oldNick.." is now known as "..newNick )
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function getChatMessages ( id ) -- pobiera wszystkie wiadomoúci ktÛre maja id wieksze od id
	local tmp = {}
	for _, msg in ipairs ( g_Msgs ) do
		if msg[2] > tonumber ( id ) then
			table.insert ( tmp, msg )
		end
	end
	return tmp
end

function addChatStr ( str )
	if table.size ( g_Msgs ) >= g_MaxMsgs then
		table.remove ( g_Msgs, 1 )
	end
	str = string.gsub ( str, "•", "&#260;" )
	str = string.gsub ( str, "π", "&#261;" )
	str = string.gsub ( str, "∆", "&#262;" )
	str = string.gsub ( str, "Ê", "&#263;" )
	str = string.gsub ( str, " ", "&#280;" )
	str = string.gsub ( str, "Í", "&#281;" )
	str = string.gsub ( str, "£", "&#321;" )
	str = string.gsub ( str, "≥", "&#322;" )
	str = string.gsub ( str, "—", "&#323;" )
	str = string.gsub ( str, "Ò", "&#324;" )
	str = string.gsub ( str, "”", "&#211;" )
	str = string.gsub ( str, "Û", "&#243;" )
	str = string.gsub ( str, "å", "&#346;" )
	str = string.gsub ( str, "ú", "&#347;" )
	str = string.gsub ( str, "è", "&#377;" )
	str = string.gsub ( str, "ü", "&#378;" )
	str = string.gsub ( str, "Ø", "&#379;" )
	str = string.gsub ( str, "ø", "&#380;" )
	table.insert ( g_Msgs, { [0]=getTime (), [1]=str, [2]=g_MsgId } )
	g_MsgId = g_MsgId + 1
end

function sendChatMsg ( user, name, msg )
	msg = string.gsub ( msg, "\196\132", "•" )
	msg = string.gsub ( msg, "\196\133", "π" )
	msg = string.gsub ( msg, "\196\134", "∆" )
	msg = string.gsub ( msg, "\196\135", "Ê" )
	msg = string.gsub ( msg, "\196\152", " " )
	msg = string.gsub ( msg, "\196\153", "Í" )
	msg = string.gsub ( msg, "\197\129", "£" )
	msg = string.gsub ( msg, "\197\130", "≥" )
	msg = string.gsub ( msg, "\197\131", "—" )
	msg = string.gsub ( msg, "\197\132", "Ò" )
	msg = string.gsub ( msg, "\195\147", "”" )
	msg = string.gsub ( msg, "\195\179", "Û" )
	msg = string.gsub ( msg, "\197\154", "å" )
	msg = string.gsub ( msg, "\197\155", "ú" )
	msg = string.gsub ( msg, "\197\185", "è" )
	msg = string.gsub ( msg, "\197\186", "ü" )
	msg = string.gsub ( msg, "\197\187", "Ø" )
	msg = string.gsub ( msg, "\197\188", "ø" )
	local str = "#ffff00"..tostring ( name ).." (web)#ffffff: "..tostring ( msg )
	outputChatBox ( str, g_Root, 255, 255, 255, true )
	addChatStr ( str )
	--outputChatBox ( tostring ( getAccountName ( user ) ) )
	--exports.toxic:chatHandler ( user, msg, 0 )
end

------------
-- Events --
------------

addEventHandler ( "onPlayerChat", g_Root, onPlayerChatHandler )
addEventHandler ( "onPlayerJoin", g_Root, onPlayerJoinHandler )
addEventHandler ( "onPlayerQuit", g_Root, onPlayerQuitHandler )
addEventHandler ( "onPlayerWasted", g_Root, onPlayerWastedHandler )
addEventHandler ( "onPlayerChangeNick", g_Root, onPlayerChangeNickHandler )
