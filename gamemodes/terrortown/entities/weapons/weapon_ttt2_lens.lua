-- Lens created by Alf21
-- magnifying glass model by https://gamebanana.com/skins/13032 (by magNet) -> models/magni/magniglass.mdl
-- made with the help of https://facepunch.com/threads/1032378 (by Clavus)

DEFINE_BASECLASS "weapon_tttbase"

if SERVER then
	AddCSLuaFile()

	-- materials
	resource.AddFile("materials/models/magni/magni_sheet.vmt")
	resource.AddFile("materials/vgui/ttt/footstep.vmt")
	resource.AddFile("materials/vgui/ttt/footblood.vmt")

	-- models
	resource.AddFile("models/magni/magniglass.mdl")
	resource.AddFile("models/magni/v_shuriken.mdl")

	-- sound
	resource.AddFile("sound/ttt2/footsteps.mp3")

	util.AddNetworkString("addFootstep")
	util.AddNetworkString("clearAllFootsteps")
	util.AddNetworkString("TTT2SnifferSendKiller")
end

util.PrecacheSound("ttt2/footsteps.mp3")

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
		type  = "item_weapon",
	  	desc  = "You are able to see footsteps!"
	}

	SWEP.ViewModelBoneMods = {
		["shuriken"] = {
			scale = Vector(0.009, 0.009, 0.009),
			pos = Vector(0, 6.48, 0),
			angle = Angle(0, 0, 0)
		}
	}

	SWEP.VElements = {
		["magniglass"] = {
			type = "Model",
			model = "models/magni/magniglass.mdl",
			bone = "shuriken",
			rel = "",
			pos = Vector(-1, 10, 0),
			angle = Angle(-30, 135, 50),
			size = Vector(0.69, 0.69, 0.69),
			color = Color(255, 255, 255, 255),
			surpresslightning = false,
			material = "",
			skin = 0,
			bodygroup = {}
		}
	}

	SWEP.WElements = {
		["magniglass"] = {
			type = "Model",
			model = "models/magni/magniglass.mdl",
			bone = "ValveBiped.Bip01_R_Hand",
			rel = "",
			--x, runter
			pos = Vector(4, 3, -3),
			angle = Angle(110, -45, -130),
			size = Vector(0.69, 0.69, 0.69),
			color = Color(255, 255, 255, 255),
			surpresslightning = false,
			material = "",
			skin = 0,
			bodygroup = {}
		}
	}

	SWEP.Icon = "vgui/ttt/icon_binoc" -- TODO: yea we need a new icon
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/magni/v_shuriken.mdl"
SWEP.WorldModel = "models/magni/magniglass.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true

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

-- don't do anything
function SWEP:PrimaryAttack()

end

-- don't do anything
function SWEP:SecondaryAttack()

end

-- disable drop
SWEP.AllowDrop = false

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:ShouldDropOnDie()
    return false
end

--------------------
-- footstep handling

local plymeta = FindMetaTable("Player")
if not plymeta then return end

function plymeta:CanSeeFootsteps()
	return self:Alive() and self:IsTerror() and self:HasWeapon("weapon_ttt2_lens")
end

