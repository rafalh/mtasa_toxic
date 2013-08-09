-- EXP
-- 1 - 0
-- 2 - 100
-- 3 - 100+200

function LvlFromExp(exp)
	--exp = tonumber(exp)
	return math.floor((50+(2500+200*exp)^0.5)/100)
end

function ExpFromLvl(lvl)
	return (100 + (lvl - 1)*100)/2 * (lvl - 1)
end

function HandleExpChange(player, oldExp, newExp)
	local oldLvl = LvlFromExp(oldExp)
	local newLvl = LvlFromExp(newExp)
	if(newLvl ~= oldLvl) then
		setElementData(player.el, 'lvl', newLvl)
		player:addNotify{
			icon = 'stats/img/icon.png',
			{"You have reached %u. level!", newLvl}}
		
		outputMsg(g_Root, Styles.stats, "%s has new level: %s!", player:getName(true), newLvl)
	end
end
