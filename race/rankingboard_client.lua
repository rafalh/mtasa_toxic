RankingBoard = {}
RankingBoard.__index = RankingBoard

RankingBoard.instances = {}

function RankingBoard.create(id)
	return setmetatable({}, self)
end

function RankingBoard.call(id, fn, ...)
end

function RankingBoard:setDirection(direction)
end

function RankingBoard:add(name, time)
end

function RankingBoard:scroll(param, phase)
end

function RankingBoard:destroyLastLabel(phase)
end

function RankingBoard:addMultiple(items)
end

function RankingBoard:clear()
end

function RankingBoard:destroy()
end



--
-- Label cache
--


function RankingBoard.precreateLabels(count)
end

function destroyElementToSpare(elem)
end

function createShadowedLabelFromSpare(x, y, width, height, text, align)
end