function plymeta:CanSeeFootblood(target)
	if not self:CanSeeFootsteps() or not IsValid(target) or not target:IsPlayer() then
		return false
	end

	local isKiller = target.snifferIsKiller
	if isKiller then
		isKiller = isKiller + GetGlobalInt("ttt2_snif_footblood_lifetime", 0) >= CurTime()

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
			inBloodTime = ply.snifferBloody + GetGlobalInt("ttt2_snif_footblood_lifetime") >= CurTime()

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

	hook.Add("TTTPrepareRound", "TTT2SnifClearAllFootsteps", function()
		for _, v in ipairs(player.GetAll()) do
			v.snifferBloody = nil
			v.snifferKilled = nil
		end

		net.Start("clearAllFootsteps")
		net.Broadcast()
	end)

	hook.Add("TTT2SyncGlobals", "SyncSnifferGlobals", function()
		SetGlobalInt("ttt2_snif_footsteps_lifetime", CreateConVar("ttt2_snif_footsteps_lifetime", 15, {FCVAR_NOTIFY, FCVAR_ARCHIVE}):GetInt())
		SetGlobalInt("ttt2_snif_footblood_lifetime", CreateConVar("ttt2_snif_footblood_lifetime", 30, {FCVAR_NOTIFY, FCVAR_ARCHIVE}):GetInt())
	end)

	cvars.AddChangeCallback("ttt2_snif_footsteps_lifetime", function(name, old, new)
		SetGlobalInt(name, tonumber(new))
	end, "ttt2_snif_footsteps_lifetime")

	cvars.AddChangeCallback("ttt2_snif_footblood_lifetime", function(name, old, new)
		SetGlobalInt(name, tonumber(new))
	end, "ttt2_snif_footblood_lifetime")

	hook.Add("TTT2PostPlayerDeath", "TTT2SnifferBloodMarker", function(victim, infl, attacker)
		victim.snifferKilled = nil

		if IsValid(attacker) and attacker:IsPlayer() then
			attacker.snifferBloody = CurTime()
			victim.snifferKilled = attacker
		end
	end

	hook.Add("TTTBodyFound", "TTT2SnifferRegisterBlood", function(finder, deadply)
		if IsValid(deadply) and deadply.snifferKilled then
			local killer = deadply.snifferKilled

			killer.snifferIsKiller = killer.snifferBloody

			net.Start("TTT2SnifferSendKiller")
			net.WriteEntity(killer)
			net.WriteUInt(32, killer.snifferIsKiller)
			net.Broadcast()
		end
	end)

	function SWEP:Deploy()
		local owner = self:GetOwner()

		if IsValid(owner) and owner:Alive() and owner:IsTerror() then
			owner:EmitSound("ttt2/footsteps.mp3")
		end
	end
else
	local footbloodMat = Material("vgui/ttt/footblood")
	local footstepMat = Material("vgui/ttt/footstep")
	local maxDistance = 360000
	local footsteps = {}
	local footSize = 12
	local bloodcolor = Color(180, 21, 21)

	-- improved and modified code of https:--github.com/MechanicalMind/murder/blob/master/gamemode/cl_footsteps.lua
	local function DrawFootsteps()
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
			if v.b and client:CanSeeFootblood() then
				render.DrawQuadEasy(v.p, v.n, v.f and -(v.h) or v.h, v.h, bloodcolor, v.r)
			end
		end

		render.SetMaterial(footstepMat)

		for _, v in ipairs(drawTable) do
			render.DrawQuadEasy(v.p, v.n, v.f and (v.h * -0.5) or (v.h * 0.5), v.h, v.c, v.r)
		end

		cam.End3D()
	end

	local function UpdateFootsteps()
		local lifeTime = math.Clamp(GetGlobalInt("ttt2_snif_footsteps_lifetime"), 0, 30)

		for k, footstep in pairs(footsteps) do
			if footstep.curtime + lifeTime < CurTime() then
				footsteps[k] = nil
			end
		end
	end

	-- performance improvements
	function SWEP:Deploy()
		local owner = self:GetOwner()

		if not hook_installed and IsValid(owner) and owner == LocalPlayer() and owner:Alive() and owner:IsTerror() then
			hook.Add("PostDrawTranslucentRenderables", "TTT2SnifDrawFootSteps", DrawFootsteps)
			hook.Add("Think", "TTT2UpdateFootsteps", UpdateFootsteps)

			hook_installed = true
		end
	end

	function SWEP:Holster()
		local owner = self:GetOwner()

		if not IsValid(owner) then
			return true
		end

		if hook_installed and owner == LocalPlayer() then
			hook.Remove("PostDrawTranslucentRenderables", "TTT2SnifDrawFootSteps")
			hook.Remove("Think", "TTT2UpdateFootsteps")

			hook_installed = false
		end

		local vm = owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	end

	function SWEP:OnRemove()
		self:Holster()
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
		tbl.col = ply:GetRoleColor()
		tbl.bloody = bloody

		hook.Run("TTT2SnifferModifyFootstep", ply, tbl)

		footsteps[#footsteps + 1] = tbl
	end)

	net.Receive("clearAllFootsteps", function()
		footsteps = {}
	end)
end

--[[----------------------------------------------------
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378


	DESCRIPTION:
		This script is meant for experienced scripters
		that KNOW WHAT THEY ARE DOING. Don't come to me
		with basic Lua questions.

		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.

		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
------------------------------------------------------]]

-- World-/Viewmodel handling
function SWEP:GetViewModelPosition(pos, ang)
	pos = pos + ang:Forward() * 5.48
	pos = pos + ang:Right() * 2.68
	pos = pos + ang:Up() * 1.96

	return pos, ang
end

-----------------------------------------
-- and now, let's create a nice viewmodel
function SWEP:Initialize()
	if CLIENT then
		-- Create a new table for every weapon instance
		self.VElements = table.FullCopy(self.VElements)
		self.WElements = table.FullCopy(self.WElements)
		self.ViewModelBoneMods = table.FullCopy(self.ViewModelBoneMods)

		self:CreateModels(self.VElements) -- create viewmodels
		self:CreateModels(self.WElements) -- create worldmodels

		-- init view model bone build function
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)

				-- Init viewmodel visibility
				if self.ShowViewModel == nil or self.ShowViewModel then
					vm:SetColor(Color(255, 255, 255, 255))
				else
					-- we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255, 255, 255, 1))
					-- ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					-- however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")
				end
			end
		end
	end
