local function updatePlayerBlipColor(playerEl)
	local player = Player.fromEl(playerEl)
	if(not player) then return end
	
	local isRace = player.room.isRace
	if(isRace) then return end
	
	for i, el in ipairs(getAttachedElements(playerEl)) do
		if(getElementType(el) == 'blip') then
			local r, g, b, a = getBlipColor(el)
			local pr, pg, pb = getPlayerNametagColor(playerEl)
			r = 100 + pr*0.5
			g = 100 + pg*0.5
			b = 100 + pb*0.5
			setBlipColor(el, r, g, b, a)
			--Debug.info('Changing blip color')
			break
        end
    end
end

local function onPlayerSpawn()
	local player = Player.fromEl(source)
	if(not player) then return end
	
	local isRace = player.room.isRace
	if(isRace) then return end
	
	setTimer(updatePlayerBlipColor, 50, 1, player.el)
end

addInitFunc(function()
	addEventHandler('onPlayerSpawn', root, onPlayerSpawn)
end)
