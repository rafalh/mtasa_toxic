-- Includes
#include 'include/config.lua'

AchvRegister{
	id = 0,
	name = "Open User Panel",
	client = true,
	prize = 1000,
}

AchvRegister{
	id = 1,
	name = "Open Statistics Panel",
	client = true,
	prize = 1000,
}

AchvRegister{
	id = 2,
	name = "Try built-in radio",
	client = true,
	prize = 2000,
}

AchvRegister{
	id = 3,
	name = "Try built-in translator",
	save = true,
	prize = 2000,
}

AchvRegister{
	id = 43,
	name = "Read about the server",
	client = true,
	prize = 2000,
}

#if(RACE_STATS) then
AchvRegister{
	id = 4,
	name = "Finish a race",
	checkStats = function(stats) return stats.racesFinished >= 1 end,
	prize = 2000,
}

AchvRegister{
	id = 5,
	name = "1st victory in race",
	checkStats = function(stats) return stats.raceVictories >= 1 end,
	prize = 5000,
}

AchvRegister{
	id = 6,
	name = "10th victory in race",
	checkStats = function(stats) return stats.raceVictories >= 10 end,
	prize = 10000,
}

AchvRegister{
	id = 7,
	name = "100th victory in race",
	checkStats = function(stats) return stats.raceVictories >= 100 end,
	prize = 20000,
}

AchvRegister{
	id = 8,
	name = "1000th victory in race",
	checkStats = function(stats) return stats.raceVictories >= 1000 end,
	prize = 100000,
}
#end -- RACE_STATS

#if(DM_STATS) then
AchvRegister{
	id = 9,
	name = "Take 1st hunter on DM",
	checkStats = function(stats) return stats.huntersTaken >= 1 end,
	prize = 5000,
}

AchvRegister{
	id = 10,
	name = "Take 10th hunter on DM",
	checkStats = function(stats) return stats.huntersTaken >= 10 end,
	prize = 10000,
}

AchvRegister{
	id = 11,
	name = "Take 100th hunter on DM",
	checkStats = function(stats) return stats.huntersTaken >= 100 end,
	prize = 20000,
}

AchvRegister{
	id = 12,
	name = "Take 1000th hunter on DM",
	checkStats = function(stats) return stats.huntersTaken >= 1000 end,
	prize = 100000,
}
#end -- DM_STATS

#if(DD_STATS) then
AchvRegister{
	id = 13,
	name = "1st victory on DD",
	checkStats = function(stats) return stats.ddVictories >= 1 end,
	prize = 5000,
}

AchvRegister{
	id = 14,
	name = "10th victory on DD",
	checkStats = function(stats) return stats.ddVictories >= 10 end,
	prize = 10000,
}

AchvRegister{
	id = 15,
	name = "100th victory on DD",
	checkStats = function(stats) return stats.ddVictories >= 100 end,
	prize = 20000,
}

AchvRegister{
	id = 16,
	name = "1000th victory on DD",
	checkStats = function(stats) return stats.ddVictories >= 1000 end,
	prize = 100000,
}
#end -- DD_STATS
AchvRegister{
	id = 17,
	name = "Play 50 matches",
	checkStats = function(stats) return stats.mapsPlayed >= 50 end,
	prize = 10000,
}

AchvRegister{
	id = 18,
	name = "Play 300 matches",
	checkStats = function(stats) return stats.mapsPlayed >= 300 end,
	prize = 20000,
}

AchvRegister{
	id = 19,
	name = "Play 1000 matches",
	checkStats = function(stats) return stats.mapsPlayed >= 1000 end,
	prize = 50000,
}

AchvRegister{
	id = 20,
	name = "Play 5000 matches",
	checkStats = function(stats) return stats.mapsPlayed >= 5000 end,
	prize = 100000,
}

AchvRegister{
	id = 21,
	name = "Spend 1 hour on this server",
	checkStats = function(stats) return stats.time_here >= 3600 end,
	prize = 10000,
}

AchvRegister{
	id = 22,
	name = "Spend 1 day on this server",
	checkStats = function(stats) return stats.time_here >= 24*3600 end,
	prize = 50000,
}

AchvRegister{
	id = 23,
	name = "Spend 7 days on this server",
	checkStats = function(stats) return stats.time_here >= 7*24*3600 end,
	prize = 100000,
}

AchvRegister{
	id = 24,
	name = "Spend 30 days on this server",
	checkStats = function(stats) return stats.time_here >= 30*24*3600 end,
	prize = 300000,
}

AchvRegister{
	id = 25,
	name = "Gather first million Euro",
	checkStats = function(stats) return stats.cash >= 1000*1000 end,
	save = true,
	prize = 10000,
}

AchvRegister{
	id = 42,
	name = "Gather 10 millions Euro",
	checkStats = function(stats) return stats.cash >= 10*1000*1000 end,
	save = true,
	prize = 100000,
}

AchvRegister{
	id = 26,
	name = "Buy a map",
	checkStats = function(stats) return stats.mapsBought >= 1 end,
	prize = 10000,
}

AchvRegister{
	id = 27,
	name = "Buy 10 maps",
	checkStats = function(stats) return stats.mapsBought >= 10 end,
	prize = 20000,
}

AchvRegister{
	id = 28,
	name = "Buy 50 maps",
	checkStats = function(stats) return stats.mapsBought >= 50 end,
	prize = 30000,
}

AchvRegister{
	id = 29,
	name = "Buy 200 maps",
	checkStats = function(stats) return stats.mapsBought >= 200 end,
	prize = 50000,
}

AchvRegister{
	id = 30,
	name = "Buy a weapon",
	save = true,
	prize = 10000,
}

AchvRegister{
	id = 31,
	name = "2 victories in a row",
	checkStats = function(stats) return stats.maxWinStreak >= 2 end,
	prize = 3000,
}

AchvRegister{
	id = 32,
	name = "3 victories in a row",
	checkStats = function(stats) return stats.maxWinStreak >= 3 end,
	prize = 10000,
}

AchvRegister{
	id = 33,
	name = "5 victories in a row",
	checkStats = function(stats) return stats.maxWinStreak >= 5 end,
	prize = 20000,
}

#if(TOP_TIMES) then
AchvRegister{
	id = 34,
	name = "1st Top Time",
	checkStats = function(stats) return stats.toptimes_count >= 1 end,
	prize = 10000,
}

AchvRegister{
	id = 35,
	name = "10th Top Time",
	checkStats = function(stats) return stats.toptimes_count >= 10 end,
	save = true,
	prize = 50000,
}

AchvRegister{
	id = 36,
	name = "25th Top Time",
	checkStats = function(stats) return stats.toptimes_count >= 25 end,
	save = true,
	prize = 100000,
}

AchvRegister{
	id = 37,
	name = "100th Top Time",
	checkStats = function(stats) return stats.toptimes_count >= 100 end,
	save = true,
	prize = 300000,
}
#end -- TOP_TIMES

AchvRegister{
	id = 38,
	name = "Rate a map",
	checkStats = function(stats) return stats.mapsRated >= 1 end,
	prize = 1000,
}

AchvRegister{
	id = 39,
	name = "Rate 10 maps",
	checkStats = function(stats) return stats.mapsRated >= 10 end,
	prize = 3000,
}

AchvRegister{
	id = 40,
	name = "Rate 100 maps",
	checkStats = function(stats) return stats.mapsRated >= 100 end,
	prize = 10000,
}

AchvRegister{
	id = 41,
	name = "Rate 1000 maps",
	checkStats = function(stats) return stats.mapsRated >= 1000 end,
	prize = 50000,
}

-- LAST ID: 43
