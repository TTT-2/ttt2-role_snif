-- Lens created by Alf21
-- magnifying glass model by https://gamebanana.com/skins/13032 (by magNet) -> models/magni/magniglass.mdl
-- made with the help of https://facepunch.com/threads/1032378 (by Clavus)
-- code un-SWEP-construction-kitted by EntranceJew
-- magnifying glass viewmodel by Matsilagi

DEFINE_BASECLASS "weapon_tttbase"

if SERVER then
	AddCSLuaFile()

	-- materials
	resource.AddFile("materials/models/magni/magni_sheet.vmt")
	resource.AddFile("materials/vgui/ttt/footstep.vmt")
	resource.AddFile("materials/vgui/ttt/footblood.vmt")
	resource.AddFile("materials/vgui/ttt/icon_weapon_ttt2_lens.vmt")

	-- models
	resource.AddFile("models/magni/magniglass.mdl")
	resource.AddFile("models/magni/v_shuriken.mdl")

	-- sound
	resource.AddFile("sound/ttt2/footsteps.mp3")

	util.AddNetworkString("addFootstep")
	util.AddNetworkString("clearAllFootsteps")
	util.AddNetworkString("TTT2SnifferSendKiller")
end

sound.Add({
	name = "ttt2_sniffer_haefootsteps",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 80,
	sound = "ttt2/footsteps.mp3"
})

local flags = {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
local cvFootstepsLifetime = CreateConVar("ttt2_snif_footsteps_lifetime", "15", flags)
local cvFootbloodLifetime = CreateConVar("ttt2_snif_footblood_lifetime", "30", flags)
local cvLensSound = CreateConVar("ttt2_snif_lens_sound", "1", flags)

------------
-- SWEP data

SWEP.HoldType = "normal"

if CLIENT then
	SWEP.PrintName = "Lens"
	SWEP.Slot = 7

	SWEP.ViewModelFOV = 70
	SWEP.ViewModelFlip = false
	SWEP.DrawCrosshair = false

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "You are able to see footsteps!"
	}

	SWEP.Icon = "vgui/ttt/icon_weapon_ttt2_lens"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/c_magni.mdl"
SWEP.WorldModel = "models/magni/magniglass.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 0.2

SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {} -- no one can buy
SWEP.notBuyable	= true -- no one can buy

SWEP.IronSightsPos = Vector(-5.4, -18, 1.9)
SWEP.IronSightsAng = Vector(0, 0, 0)

-- don't do anything
function SWEP:PrimaryAttack()

end

SWEP.AllowDrop = true

function SWEP:ShouldDropOnDie()
	return true
end

--------------------
-- footstep handling

local plymeta = FindMetaTable("Player")
if not plymeta then return end

function plymeta:CanSeeFootsteps()
	return self:Alive() and self:IsTerror() and IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon():GetClass() == "weapon_ttt2_lens" and self:GetActiveWeapon():GetIronsights()
end

function plymeta:CanSeeFootblood(target)
	if not self:CanSeeFootsteps() or not IsValid(target) or not target:IsPlayer() then
		return false
	end

	local isKiller = target.snifferIsKiller
	if isKiller then
		isKiller = isKiller + cvFootbloodLifetime:GetInt() >= CurTime()

		if not isKiller then
			target.snifferIsKiller = nil
		end
	end

	return isKiller or false
end

hook.Add("TTTPrepareRound", "TTT2SnifClearAllFootsteps", function()
	for _, v in ipairs(player.GetAll()) do
		v.snifferIsKiller = nil
	end
end)

local hook_installed = CLIENT and (hook_installed or false)

