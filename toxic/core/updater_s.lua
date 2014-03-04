-- Includes
#include 'include/config.lua'

-- Defines
#AWESOME_GAMERS = false

local function mergeMaps(mapDst, mapSrc)
	-- Rates
	local rows = DbQuerySync('SELECT rS.player FROM '..RatesTable..' rS, '..RatesTable..' rD WHERE rS.map=? AND rD.map=? AND rS.player=rD.player', mapSrc, mapDst)
	if(not rows) then return false end
	
	local players = {}
	local questionMarks = {}
	for i, data in ipairs(rows) do
		table.insert(players, data.player)
		table.insert(questionMarks, '?')
	end
	if(#players > 0) then
		local questionMarksStr = table.concat(questionMarks, ',')
		DbQuerySync('DELETE FROM '..RatesTable..' WHERE map=? AND player IN ('..questionMarksStr..')', mapSrc, unpack(players)) -- remove duplicates
		DbQuerySync('UPDATE '..PlayersTable..' SET mapsRated=mapsRated-1 WHERE player IN ('..questionMarksStr..')', unpack(players)) -- remove duplicates
		DbQuerySync('UPDATE '..RatesTable..' SET map=? WHERE map=?', mapDst, mapSrc)
	end
	
	-- Best times
	local rows = DbQuerySync('SELECT btS.player, btS.time AS timeSrc, btD.time AS timeDst FROM '..BestTimesTable..' btS, '..BestTimesTable..' btD WHERE btS.map=? AND btD.map=? AND btS.player=btD.player', mapSrc, mapDst)
	local playersSrc, playersDst = {}, {}
	local questionMarksSrc, questionMarksDst = {}, {}
	
	for i, data in ipairs(rows) do
		local rows2
		
		if(data.timeSrc < data.timeDst) then -- src besttime is better
			table.insert(playersDst, data.player)
			table.insert(questionMarksDst, '?')
			rows2 = DbQuerySync('SELECT COUNT(player) AS pos FROM '..BestTimesTable..' WHERE map=? AND time<=?', mapDst, data.timeDst)
		else -- dst besttime is better
			table.insert(playersSrc, data.player)
			table.insert(questionMarksSrc, '?')
			rows2 = DbQuerySync('SELECT COUNT(player) AS pos FROM '..BestTimesTable..' WHERE map=? AND time<=?', mapSrc, data.timeSrc)
		end
		
		if(rows2[1].pos <= 3) then
			DbQuerySync('UPDATE '..PlayersTable..' SET toptimes_count=toptimes_count-1 WHERE player=?', data.player)
		end
	end
	if(#playersDst > 0) then
		local questionMarksStr = table.concat(questionMarksDst, ',')
		BtDeleteTimes('map=? AND player IN ('..questionMarksStr..')', mapDst, unpack(playersDst)) -- remove duplicates
	end
	if(#playersSrc > 0) then
		local questionMarksStr = table.concat(questionMarksSrc, ',')
		BtDeleteTimes('map=? AND player IN ('..questionMarksStr..')', mapSrc, unpack(playersSrc)) -- remove duplicates
	end
	DbQuerySync('UPDATE '..BestTimesTable..' SET map=? WHERE map=?', mapDst, mapSrc) -- set new best times map
	
	-- Map
	local rows = DbQuerySync('SELECT * FROM '..MapsTable..' WHERE map=?', mapSrc)
	local data = rows and rows[1]
	DbQuerySync('UPDATE '..MapsTable..' SET '..
		'played=played+?, rates=rates+?, rates_count=rates_count+?, '..
		'played_timestamp=max(played_timestamp, ?), added_timestamp=min(added_timestamp, ?) WHERE map=?',
		data.played, data.rates, data.rates_count, data.played_timestamp, data.added_timestamp, mapDst)
	DbQuerySync('DELETE FROM '..MapsTable..' WHERE map=?', mapSrc) -- remove map
	return true
end

local g_TablesToRecreate = {}

local function requestTableRecreate(tbl)
	table.insert(g_TablesToRecreate, tbl)
end

function finishUpdate()
	for i, tbl in ipairs(g_TablesToRecreate) do
		Database.recreateTable(tbl)
	end
end

Updater = {
	currentVer = 171,
	list = {
		{
			ver = 149,
			func = function()
				local rows = DbQuerySync('SELECT DISTINCT serial FROM '..PlayersTable..' WHERE pmuted=1')
				local now = getRealTime().timestamp
				for i, data in ipairs(rows) do
					DbQuerySync('INSERT INTO '..MutesTable..' (serial, timestamp, duration) VALUES(?, ?, ?)', data.serial, now, 3600*24*31)
				end
				Debug.info(#rows..' pmutes updated')
			end
		},
		{
			ver = 150,
			func = function()
				if(not BestTimesTable) then return end
				
				local rows = DbQuerySync('SELECT map, player, rec, cp_times FROM '..BestTimesTable..' WHERE length(rec)>0 OR length(cp_times)>0')
				DbQuerySync('UPDATE '..BestTimesTable..' SET rec=0 WHERE length(rec)=0')
				DbQuerySync('UPDATE '..BestTimesTable..' SET cp_times=0 WHERE length(cp_times)=0')
				for i, data in ipairs(rows) do
					if(data.rec ~= '') then
						DbQuerySync('INSERT INTO '..BlobsTable..' (data) VALUES('..DbBlob(data.rec)..')')
						local id = Database.getLastInsertID()
						if(id == 0) then Debug.warn('last insert ID == 0') end
						DbQuerySync('UPDATE '..BestTimesTable..' SET rec=? WHERE map=? AND player=?', id, data.map, data.player)
					end
					if(data.cp_times ~= '') then
						DbQuerySync('INSERT INTO '..BlobsTable..' (data) VALUES('..DbBlob(data.cp_times)..')')
						local id = Database.getLastInsertID()
						if(id == 0) then Debug.warn('last insert ID == 0') end
						DbQuerySync('UPDATE '..BestTimesTable..' SET cp_times=? WHERE map=? AND player=?', id, data.map, data.player)
					end
					
					coroutine.yield()
				end
				Debug.info(#rows..' best times updated')
			end
		},
		{
			ver = 151,
			func = function()
				if(not BestTimesTable) then return end
				
				DbQuerySync('UPDATE '..BestTimesTable..' SET timestamp=0 WHERE timestamp IS NULL')
				if(not Database.recreateTable(BestTimesTable)) then
					return 'Failed to recreate best times table'
				end
			end
		},
		{
			ver = 152,
			func = function()
				DbQuerySync('UPDATE '..PlayersTable..' SET account=NULL WHERE account=\'\'')
				
				-- Only for AwesomeGamers
#if(AWESOME_GAMERS) then
				if(not DbQuerySync('ALTER TABLE '..PlayersTable..' ADD COLUMN warnings TINYINT UNSIGNED NOT NULL DEFAULT 0')) then
					return 'Failed to add warnings column'
				end
				
				if(not DbQuerySync('ALTER TABLE '..DbPrefix..'settings ADD COLUMN backupTimestamp INT DEFAULT 0 NOT NULL')) then
					return 'Failed to add backupTimestamp column.'
				end
				
				if(not DbQuerySync('UPDATE '..PlayersTable..' SET points=exp')) then
					return 'Failed to update points'
				end
				
				Settings.loadPrivate() -- for backupTimestamp
#end
				
				if(not Database.recreateTable(PlayersTable)) then
					return 'Failed to recreate players table'
				end
			end
		},
		{
			ver = 153,
			func = function()
				if(not DbQuerySync('ALTER TABLE '..MapsTable..' ADD COLUMN patcherSeq SMALLINT NOT NULL DEFAULT 0')) then
					return 'Failed to add patcherSeq column'
				end
				return false
			end
		},
		{
			ver = 154,
			func = function()
				if(not DbQuerySync('INSERT INTO '..SerialsTable..' (serial) '..
						'SELECT DISTINCT serial '..
						'FROM '..PlayersTable)) then
					return 'Failed to init serials table'
				end

				if(not DbQuerySync('INSERT INTO '..AliasesTable..' (serial, name) '..
						'SELECT DISTINCT s.id AS serial, n.name '..
						'FROM '..PlayersTable..' p, '..SerialsTable..' s, '..DbPrefix..'names n '..
						'WHERE p.player=n.player AND p.serial=s.serial')) then
					return 'Failed to init aliases table'
				end
				
				if(not DbQuerySync('DROP TABLE '..DbPrefix..'names')) then
					return 'Failed to delete names table'
				end
				
				return false
			end
		},
		{
			ver = 155,
			func = function()
				if(not DbQuerySync('DROP INDEX IF EXISTS '..DbPrefix..'rates_idx') or
					not DbQuerySync('CREATE UNIQUE INDEX '..DbPrefix..'rates_idx ON '..RatesTable..' (map, player)')) then
					return 'Failed to recreate rafalh_rates_idx'
				end
				return false
			end
		},
		{
			ver = 157,
			func = function()
				local rows = DbQuerySync('SELECT m1.map AS map1, m2.map AS map2 FROM '..MapsTable..' m1, '..MapsTable..' m2 WHERE m1.name=m2.name AND m1.map<m2.map')
				for i, row in ipairs(rows) do
					Debug.info('Merging maps: '..row.map1..' <- '..row.map2)
					if(not mergeMaps(row.map1, row.map2)) then
						return 'Merging maps failed'
					end
					coroutine.yield()
				end
				return false
			end
		},
		{
			ver = 158,
			func = function()
				if(not DbQuerySync('DROP INDEX IF EXISTS '..DbPrefix..'maps_idx') or
					not DbQuerySync('CREATE UNIQUE INDEX '..DbPrefix..'maps_idx ON '..MapsTable..' (name)')) then
					return 'Failed to recreate rafalh_maps_idx'
				end
				return false
			end
		},
		{
			ver = 159,
			func = function()
				if(not DbQuerySync('DROP INDEX IF EXISTS '..DbPrefix..'mutes_idx') or
					not DbQuerySync('CREATE UNIQUE INDEX '..DbPrefix..'mutes_idx ON '..MutesTable..' (serial)')) then
					return 'Failed to recreate rafalh_mutes_idx'
				end
				return false
			end
		},

		{
			ver = 160,
			func = function()
#if(not AWESOME_GAMERS) then
				if(not DbQuerySync('ALTER TABLE '..PlayersTable..' ADD COLUMN avatar VARCHAR(255) NOT NULL DEFAULT \'\'')) then
					return 'Failed to add avatar column'
				end
#end
				return false
			end
		},
		{
			ver = 161,
			func = function()
#if(not AWESOME_GAMERS and DD_STATS) then
				if(not DbQuerySync('ALTER TABLE '..PlayersTable..' ADD COLUMN kills MEDIUMINT UNSIGNED NOT NULL DEFAULT 0')) then
					return 'Failed to add kills column'
				end
#end
				return false
			end
		},
		{
			ver = 162,
			func = function()
				if(not DbQuerySync('ALTER TABLE '..PlayersTable..' ADD COLUMN passwordRecoveryKey VARCHAR(32)')) then
					return 'Failed to add passwordRecoveryKey column'
				end
			end
		},
		{
			ver = 163,
			func = function()
#if(TOP_TIMES) then
				if(not Database.recreateTable(BestTimesTable)) then
					return 'Failed to recreate besttimes table'
				end
				
				if(not DbQuerySync('UPDATE '..BestTimesTable..' SET rec=NULL WHERE rec=0') or
					not DbQuerySync('UPDATE '..BestTimesTable..' SET cp_times=NULL WHERE cp_times=0')) then
					return 'Failed to update rec or cp_times columns'
				end
#end
			end
		},
		{
			ver = 164,
			func = function()
#if(SHOP_ITEM_TEAM) then
				if(not DbQuerySync('ALTER TABLE '..PlayersTable..' ADD COLUMN ownedTeam INT DEFAULT NULL')) then
					return 'Failed to add ownedTeam column'
				end
#end
			end
		},
		{
			ver = 165,
			func = function()
#if(SHOP_ITEM_TEAM) then
				if(not DbQuerySync('ALTER TABLE '..Teams.TeamsTable..' ADD COLUMN owner INT DEFAULT NULL')) then
					return 'Failed to add owner column'
				end
#end
			end
		},
		{
			ver = 166,
			func = function()
				if(not DbQuerySync('ALTER TABLE '..PlayersTable..' ADD COLUMN namePlain VARCHAR(32) NOT NULL DEFAULT \'\'')) then
					return 'Failed to add namePlain column'
				end
				if(not DbQuerySync('UPDATE '..PlayersTable..' SET namePlain=name')) then
					return 'Failed to update namePlain column'
				end
				local rows = DbQuerySync('SELECT player, name FROM '..PlayersTable..' WHERE name LIKE ?', '%#%')
				if(not rows) then
					return 'Failed to find players with colored names'
				end
				for i, data in ipairs(rows) do
					if(not DbQuerySync('UPDATE '..PlayersTable..' SET namePlain=? WHERE player=?', data.name:gsub('#%x%x%x%x%x%x', ''), data.player)) then
						return 'Failed to update player plain name'
					end
				end
			end
		},
		{
			ver = 167,
			func = function()
				if(not DbQuerySync('UPDATE '..RatesTable..' SET rate=ROUND(rate/2, 0)')) then
					return 'Failed to update rates table'
				end
				if(not DbQuerySync('UPDATE '..MapsTable..' SET rates=ROUND(rates/2, 0)')) then
					return 'Failed to update maps table'
				end
			end
		},
		{
			ver = 168,
			func = function()
				if(not DbQuerySync('ALTER TABLE '..PlayersTable..' ADD COLUMN spikeStrips TINYINT NOT NULL DEFAULT 0')) then
					return 'Failed to add spikeStrips column'
				end
			end
		},
		{
			ver = 169,
			func = function()
				if(not Database.alterColumn(BlobsTable, {'id', 'INT UNSIGNED', pk = true})) then
					return 'Failed to alter id column in '..BlobsTable
				end
				if(not Database.addConstraint(MutesTable, {'mutes_idx', unique = {'serial'}})) then
					return 'Failed to add constraint do '..MutesTable
				end
				if(not Database.alterColumn(BestTimesTable, {'timestamp', 'INT UNSIGNED', null = true})) then
					return 'Failed to alter timestamp column in '..BestTimesTable
				end
				if(not Database.alterColumns(PlayersTable, {
					{'invitedby', 'INT UNSIGNED', default = 0, null = true},
					{'namePlain', 'VARCHAR(32)', default = ''},
					{'serial', 'VARCHAR(32)', default = '', null = true},
					{'account', 'VARCHAR(255)', default = '', null = true},
					{'spikeStrips', 'TINYINT UNSIGNED', default = 0},
					{'email', 'VARCHAR(128)', default = '', null = true},
				})) then
					return 'Failed to alter columns in '..PlayersTable
				end
				local colsToDrop = {'efectiveness', 'efectiveness_dd', 'efectiveness_dm', 'efectiveness_race'}
				if(not PlayersTable:hasColumn('avatar')) then
					table.insert(colsToDrop, 'avatar')
				end
				if(not Database.dropColumns(PlayersTable, colsToDrop)) then
					return 'Failed to drop columns in '..PlayersTable
				end
				requestTableRecreate(SerialsTable)
				requestTableRecreate(MapsTable)
				requestTableRecreate(AliasesTable)
				requestTableRecreate(BestTimesTable)
				requestTableRecreate(RatesTable)
				requestTableRecreate(ProfilesTable)
				requestTableRecreate(Teams.TeamsTable)
				requestTableRecreate(SettingsTable)
				requestTableRecreate(PlayersTable)
			end
		},
		{
			ver = 170,
			func = function()
				if(not DbQuerySync('UPDATE '..BestTimesTable..' SET timestamp=NULL WHERE timestamp=0')) then
					return 'Failed to update '..BestTimesTable..' table'
				end
				
				if(not Database.alterColumns(MapsTable, {
					{'removed', 'VARCHAR(255)', null = true},
					{'played_timestamp', 'INT UNSIGNED', null = true},
					{'added_timestamp', 'INT UNSIGNED', null = true},
				})) then
					return 'Failed to alter columns in '..MapsTable
				end
				if(not DbQuerySync('UPDATE '..MapsTable..' SET removed=NULL WHERE removed=\'\'')) then
					return 'Failed to update '..MapsTable..' table'
				end
				if(not DbQuerySync('UPDATE '..MapsTable..' SET played_timestamp=NULL WHERE played_timestamp=0')) then
					return 'Failed to update '..MapsTable..' table'
				end
				if(not DbQuerySync('UPDATE '..MapsTable..' SET added_timestamp=NULL WHERE added_timestamp=0')) then
					return 'Failed to update '..MapsTable..' table'
				end
				
				if(not Database.alterColumns(MutesTable, {
					{'reason', 'VARCHAR(255)', null = true},
					{'duration', 'INT UNSIGNED', null = true},
				})) then
					return 'Failed to alter columns in '..MutesTable
				end
				if(not DbQuerySync('UPDATE '..MutesTable..' SET reason=NULL WHERE reason=\'\'')) then
					return 'Failed to update '..MutesTable..' table'
				end
				if(not DbQuerySync('UPDATE '..MutesTable..' SET duration=NULL WHERE duration=0')) then
					return 'Failed to update '..MutesTable..' table'
				end
				
				if(not Database.alterColumns(PlayersTable, {
					{'first_visit', 'INT UNSIGNED', default = false, null = true},
					{'last_visit', 'INT UNSIGNED', default = false, null = true},
					{'ip', 'VARCHAR(16)', default = false, null = true},
					{'email', 'VARCHAR(128)', default = false, null = true},
				})) then
					return 'Failed to alter columns in '..PlayersTable
				end
				if(not DbQuerySync('UPDATE '..PlayersTable..' SET first_visit=NULL WHERE first_visit=0 OR first_visit=1278598053')) then
					return 'Failed to update '..PlayersTable..' table'
				end
				if(not DbQuerySync('UPDATE '..PlayersTable..' SET last_visit=NULL WHERE last_visit=0')) then
					return 'Failed to update '..PlayersTable..' table'
				end
				if(not DbQuerySync('UPDATE '..PlayersTable..' SET ip=NULL WHERE ip=\'\'')) then
					return 'Failed to update '..PlayersTable..' table'
				end
				if(not DbQuerySync('UPDATE '..PlayersTable..' SET email=NULL WHERE email=\'\'')) then
					return 'Failed to update '..PlayersTable..' table'
				end
				
				if(WarningsTable) then
					if(not Database.alterColumns(WarningsTable, {
						{'duration', 'INT UNSIGNED', null = true},
					})) then
						return 'Failed to alter columns in '..WarningsTable
					end
					if(not DbQuerySync('UPDATE '..WarningsTable..' SET duration=NULL WHERE duration=0')) then
						return 'Failed to update '..WarningsTable..' table'
					end
				end
				
				if(Teams) then
					if(not DbQuerySync('UPDATE '..Teams.TeamsTable..' SET owner=NULL WHERE owner=\'\'')) then
						return 'Failed to update '..Teams.TeamsTable..' table'
					end
				end
			end
		},
		{
			ver = 171,
			func = function()
				if(Teams) then
					if(not Database.alterColumns(Teams.TeamsTable, {
						{'tag', 'VARCHAR(255)', null = true},
						{'aclGroup', 'VARCHAR(255)', null = true},
						{'color', 'VARCHAR(7)', null = true},
						{'lastUsage', 'INT UNSIGNED', default = false, null = true},
					})) then
						return 'Failed to alter columns in '..Teams.TeamsTable
					end
					if(not DbQuerySync('UPDATE '..Teams.TeamsTable..' SET tag=NULL WHERE tag=\'\'')) then
						return 'Failed to update '..Teams.TeamsTable..' table'
					end
					if(not DbQuerySync('UPDATE '..Teams.TeamsTable..' SET aclGroup=NULL WHERE aclGroup=\'\'')) then
						return 'Failed to update '..Teams.TeamsTable..' table'
					end
					if(not DbQuerySync('UPDATE '..Teams.TeamsTable..' SET color=NULL WHERE color=\'\'')) then
						return 'Failed to update '..Teams.TeamsTable..' table'
					end
					if(not DbQuerySync('UPDATE '..Teams.TeamsTable..' SET lastUsage=NULL WHERE lastUsage=0')) then
						return 'Failed to update '..Teams.TeamsTable..' table'
					end
				end
			end
		},
	}
}
