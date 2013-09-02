-- Globals
#DEBUG = false
#PERF_DEBUG = false
#LOG_PATH = false -- "log.txt"

local g_DbgPerfData = {}

#if(DEBUG) then
	function DbgPrint ( fmt, ... )
		outputDebugString ( fmt:format ( ... ), 3 )
		
#		if(LOG_PATH) then
			local file = fileExists("$(LOG_PATH)") and fileOpen("$(LOG_PATH)") or fileCreate("$(LOG_PATH)")
			if ( file ) then
				fileSetPos ( file, fileGetSize ( file ) )
				fileWrite ( file, fmt:format ( ... ) )
				fileClose ( file )
			else
				outputDebugString("Failed to open $(LOG_PATH)", 2)
			end
#		end
	end

	function DbgDump ( str, title )
		local bytes = { str:byte ( 1, str:len () ) }
		local buf = "";
		for i, byte in ipairs ( bytes ) do
			buf = buf..( " %02X" ):format ( byte )
		end
		DbgPrint ( ( title or "dump" )..":"..buf )
	end

	function DbgPerfInit ( channel )
		g_DbgPerfData[channel or 1] = getTickCount ()
	end

	function DbgPerfCp ( title, channel, ... )
		local dt = getTickCount () - g_DbgPerfData[channel or 1]
		local args = { ... }
		args[#args + 1] = dt
#		if(PERF_DEBUG) then
			DbgPrint ( title.." has taken %u ms", unpack ( args ) )
#		end
		g_DbgPerfData[channel or 1] = getTickCount ()
	end
#else
	local function DbgDummy ()
	end
	
	DbgPrint = DbgDummy
	DbgDump = DbgDummy
	DbgPerfInit = DbgDummy
	DbgPerfCp = DbgDummy
#end
