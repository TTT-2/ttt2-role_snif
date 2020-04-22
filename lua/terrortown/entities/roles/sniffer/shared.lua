if SERVER then
	-- materials
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_snif.vmt")
end

function ROLE:PreInitialize()
	self.color = Color(81, 123, 226, 255)

	self.abbr = "snif"
	self.scoreKillsMultiplier = 1
	self.scoreTeamKillsMultiplier = -8
	self.fallbackTable = {}
	self.unknownTeam = true

	self.defaultTeam = TEAM_INNOCENT
	self.defaultEquipment = SPECIAL_EQUIPMENT

	-- conVarData
	self.conVarData = {
		pct = 0.13,
		maximum = 32,
		minPlayers = 8,
		minKarma = 600,

		credits = 1,
		creditsTraitorKill = 0,
		creditsTraitorDead = 1,

		togglable = true,
		shopFallback = SHOP_FALLBACK_DETECTIVE
	}
end

function ROLE:Initialize()
	roles.SetBaseRole(self, ROLE_DETECTIVE)

	if CLIENT then
		-- Role specific language elements
		LANG.AddToLanguage("English", self.name, "Sniffer")
		LANG.AddToLanguage("English", "info_popup_" .. self.name, [[You are a Sniffer!
	Try to get some credits!]])
		LANG.AddToLanguage("English", "body_found_" .. self.abbr, "They were a Sniffer.")
		LANG.AddToLanguage("English", "search_role_" .. self.abbr, "This person was a Sniffer!")
		LANG.AddToLanguage("English", "target_" .. self.name, "Sniffer")
		LANG.AddToLanguage("English", "ttt2_desc_" .. self.name, [[The Sniffer is a Detective (who works together with the other detectives)]])
		
		LANG.AddToLanguage("Italiano", self.name, "Sniffer")
		LANG.AddToLanguage("Italiano", "info_popup_" .. self.name, [[Sei uno Sniffer!
	Prova a prendere dei crediti!]])
		LANG.AddToLanguage("Italiano", "body_found_" .. self.abbr, "Era uno Sniffer.")
		LANG.AddToLanguage("Italiano", "search_role_" .. self.abbr, "Questa persona era uno Sniffer!")
		LANG.AddToLanguage("Italiano", "target_" .. self.name, "Sniffer")
		LANG.AddToLanguage("Italiano", "ttt2_desc_" .. self.name, [[Lo Sniffer è un Detective (che collabora con gli altri Detective)]])

		LANG.AddToLanguage("Deutsch", self.name, "Sniffer")
		LANG.AddToLanguage("Deutsch", "info_popup_" .. self.name, [[Du bist ein Sniffer!
	Versuche ein paar Credits zu bekommen!]])
		LANG.AddToLanguage("Deutsch", "body_found_" .. self.abbr, "Er war ein Sniffer.")
		LANG.AddToLanguage("Deutsch", "search_role_" .. self.abbr, "Diese Person war ein Sniffer!")
		LANG.AddToLanguage("Deutsch", "target_" .. self.name, "Sniffer")
		LANG.AddToLanguage("Deutsch", "ttt2_desc_" .. self.name, [[Der Sniffer ist ein Detektiv (der mit den anderen Detektiv-Rollen zusammenarbeitet)]])
	end
end

if SERVER then
	-- Give Loadout on respawn and rolechange
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		ply:GiveEquipmentWeapon("weapon_ttt2_lens")
	end

	-- Remove Loadout on death and rolechange
	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
		ply:StripWeapon("weapon_ttt2_lens")
	end
end
