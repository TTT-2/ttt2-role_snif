if SERVER then
	-- materials
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_snif.vmt")
end

function ROLE:PreInitialize()
	self.color = Color(81, 123, 226, 255)
	self.dkcolor = Color(17, 69, 200, 255)
	self.bgcolor = Color(255, 157, 72, 255)
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
		-- setup here is not necessary but if you want to access the role data, you need to start here
		-- setup basic translation !
		LANG.AddToLanguage("English", self.name, "Sniffer")
		LANG.AddToLanguage("English", "info_popup_" .. self.name, [[You are a Sniffer!
	Try to get some credits!]])
		LANG.AddToLanguage("English", "body_found_" .. self.abbr, "This was a Sniffer...")
		LANG.AddToLanguage("English", "search_role_" .. self.abbr, "This person was a Sniffer!")
		LANG.AddToLanguage("English", "target_" .. self.name, "Sniffer")
		LANG.AddToLanguage("English", "ttt2_desc_" .. self.name, [[The Sniffer is a Detective (who works together with the other detectives)]])

		---------------------------------

		-- maybe this language as well...
		LANG.AddToLanguage("Deutsch", self.name, "Sniffer")
		LANG.AddToLanguage("Deutsch", "info_popup_" .. self.name, [[Du bist ein Sniffer!
	Versuche ein paar Credits zu bekommen!]])
		LANG.AddToLanguage("Deutsch", "body_found_" .. self.abbr, "Er war ein Sniffer...")
		LANG.AddToLanguage("Deutsch", "search_role_" .. self.abbr, "Diese Person war ein Sniffer!")
		LANG.AddToLanguage("Deutsch", "target_" .. self.name, "Sniffer")
		LANG.AddToLanguage("Deutsch", "ttt2_desc_" .. self.name, [[Der Sniffer ist ein Detektiv (der mit den anderen Detektiv-Rollen zusammenarbeitet)]])
	end
end)

if SERVER then
	hook.Add("TTT2UpdateSubrole", "TTT2SnifGiveLens", function(ply, old, new)
		if new == ROLE_SNIFFER then
			ply:GiveEquipmentWeapon("weapon_ttt2_lens")
		elseif old == ROLE_SNIFFER then
			ply:StripWeapon("weapon_ttt2_lens")
		end
	end)
end
