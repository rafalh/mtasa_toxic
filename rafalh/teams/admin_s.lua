local TEAMS_RIGHT = "resource."..g_ResName..".teams"

local function CmdTeamsAdmin()
	RPC("openTeamsAdmin"):exec()
end

CmdRegister("teamsadmin", CmdTeamsAdmin, TEAMS_RIGHT)