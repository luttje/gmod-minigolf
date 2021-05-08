-- Ripped from The Last Of Us: https://steamcommunity.com/sharedfiles/filedetails/?id=2157948565

---Plays weapon sounds
---@param entity table
---@param sound table or string
---@param volOverride number Between 0.0 -> 1.0
local function playWeaponSound(entity, sound, volOverride)
  if not IsValid(entity) or not sound then return end

  if istable(sound) then
    sound = table.Random(sound)
  end

  entity:EmitSound(sound, 100, 100, volOverride or 0.5, CHAN_WEAPON)
end

local soundsImpactWorld = {
  "physics/cardboard/cardboard_box_impact_hard1.wav",
  "physics/cardboard/cardboard_box_impact_hard2.wav",
  "physics/cardboard/cardboard_box_impact_hard3.wav",
  "physics/cardboard/cardboard_box_impact_hard4.wav",
  "physics/cardboard/cardboard_box_impact_hard5.wav",
  "physics/cardboard/cardboard_box_impact_hard6.wav",
}

local soundsImpactSmash = {
  "physics/flesh/flesh_impact_hard1.wav",
  "physics/flesh/flesh_impact_hard2.wav",
  "physics/flesh/flesh_impact_hard3.wav",
  "physics/flesh/flesh_impact_hard4.wav",
  "physics/flesh/flesh_impact_hard5.wav",
  "physics/flesh/flesh_impact_hard6.wav"
}

local soundsImpactHeavy =  {
  "physics/flesh/flesh_bloody_break.wav",
  "physics/body/body_medium_break2.wav",
  "physics/body/body_medium_break3.wav",
  "physics/body/body_medium_break4.wav",
  "physics/plaster/ceilingtile_break1.wav",
  "physics/plaster/ceilingtile_break2.wav",
  "npc/zombie/zombie_hit.wav",
  "npc/vort/foot_hit.wav"
}

local soundsImpactBall = {
  "physics/metal/soda_can_impact_soft1.wav",
  "physics/metal/soda_can_impact_soft2.wav",
  "physics/metal/soda_can_impact_soft3.wav"
}

local soundsSwing = {
  "npc/vort/claw_swing1.wav",
  "npc/vort/claw_swing2.wav"
}

if CLIENT then
  SWEP.WepSelectIcon     = surface.GetTextureID("vgui/hud/tlouii_club")
  SWEP.DrawWeaponInfoBox = false
  SWEP.BounceWeaponIcon  = false
  killicon.Add("tlouii_club", "vgui/hud/tlouii_club", Color(202, 92, 205, 255))
else
  resource.AddFile("models/weapons/melee/v_golfclub.mdl")
  resource.AddFile("models/weapons/melee/w_golfclub.mdl")
  resource.AddFile("materials/models/weapons/melee/golf_club.vmt")
  resource.AddFile("materials/models/weapons/melee/golf_club_normal.vtf")
end

SWEP.PrintName             = "Golf Club"

SWEP.Category              = "Minigolf"

SWEP.Spawnable             = true
SWEP.AdminSpawnable        = true
SWEP.AdminOnly             = false

SWEP.ViewModelFOV          = 50
SWEP.ViewModel             = "models/weapons/melee/v_golfclub.mdl"
SWEP.WorldModel            = "models/weapons/melee/w_golfclub.mdl"
SWEP.ViewModelFlip         = false

SWEP.SwayScale             = 0.5
SWEP.BobScale              = 0.5

SWEP.AutoSwitchTo          = false
SWEP.AutoSwitchFrom        = false
SWEP.Weight                = 5

SWEP.Slot                  = 0
SWEP.SlotPos               = 0

SWEP.UseHands              = true
SWEP.HoldType              = "melee"
SWEP.FiresUnderwater       = true
SWEP.DrawCrosshair         = true
SWEP.DrawAmmo              = true
SWEP.CSMuzzleFlashes       = 1
SWEP.Base                  = "weapon_base"

SWEP.Idle                  = 0
SWEP.IdleTimer             = CurTime()

SWEP.Primary.ClipSize      = -1
SWEP.Primary.DefaultClip   = -1
SWEP.Primary.Automatic     = false
SWEP.Primary.Ammo          = "none"
SWEP.Primary.Damage        = 0
SWEP.Primary.Recoil        = 0.5
SWEP.Primary.Delay         = 0.8

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.Damage      = 0
SWEP.Secondary.Recoil      = 1
SWEP.Secondary.Delay       = 1

