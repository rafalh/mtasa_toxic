RankingBoard = {}
RankingBoard.__index = RankingBoard

RankingBoard.clientInstances = {}

function RankingBoard:create()
	return setmetatable({}, self)
end

function RankingBoard:clientCall(player, fn, ...)
end

function RankingBoard:setDirection(direction, plrcount)
end

function RankingBoard:add(player, time)
end

function RankingBoard:playerJoined(player)
end

function RankingBoard:clear()
end

function RankingBoard:destroy()
end
