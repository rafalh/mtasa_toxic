Updater = {
	currentVer = 153,
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
	}
}