function SWEP:Initialize()
  self:SetWeaponHoldType(self.HoldType)
  self.Idle      = 0
  self.IdleTimer = CurTime() + 1
end

function SWEP:Deploy()
  self:SetWeaponHoldType(self.HoldType)
  self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
  self:SetNextPrimaryFire(CurTime() + self.Owner:GetViewModel():SequenceDuration())
  self:SetNextSecondaryFire(CurTime() + self.Owner:GetViewModel():SequenceDuration())
  self.Idle      = 0
  self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
end

function SWEP:Holster()
  self.Idle      = 0
  self.IdleTimer = CurTime()

  return true
end

function SWEP:PrimaryAttack()
  -- Set next attack time
  self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
  self.Weapon:SetNextSecondaryFire(CurTime() + self.Secondary.Delay / 1.5)

  if not IsValid(self:GetOwner()) then return end

  -- Start lag compensation
  if self:GetOwner().LagCompensation then
    self:GetOwner():LagCompensation(true)
  end

  -- Do animations
  self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)
  self.Owner:SetAnimation(PLAYER_ATTACK1)

  playWeaponSound(self, soundsSwing)

  self.Idle      = 0
  self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()

  local tr       = util.TraceLine({
    start  = self.Owner:GetShootPos(),
    endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 80,
    filter = self.Owner,
    mask   = MASK_SHOT_HULL,
  })

  if not IsValid(tr.Entity) then
    tr = util.TraceHull({
      start  = self.Owner:GetShootPos(),
      endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 80,
      filter = self.Owner,
      mins   = Vector(-16, -16, 0),
      maxs   = Vector(16, 16, 0),
      mask   = MASK_SHOT_HULL,
    })
  end

  if SERVER then
    -- Player makes a shot
    if self.Owner:GetBallGivingForce() then
      playWeaponSound(tr.Entity, soundsImpactBall)
    end

    -- Player hits the world
    if tr.HitWorld and not self.Owner:GetBallGivingForce() then
      playWeaponSound(self, soundsImpactWorld)
    end

    -- Special sounds for hitting characters
    if tr.Hit and tr.Entity:IsNPC() or tr.Entity:IsPlayer() then
      playWeaponSound(tr.Entity, soundsImpactHeavy, 0.7)
    end
  end

  self.Owner:ViewPunchReset()
  self.Owner:ViewPunch(Angle(4 * self.Primary.Recoil, -10 * self.Primary.Recoil, 0))

  -- End lag compensation
  if self:GetOwner().LagCompensation then
    self:GetOwner():LagCompensation(false)
  end
end

function SWEP:SecondaryAttack()
  local worldHit = true

  -- Set attack timers
  self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
  self.Weapon:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

  if not IsValid(self:GetOwner()) then return end

  --Start lag compensation
  if self:GetOwner().LagCompensation then
    self:GetOwner():LagCompensation(true)
  end

  -- Play swing sound
  playWeaponSound(self, soundsSwing)

  local tr = util.TraceLine({
    start  = self.Owner:GetShootPos(),
    endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 75,
    filter = self.Owner,
    mask   = MASK_SHOT_HULL,
  })

  if not IsValid(tr.Entity) then
    tr = util.TraceHull({
      start  = self.Owner:GetShootPos(),
      endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 75,
      filter = self.Owner,
      mins   = Vector(-16, -16, 0),
      maxs   = Vector(16, 16, 0),
      mask   = MASK_SHOT_HULL,
    })
  end

  -- Serverside functions and logic
  if SERVER and IsValid(tr.Entity) then
    -- Hit world, do nothing special
    if tr.HitWorld then
      -- Nothing?
    end

    -- Play sound only when hitting characters
    if tr.Entity:IsNPC() or tr.Entity:IsPlayer() then
      playWeaponSound(tr.Entity, soundsImpactSmash, 0.7)

      worldHit = false
    end
  end

  -- Animations
  self.Weapon:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
  self.Owner:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND)

  self.Idle      = 0
  self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()

  -- Prevent spammage
  self.Weapon:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)

  -- Little logic to prevent cloned code, only set high delay on entity hit.
  if worldHit then
    self.Weapon:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
  else
    self.Weapon:SetNextSecondaryFire(CurTime() + self.Secondary.Delay * 5)
  end

  -- End lag compensation
  if self:GetOwner().LagCompensation then
    self:GetOwner():LagCompensation(false)
  end
end

function SWEP:Reload()
end

function SWEP:Think()
  if self.Idle == 0 and self.IdleTimer > CurTime() and self.IdleTimer < CurTime() + 0.1 then
    self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
    self.Idle = 1
  end
end