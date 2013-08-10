local g_Ranks = {}

function StLoadRanks()
	local node, i = xmlLoadFile('conf/ranks.xml'), 0
	if(not node) then return false end
	
	while(true) do
		local subnode = xmlFindChild(node, 'rank', i)
		if(not subnode) then break end
		i = i + 1
		
		local pts = touint(xmlNodeGetAttribute(subnode, 'points' ), 0)
		local name = xmlNodeGetAttribute(subnode, 'name')
		assert(name)
		g_Ranks[pts] = name
	end
	xmlUnloadFile(node)
	return true
end

function StRankFromPoints(points)
	assert(points)
	local pt = -1
	local rank = nil
	
	for pt_i, rank_i in pairs(g_Ranks) do
		if(pt_i > pt and pt_i <= points) then
			rank = rank_i
			pt = pt_i
		end
	end
	
	return rank or "none"
end

function StDetectRankChange(player, oldPoints, newPoints)
	local oldRank = StRankFromPoints(oldPoints)
	local newRank = StRankFromPoints(newPoints)
	if(newRank ~= oldRank) then
		outputMsg(g_Root, Styles.stats, "%s has new rank: %s!", player:getName(), newRank)
	end
end
