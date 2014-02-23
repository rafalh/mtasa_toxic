-------------------
-- Custom events --
-------------------

addEvent ( 'onPollModified' )
addEvent ( 'onPollStarting' )

--------------------------------
-- Local function definitions --
--------------------------------

local function onPollStarting ( poll )
	--Debug.info('onPollStarting')
	local room = g_RootRoom
	
	--[[local nextMap = MqPop(room)
	if(nextMap) then
		-- cancel poll
		poll.title = nil
		
		-- change map
		g_StartingQueuedMap = nextMap
		nextMap:start(room)
	else]]
		local maps = getMapsList()
		local voteType = Settings.vote_between_maps
		local showRatings = (voteType == 1)
		local randomPlayAgainVote = (voteType == 2)
		local mapTypeVote = (voteType == 3)
		local mapTypesCount = 0
		local pollMapTypes = {}
		
		if(mapTypeVote) then
			local forced_exist = false
			for i, mapType in ipairs ( g_MapTypes ) do
				local forced = mapType.max_others_in_row and mapType.others_in_row >= mapType.max_others_in_row
				if(forced) then -- map is not allowed now
					forced_exist = true
					break
				else
					mapTypesCount = mapTypesCount + 1
				end
			end
			if(forced_exist) then
				mapTypesCount = 0
				for i, mapType in ipairs ( g_MapTypes ) do
					local forced = mapType.max_others_in_row and mapType.others_in_row >= mapType.max_others_in_row
					if(not forced) then -- map is not allowed now
						pollMapTypes[i] = true
					else
						mapTypesCount = mapTypesCount + 1
					end
				end
			end
		end
		
		local i = 1
		local map_i = 1
		while(i <= #poll) do
			local opt = poll[i]
			if(exports.mapmanager:isMap(opt[4])) then
				local map = Map(opt[4])
				local mapName = map:getName()
				
				if(map ~= getLastMap(room) and opt[1] == mapName) then
					if((randomPlayAgainVote and map_i > 1) or (mapTypeVote and map_i > mapTypesCount)) then
						table.remove(poll, i)
					else
						if(mapTypeVote) then
							local map_type = map:getType()
							
							while((not map_type or pollMapTypes[map_type] or map:isForbidden(room)) and maps:getCount() > 0) do
								map = maps:remove(math.random(1, maps:getCount()))
								opt[4] = map.res
								map_type = map:getType()
							end
							
							pollMapTypes[map_type] = true
							opt[1] = map_type.name
						else
							while(map:isForbidden(room) and maps:getCount() > 0) do
								map = maps:remove(math.random(1, maps:getCount()))
								opt[4] = map.res
							end
							-- ignore case when maps:getCount() == 0
							if(randomPlayAgainVote) then
								opt[1] = "Random"
							elseif(showRatings) then
								local map = Map(opt[4])
								local map_id = map:getId()
								local rows = DbQuery('SELECT rates, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', map_id)
								opt[1] = map:getName()
								
								if(rows[1].rates_count > 0) then
									opt[1] = opt[1]..(' (%.2f)'):format(rows[1].rates / rows[1].rates_count)
								end
							end
						end
						
						poll[i] = opt
						i = i + 1
						map_i = map_i + 1
					end
				else -- Play again
					if(map:isForbidden(room)) then
						table.remove(poll, i)
					else
						i = i + 1
					end
				end
			else
				i = i + 1
			end
		end
		
		if(#poll == 1) then
			poll[2] = {poll[1][1], poll[1][2], poll[1][3], poll[1][4]} -- Note: lua handles tables by reference
			poll.timeout = 0.06
		end
		
		if(#poll == 0) then -- this shouldnt happen
			Debug.warn('No maps in votemap!')
			startRandomMap(room)
		end
	--end
	
	triggerEvent('onPollModified', g_Root, poll)
end

------------
-- Events --
------------

addInitFunc(function()
	addEventHandler( 'onPollStarting', g_Root, onPollStarting )
end)
