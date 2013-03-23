g_ForbWords = {}

function CsProcessMsg(message)
	if ( not SmGetBool ( "censor" ) ) then
		return 0, message
	end
	
	local fine = 0
	local offsets = {}
	local offset = 0
	
	local buf = message:lower ():gsub ( "()%A", function ( i ) -- remove color codes
		offsets[i-offset] = i + 1
		offset = offset + 1
		return ""
	end )
	
	offset = 0
	for i = 1, buf:len ()+1, 1 do
		if ( not offsets[i] ) then
			offsets[i] = offset + 1
		end
		offset = offsets[i]
	end
	
	for word, price in pairs ( g_ForbWords ) do
		local pattern = word:lower ()
		pattern = pattern:gsub ( ".", "%1+" )
		for i, j in buf:gmatch ( "()"..pattern.."()" ) do
			message = message:sub ( 1, offsets[i] - 1 )..( "*" ):rep ( word:len () )..message:sub ( offsets[j] ) -- change word to *****
			if ( price > fine ) then
				fine = price
			end
		end
	end
	
	return fine, message
end

local function CsInit()
	local node, i = xmlLoadFile ( "conf/censor.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "word", i )
			if ( not subnode ) then break end
			i = i + 1
			
			local word = xmlNodeGetValue ( subnode )
			local price = touint ( xmlNodeGetAttribute ( subnode, "price" ) )
			g_ForbWords[word] = price
		end
		xmlUnloadFile ( node )
	end
end

addEventHandler("onResourceStart", g_ResRoot, CsInit)