end

if CLIENT then
	SWEP.vRenderOrder = nil

	function SWEP:ViewModelDrawn()
		local vm = self.Owner:GetViewModel()
		if not IsValid(vm) or not self.VElements then return end

		self:UpdateBonePositions(vm)

		if not self.vRenderOrder then

			-- we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}

			for k, v in pairs(self.VElements) do
				if v.type == "Model" then
					table.insert(self.vRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.vRenderOrder, k)
				end
			end
		end

		for k, name in ipairs(self.vRenderOrder) do
			local v = self.VElements[name]
			if not v then
				self.vRenderOrder = nil

				break
			end

			if v.hide then continue end

			local model = v.modelEnt
			local sprite = v.spriteMaterial

			if not v.bone then continue end

			local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)

			if not pos then continue end

			if v.type == "Model" and IsValid(model) then
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)

				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				--model:SetModelScale(v.size)

				local matrix = Matrix()
				matrix:Scale(v.size)

				model:EnableMatrix("RenderMultiply", matrix)

				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() ~= v.material then
					model:SetMaterial(v.material)
				end

				if v.skin and v.skin ~= model:GetSkin() then
					model:SetSkin(v.skin)
				end

				if v.bodygroup then
					for k, v in pairs(v.bodygroup) do
						if model:GetBodygroup(k) ~= v then
							model:SetBodygroup(k, v)
						end
					end
				end

				if v.surpresslightning then
					render.SuppressEngineLighting(true)
				end

				render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
				render.SetBlend(v.color.a / 255)

				model:DrawModel()

				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)

				if v.surpresslightning then
					render.SuppressEngineLighting(false)
				end
			elseif v.type == "Sprite" and sprite then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z

				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			elseif v.type == "Quad" and v.draw_func then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z

				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				cam.Start3D2D(drawpos, ang, v.size)

				v.draw_func(self)

				cam.End3D2D()
			end
		end
	end

	SWEP.wRenderOrder = nil

	function SWEP:DrawWorldModel()
		if not IsValid(self:GetOwner()) then
			self:DrawModel()
		end

		if not self.WElements then return end

		if not self.wRenderOrder then
			self.wRenderOrder = {}

			for k, v in pairs(self.WElements) do
				if v.type == "Model" then
					table.insert(self.wRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.wRenderOrder, k)
				end
			end
		end

		if IsValid(self.Owner) then
			bone_ent = self.Owner
		else
			-- when the weapon is dropped
			bone_ent = self
		end

		for _, name in pairs(self.wRenderOrder) do
			local v = self.WElements[name]
			if not v then
				self.wRenderOrder = nil

				break
			end

			if v.hide then continue end

			local pos, ang

			if v.bone then
				pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent)
			else
				pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand")
			end

			if not pos then continue end

			local model = v.modelEnt
			local sprite = v.spriteMaterial

			if v.type == "Model" and IsValid(model) then
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)

				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				--model:SetModelScale(v.size)

				local matrix = Matrix()
				matrix:Scale(v.size)

				model:EnableMatrix("RenderMultiply", matrix)

				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() ~= v.material then
					model:SetMaterial(v.material)
				end

				if v.skin and v.skin ~= model:GetSkin() then
					model:SetSkin(v.skin)
				end

				if v.bodygroup then
					for k, v in pairs(v.bodygroup) do
						if model:GetBodygroup(k) ~= v then
							model:SetBodygroup(k, v)
						end
					end
				end

				if v.surpresslightning then
					render.SuppressEngineLighting(true)
				end

				render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
				render.SetBlend(v.color.a / 255)

				model:DrawModel()

				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)

				if v.surpresslightning then
					render.SuppressEngineLighting(false)
				end
			elseif v.type == "Sprite" and sprite then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z

				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			elseif v.type == "Quad" and v.draw_func then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z

				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				cam.Start3D2D(drawpos, ang, v.size)

				v.draw_func(self)

				cam.End3D2D()
			end
		end
	end

	function SWEP:GetBoneOrientation(basetab, tbl, ent, bone_override)
		local bone, pos, ang

		if tbl.rel and tbl.rel ~= "" then
			local v = basetab[tbl.rel]
			if not v then return end

			-- Technically, if there exists an element with the same name as a bone
			-- you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang = self:GetBoneOrientation(basetab, v, ent)

			if not pos then return end

			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z

			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
		else
			bone = ent:LookupBone(bone_override or tbl.bone)

			if not bone then return end

			pos, ang = Vector(0, 0, 0), Angle(0, 0, 0)

			local m = ent:GetBoneMatrix(bone)
			if m then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end

			if IsValid(self.Owner) and self.Owner:IsPlayer() and ent == self.Owner:GetViewModel() and self.ViewModelFlip then
				ang.r = -ang.r -- Fixes mirrored models
			end

		end

		return pos, ang
	end

	function SWEP:CreateModels(tbl)
		if not tbl then return end

		-- Create the clientside models here because Garry says we can't do it in the render hook
		for _, v in pairs(tbl) do
			if v.type == "Model" and v.model and v.model ~= ""
			and (not IsValid(v.modelEnt) or v.createdModel ~= v.model)
			and string.find(v.model, ".mdl") and file.Exists(v.model, "GAME")
			then
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)

				if IsValid(v.modelEnt) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)

					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
			elseif v.type == "Sprite" and v.sprite and v.sprite ~= ""
			and (not v.spriteMaterial or v.createdSprite ~= v.sprite)
			and file.Exists("materials/" .. v.sprite .. ".vmt", "GAME")
			then
				local name = v.sprite .. "-"
				local params = {["$basetexture"] = v.sprite}

				-- make sure we create a unique name based on the selected options
				local tocheck = {"nocull", "additive", "vertexalpha", "vertexcolor", "ignorez"}
				for i, j in pairs(tocheck) do
					if v[j] then
						params["$" .. j] = 1

						name = name .. "1"
					else
						name = name .. "0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name, "UnlitGeneric", params)
			end
		end
	end

	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		if self.ViewModelBoneMods then
			if not vm:GetBoneCount() then return end

			-- !! WORKAROUND !! --
			-- We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods

			if not hasGarryFixedBoneScalingYet then
				allbones = {}

				for i = 0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)

					if self.ViewModelBoneMods[bonename] then
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = {
							scale = Vector(1, 1, 1),
							pos = Vector(0, 0, 0),
							angle = Angle(0, 0, 0)
						}
					end
				end

				loopthrough = allbones
			end
			-- !! ----------- !! --

			for k, v in pairs(loopthrough) do
				local bone = vm:LookupBone(k)
				if not bone then continue end

				-- !! WORKAROUND !! --
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if not hasGarryFixedBoneScalingYet then
					local cur = vm:GetBoneParent(bone)
					while cur >= 0 do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale

						ms = ms * pscale

						cur = vm:GetBoneParent(cur)
					end
				end

				s = s * ms
				-- !! ----------- !! --

				if vm:GetManipulateBoneScale(bone) ~= s then
					vm:ManipulateBoneScale(bone, s)
				end

				if vm:GetManipulateBoneAngles(bone) ~= v.angle then
					vm:ManipulateBoneAngles(bone, v.angle)
				end

				if vm:GetManipulateBonePosition(bone) ~= p then
					vm:ManipulateBonePosition(bone, p)
				end
			end
		else
			self:ResetBonePositions(vm)
		end
	end

	function SWEP:ResetBonePositions(vm)
		if not vm:GetBoneCount() then return end

		for i = 0, vm:GetBoneCount() do
			vm:ManipulateBoneScale(i, Vector(1, 1, 1))
			vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
			vm:ManipulateBonePosition(i, Vector(0, 0, 0))
		end
	end

	--[[-----------------------
		Global utility code
	-------------------------]]

	-- Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
	-- Does not copy entities of course, only copies their reference.
	-- WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
	function table.FullCopy(tbl)
		if not tbl then return end

		local res = {}

		for k, v in pairs(tbl) do
			if type(v) == "table" then
				res[k] = table.FullCopy(v) -- recursion ho!
			elseif type(v) == "Vector" then
				res[k] = Vector(v.x, v.y, v.z)
			elseif type(v) == "Angle" then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end

		return res
	end
end
