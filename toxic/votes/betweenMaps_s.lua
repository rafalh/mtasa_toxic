-------------------
-- Custom events --
-------------------

addEvent ( 'onPollModified' )
addEvent ( 'onPollStarting' )

--------------------------------
-- Local function definitions --
--------------------------------

local function onPollStarting ( poll )
	--outputDebugString ( 'onPollStarting', 3 )
	local room = g_RootRoom
	
	local nextMap = MqPop(room)
	if(nextMap) then
		-- cancel poll
		poll.title = nil
		
		-- change map
		g_StartingQueuedMap = nextMap
		nextMap:start(room)
	else
		local maps = getMapsList()
		local vote_type = Settings.vote_between_maps
		local show_ratings = (vote_type == 1)
		local random_play_again_vote = (vote_type == 2)
		local map_type_vote = (vote_type == 3)
		local map_types_count = 0
		local poll_map_types = {}
		
		if ( map_type_vote ) then
			local forced_exist = false
			for i, map_type in ipairs ( g_MapTypes ) do
				if ( map_type.others_in_row >= map_type.max_others_in_row ) then -- map is not allowed now
					forced_exist = true
					break
				else
					map_types_count = map_types_count + 1
				end
			end
			if ( forced_exist ) then
				map_types_count = 0
				for i, map_type in ipairs ( g_MapTypes ) do
					if ( map_type.others_in_row < map_type.max_others_in_row ) then -- map is not allowed now
						poll_map_types[i] = true
					else
						map_types_count = map_types_count + 1
					end
				end
			end
		end
		
		local i = 1
		local map_i = 1
		while ( i <= #poll ) do
			local opt = poll[i]
			if ( exports.mapmanager:isMap (opt[4]) ) then
				local map = Map.create(opt[4])
				local map_name = map:getName()
				
				if ( map ~= getLastMap(room) and opt[1] == map_name ) then
					if ( ( random_play_again_vote and map_i > 1 ) or ( map_type_vote and map_i > map_types_count ) ) then
						table.remove ( poll, i )
					else
						if ( map_type_vote ) then
							local map_type = map:getType()
							
							while ( (not map_type or poll_map_types[map_type] or map:isForbidden(room)) and maps:getCount() > 0 ) do
								map = maps:remove(math.random (1, maps:getCount()))
								opt[4] = map.res
								map_type = map:getType()
							end
							
							poll_map_types[map_type] = true
							opt[1] = map_type.name
						else
							while ( map:isForbidden(room) and maps:getCount() > 0 ) do
								map = maps:remove(math.random (1, maps:getCount()))
								opt[4] = map.res
							end
							-- ignore case when maps:getCount() == 0
							if ( random_play_again_vote ) then
								opt[1] = "Random"
							elseif ( show_ratings ) then
								local map = Map.create(opt[4])
								local map_id = map:getId()
								local rows = DbQuery ( 'SELECT rates, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', map_id )
								opt[1] = map:getName()
								
								if(rows[1].rates_count > 0) then
									opt[1] = opt[1]..( ' (%.2f)' ):format ( rows[1].rates / rows[1].rates_count )
								end
							end
						end
						
						poll[i] = opt
						i = i + 1
						map_i = map_i + 1
					end
				else -- Play again
					if (map:isForbidden(room)) then
						table.remove(poll, i)
					else
						i = i + 1
					end
				end
			else
				i = i + 1
			end
		end
		
		if ( #poll == 1 ) then
			poll[2] = { poll[1][1], poll[1][2], poll[1][3], poll[1][4] } -- Note: lua handles tables by reference
			poll.timeout = 0.06
		end
		
		if ( #poll == 0 ) then -- this shouldnt happen
			outputDebugString ( 'No maps in votemap!', 2 )
			startRandomMap(room)
		end
	end
	
	triggerEvent ( 'onPollModified', g_Root, poll )
end

------------
-- Events --
------------

addInitFunc(function()
	addEventHandler( 'onPollStarting', g_Root, onPollStarting )
end)