if SERVER then
	hook.Add("PlayerFootstep", "TTT2SnifFootsteps", function(ply, pos, foot)
		local plys = {}

		for _, v in ipairs(player.GetAll()) do
			if v ~= ply then
				plys[#plys + 1] = v
			end
		end

		local inBloodTime = false

		if ply.snifferBloody then
			inBloodTime = ply.snifferBloody + cvFootstepsLifetime:GetInt() >= CurTime()

			if not inBloodTime then
				ply.snifferBloody = nil
			end
		end

		local tbl = {
			p = pos,
			a = ply:GetForward():Angle(),
			f = foot == 1,
			b = inBloodTime
		}

		hook.Run("TTT2SnifferModifyFootstep", ply, tbl, plys)

		net.Start("addFootstep")
		net.WriteVector(tbl.p)
		net.WriteAngle(tbl.a)
		net.WriteBool(tbl.f)
		net.WriteBool(tbl.b)
		net.WriteEntity(ply)
		net.Send(plys)
	end)

	hook.Add("TTTPrepareRound", "TTT2SvSnifClearAllFootsteps", function()
		for _, v in ipairs(player.GetAll()) do
			v.snifferBloody = nil
			v.snifferKilled = nil
		end

		net.Start("clearAllFootsteps")
		net.Broadcast()
	end)

	hook.Add("TTT2PostPlayerDeath", "TTT2SnifferBloodMarker", function(victim, infl, attacker)
		victim.snifferKilled = nil

		if IsValid(attacker) and attacker:IsPlayer() then
			attacker.snifferBloody = CurTime()
			victim.snifferKilled = attacker
		end
	end)

	hook.Add("TTTBodyFound", "TTT2SnifferRegisterBlood", function(finder, deadply)
		if IsValid(deadply) and deadply.snifferKilled then
			local killer = deadply.snifferKilled

			if IsValid(killer) and killer.snifferBloody then
				killer.snifferIsKiller = killer.snifferBloody

				net.Start("TTT2SnifferSendKiller")
				net.WriteEntity(killer)
				net.WriteUInt(32, killer.snifferIsKiller)
				net.Broadcast()
			end
		end
	end)

	function SWEP:Deploy()
		local owner = self:GetOwner()

		if IsValid(owner) and owner:Alive() and owner:IsTerror() then
			if not cvLensSound:GetBool() or math.random(1, 5) ~= 1 then return end

			owner:EmitSound("ttt2_sniffer_haefootsteps")
		end

		local r = BaseClass.Deploy(self)

		local irons = self:GetIronsights()
		self:SyncIrons(irons)

		return r
	end

	function SWEP:Holster()
		if not IsFirstTimePredicted() then return end

		local owner = self:GetOwner()

		if IsValid(owner) then
			owner:StopSound("ttt2_sniffer_haefootsteps")
		end

		local r = BaseClass.Holster(self)

		local irons = self:GetIronsights()
		self:SyncIrons(irons)

		return r
	end

	function SWEP:ShowFootPrints(show)

	end
else
	local footbloodMat = Material("vgui/ttt/footblood")
	local footstepMat = Material("vgui/ttt/footstep")
	local maxDistance = 360000
	local footsteps = {}
	local footSize = 12
	local bloodcolor = Color(180, 21, 21)

	-- improved and modified code of https:--github.com/MechanicalMind/murder/blob/master/gamemode/cl_footsteps.lua
	SWEP.DrawFootsteps = function()
		local client = LocalPlayer()

		if not client:CanSeeFootsteps() then return end

		cam.Start3D(EyePos(), EyeAngles())

		local drawTable = {}

		for _, footstep in pairs(footsteps) do
			if (footstep.pos - EyePos()):LengthSqr() < maxDistance then
				drawTable[#drawTable + 1] = {
					p = footstep.pos + footstep.normal * 0.01,
					n = footstep.normal,
					f = footstep.foot,
					h = footstep.size,
					c = footstep.col,
					r = footstep.angle,
					b = footstep.bloody
				}
			end
		end

		render.SetMaterial(footbloodMat)

		for _, v in ipairs(drawTable) do
			if v.b then
				render.DrawQuadEasy(v.p, v.n, v.f and - v.h or v.h, v.h, bloodcolor, v.r)
			end
		end

		render.SetMaterial(footstepMat)

		for _, v in ipairs(drawTable) do
			render.DrawQuadEasy(v.p, v.n, v.f and (v.h * -0.5) or (v.h * 0.5), v.h, v.c, v.r)
		end

		cam.End3D()
	end

	SWEP.UpdateFootsteps = function()
		local lifeTime = math.Clamp(GetConVar("ttt2_snif_footsteps_lifetime"):GetInt(), 0, 30)

		for k, footstep in pairs(footsteps) do
			if footstep.curtime + lifeTime < CurTime() then
				footsteps[k] = nil
			end
		end
	end

	function SWEP:ShowFootPrints(show)
		local owner = self:GetOwner()
		if not IsValid(owner) then
			return true
		end

		if show then
			if not hook_installed and IsValid(owner) and owner == LocalPlayer() and owner:Alive() and owner:IsTerror() then
				hook.Add("PostDrawTranslucentRenderables", "TTT2SnifDrawFootSteps", self.DrawFootsteps)
				hook.Add("Think", "TTT2UpdateFootsteps", self.UpdateFootsteps)

				hook_installed = true
			end
		else
			if hook_installed and owner == LocalPlayer() then
				hook.Remove("PostDrawTranslucentRenderables", "TTT2SnifDrawFootSteps")
				hook.Remove("Think", "TTT2UpdateFootsteps")

				hook_installed = false
			end
		end
	end

	net.Receive("TTT2SnifferSendKiller", function()
		local killer = net.ReadEntity()
		local timestamp = net.ReadUInt(32)

		if not IsValid(killer) then return end

		killer.snifferIsKiller = timestamp
	end)

	net.Receive("addFootstep", function()
		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		local foot = net.ReadBool()
		local bloody = net.ReadBool()
		local ply = net.ReadEntity()

		if not IsValid(ply) then return end

		local fpos = foot and (pos + ang:Right() * 5) or (pos + ang:Right() * -5)

		ang.r = 0
		ang.p = 0

		local trace = {}
		trace.start = fpos
		trace.endpos = trace.start + Vector(0, 0, -10)
		trace.filter = ply

		local tr = util.TraceLine(trace)
		if not tr.Hit then return end

		local tbl = {}
		tbl.pos = tr.HitPos
		tbl.plypos = fpos
		tbl.foot = foot
		tbl.size = footSize
		tbl.curtime = CurTime()
		tbl.angle = ang.y
		tbl.normal = tr.HitNormal
		if ply:GetSubRole() ~= ROLE_NONE then
			tbl.col = ply:GetRoleColor()
		else
			tbl.col = roles.INNOCENT.color
		end
		tbl.bloody = bloody

		hook.Run("TTT2SnifferModifyFootstep", ply, tbl)

		footsteps[#footsteps + 1] = tbl
	end)

	net.Receive("clearAllFootsteps", function()
		footsteps = {}
	end)
end

LENS_MODE_FISHEYE = 0
LENS_MODE_GLASS = 1
LENS_MODE_NONE = 2

function SWEP:SetLensType(lens_mode)
	local owner = self:GetOwner()
	if not owner or not owner.GetViewModel then return end
	local vm = owner:GetViewModel()
	vm:SetBodygroup(1, lens_mode)
end

function SWEP:OnRemove()
	self:Holster()

	BaseClass.OnRemove(self)
end

function SWEP:SyncIrons(irons)
	if irons then
		self:SetLensType(LENS_MODE_GLASS)
		self:ShowFootPrints(true)
	else
		self:SetLensType(LENS_MODE_FISHEYE)
		self:ShowFootPrints(false)
	end
	self:SetIronsights(irons)
	self:SetZoom(irons)
end

-- don't do anything
function SWEP:SecondaryAttack()
	local r = BaseClass.SecondaryAttack(self)
	local irons = self:GetIronsights()
	self:SyncIrons(irons)

	return r
end

function SWEP:PreDrop()
	self:SetIronsights(false)
	self:SetZoom(false)
	self:SyncIrons(false)
end

if CLIENT then
	function SWEP:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_equipment_additional")

		form:MakeHelp({
			label = "help_ttt2_snif_footsteps_lifetime",
		})
		form:MakeSlider({
			serverConvar = "ttt2_snif_footsteps_lifetime",
			label = "label_ttt2_snif_footsteps_lifetime",
			min = 0,
			max = 300,
			decimal = 0,
		})

		form:MakeHelp({
			label = "help_ttt2_snif_footblood_lifetime",
		})
		form:MakeSlider({
			serverConvar = "ttt2_snif_footblood_lifetime",
			label = "label_ttt2_snif_footblood_lifetime",
			min = 0,
			max = 300,
			decimal = 0,
		})

		form:MakeHelp({
			label = "help_ttt2_snif_lens_sound",
		})
		form:MakeCheckBox({
			serverConvar = "ttt2_snif_lens_sound",
			label = "label_ttt2_snif_lens_sound",
		})
	end
end