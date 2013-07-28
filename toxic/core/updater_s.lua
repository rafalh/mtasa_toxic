Updater = {
	currentVer = 154,
	list = {
		{
			ver = 151,
			func = function()
				DbQuery("UPDATE "..BestTimesTable.." SET timestamp=0 WHERE timestamp IS NULL")
				
				if(not DbRecreateTable(BestTimesTable)) then
					return false, "Failed to recreate best times table"
				end
				return false
			end
		},
		{
			ver = 152,
			func = function()
				DbQuery("UPDATE "..PlayersTable.." SET account=NULL WHERE account=''")
				if(not DbRecreateTable(PlayersTable)) then
					return "Failed to recreate players table"
				end
				return false
			end
		},
		{
			ver = 153,
			func = function()
				if(not DbQuery("ALTER TABLE "..MapsTable.." ADD COLUMN patcherSeq SMALLINT NOT NULL DEFAULT 0")) then
					return "Failed to add patcherSeq column"
				end
				return false
			end
		},
		{
			ver = 154,
			func = function()
				if(not DbQuery("INSERT INTO "..SerialsTable.." (serial) "..
						"SELECT DISTINCT serial "..
						"FROM "..PlayersTable)) then
					return "Failed to init serials table"
				end

				if(not DbQuery("INSERT INTO "..AliasesTable.." (serial, name) "..
						"SELECT DISTINCT s.id AS serial, n.name "..
						"FROM "..PlayersTable.." p, "..SerialsTable.." s, "..DbPrefix.."names n "..
						"WHERE p.player=n.player AND p.serial=s.serial")) then
					return "Failed to init aliases table"
				end
				
				if(not DbQuery("DROP TABLE "..DbPrefix.."names")) then
					return "Failed to delete names table"
				end
				
				return false
			end
		},
	}
}
