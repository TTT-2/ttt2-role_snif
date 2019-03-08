if SERVER then
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_snif.vmt")
end

ROLE.Base = "ttt_role_base"

ROLE.color = Color(81, 123, 226, 255)
ROLE.dkcolor = Color(17, 69, 200, 255)
ROLE.bgcolor = Color(255, 157, 72, 255)
ROLE.abbr = "snif"
ROLE.defaultTeam = TEAM_INNOCENT
ROLE.defaultEquipment = SPECIAL_EQUIPMENT
ROLE.scoreKillsMultiplier = 1
ROLE.scoreTeamKillsMultiplier = -8
ROLE.fallbackTable = {}
ROLE.unknownTeam = true

-- conVarData
ROLE.conVarData = {
	pct = 0.13,
	maximum = 32,
	minPlayers = 8,
	minKarma = 600,

	credits = 1,
	creditsTraitorKill = 0,
	creditsTraitorDead = 1,

	togglable = true
}

-- now link this subrole with its baserole
hook.Add("TTT2BaseRoleInit", "TTT2ConBRDWithSnif", function()
	SNIFFER:SetBaseRole(ROLE_DETECTIVE)
end)

-- if sync of roles has finished
hook.Add("TTT2FinishedLoading", "SnifferInitD", function()
	if CLIENT then
		-- setup here is not necessary but if you want to access the role data, you need to start here
		-- setup basic translation !
		LANG.AddToLanguage("English", SNIFFER.name, "Sniffer")
		LANG.AddToLanguage("English", "info_popup_" .. SNIFFER.name, [[You are a Sniffer!
Try to get some credits!]])
		LANG.AddToLanguage("English", "body_found_" .. SNIFFER.abbr, "This was a Sniffer...")
		LANG.AddToLanguage("English", "search_role_" .. SNIFFER.abbr, "This person was a Sniffer!")
		LANG.AddToLanguage("English", "target_" .. SNIFFER.name, "Sniffer")
		LANG.AddToLanguage("English", "ttt2_desc_" .. SNIFFER.name, [[The Sniffer is a Detective (who works together with the other detectives)]])

		---------------------------------

		-- maybe this language as well...
		LANG.AddToLanguage("Deutsch", SNIFFER.name, "Sniffer")
		LANG.AddToLanguage("Deutsch", "info_popup_" .. SNIFFER.name, [[Du bist ein Sniffer!
Versuche ein paar Credits zu bekommen!]])
		LANG.AddToLanguage("Deutsch", "body_found_" .. SNIFFER.abbr, "Er war ein Sniffer...")
		LANG.AddToLanguage("Deutsch", "search_role_" .. SNIFFER.abbr, "Diese Person war ein Sniffer!")
		LANG.AddToLanguage("Deutsch", "target_" .. SNIFFER.name, "Sniffer")
		LANG.AddToLanguage("Deutsch", "ttt2_desc_" .. SNIFFER.name, [[Der Sniffer ist ein Detektiv (der mit den anderen Detektiv-Rollen zusammenarbeitet)]])
	end
end)
