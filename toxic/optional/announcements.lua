local g_AnnouncementIndex = 0
local g_Announcements = {}

local function AnPrintNext ()
	g_AnnouncementIndex = g_AnnouncementIndex + 1
	if ( not g_Announcements[g_AnnouncementIndex] ) then
		g_AnnouncementIndex = 1
	end
	outputMsg(g_Root, '#FFFF00', g_Announcements[g_AnnouncementIndex] )
end

local function AnInit ()
	local tmp = {}
	
	local node, i = xmlLoadFile ( 'conf/announcements.xml' ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, 'announc', i )
			if ( not subnode ) then break end
			
			local announc = {}
			announc.freq = touint ( xmlNodeGetAttribute ( subnode, 'freq' ), 1 )
			announc.text = xmlNodeGetValue ( subnode )
			table.insert ( tmp, announc )
			i = i + 1
		end
		xmlUnloadFile ( node )
	end
	
	table.sort ( tmp, function ( a, b ) return a.freq < b.freq end )
	
	for i, announc in ipairs ( tmp ) do
		for j = 1, announc.freq, 1 do
			table.insert ( g_Announcements, math.floor ( #g_Announcements * j / announc.freq ) + 1, announc.text )
		end
	end
	
	local announc_interval = Settings.announc_interval
	if ( #g_Announcements > 0 and announc_interval > 0 ) then
		setTimer ( AnPrintNext, announc_interval * 1000, 0 )
	end
end

addEventHandler ( 'onResourceStart', g_ResRoot, AnInit )
