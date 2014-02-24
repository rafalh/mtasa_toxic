-------------------
-- Custom events --
-------------------

addEvent ( 'onPollModified' )
addEvent ( 'onPollStarting' )

--------------------------------
-- Local function definitions --
--------------------------------

local function onPollStarting(poll)
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
			-- Check if there is a forced map type
			local forcedExist = false
			for i, mapType in ipairs(g_MapTypes) do
				local forced = g_PlayersCount > 1 and mapType.max_others_in_row and mapType.others_in_row >= mapType.max_others_in_row
				if(forced) then
					-- At least one map type is forced
					forcedExist = true
					break
				end
			end
			
			if(not forcedExist) then
				-- Count all map types (all are allowed)
				mapTypesCount = #g_MapTypes
			else
				for i, mapType in ipairs(g_MapTypes) do
					local forced = g_PlayersCount > 1 and mapType.max_others_in_row and mapType.others_in_row >= mapType.max_others_in_row
					if(not forced) then
						-- This map type is not allowed - ignore it in next steps
						pollMapTypes[i] = true
					else
						-- This is one of forced map types
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
				
				if(map ~= getLastMap(room) and opt[1] == mapName) then -- not 'Play again'
					if((randomPlayAgainVote and map_i > 1) or (mapTypeVote and map_i > mapTypesCount)) then
						-- There is already enough options in vote
						table.remove(poll, i)
					else
						-- Process map from current item
						if(mapTypeVote) then
							local mapType = map:getType()
							
							-- Loop untill proper map is found
							while((not mapType or pollMapTypes[mapType] or map:isForbidden(room)) and maps:getCount() > 0) do
								map = maps:remove(math.random(1, maps:getCount()))
								opt[4] = map.res
								mapType = map:getType()
							end
							
							-- Mark map type as already added
							pollMapTypes[mapType] = true
							opt[1] = mapType.name
						else
							-- Loop untill proper map is found
							while(map:isForbidden(room) and maps:getCount() > 0) do
								map = maps:remove(math.random(1, maps:getCount()))
								opt[4] = map.res
							end
							
							if(randomPlayAgainVote) then
								-- If this is 'Random, Play again' vote rename current option to Random
								opt[1] = "Random"
							elseif(showRatings) then
								-- Get map rating
								local map = Map(opt[4])
								local mapId = map:getId()
								local data = DbQuerySingle('SELECT rates, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', mapId)
								opt[1] = map:getName()
								
								-- If there are any votes display rating
								if(data.rates_count > 0) then
									opt[1] = opt[1]..(' (%.2f)'):format(data.rates / data.rates_count)
								end
							end
						end
						
						-- Go to the next map
						i = i + 1
						map_i = map_i + 1
					end
				else -- Play again
					if(map:isForbidden(room)) then
						-- Remove map from this vote
						table.remove(poll, i)
					else
						-- Go to the next map
						i = i + 1
					end
				end
			else
				-- It's not a map - ignore
				i = i + 1
			end
		end
		
		if(#poll == 1) then
			-- If there is only one option duplicate it and as quickly as possible finish vote
			poll[2] = table.copy(poll[1]) -- Note: lua handles tables by reference
			poll.timeout = 0.06
		end
		
		if(#poll == 0) then -- this shouldnt happen
			Debug.warn('No maps in votemap!')
			startRandomMap(room)
		end
	--end
	
	-- Poll has been modified
	triggerEvent('onPollModified', g_Root, poll)
end

------------
-- Events --
------------

addInitFunc(function()
	addEventHandler( 'onPollStarting', g_Root, onPollStarting )
end)
