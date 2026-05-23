local module = {}

-- Services
local rs = game:GetService("ReplicatedStorage")
local ss = game:GetService("ServerStorage")
local starterPlayer = game:GetService("StarterPlayer")
local soundService = game:GetService("SoundService")
local debris = game:GetService("Debris")
local voxBreaker = require(game.ReplicatedStorage.Modules.VoxBreaker)

-- Folders
local events = rs.Events
local charSounds = rs.SFX.Characters
local rsModules = rs.Modules
local combatFolder = ss.Combat
local stuffFolder = ss.Stuff

-- Events
local combatEvent = events.Combat

-- Modules
local combatModule = require(combatFolder.CombatModule)
local charStatsModule = require(combatFolder.CharacterStats)
local othersModule = require(stuffFolder.Others)
local stunHandler = require(stuffFolder.StunHandlerV2)

-- Variables
local hitboxSize = Vector3.new(6, 6, 5)
local maxHitRange = 12

local function inRange(attackerHrp, targetHrp)
    if not attackerHrp or not targetHrp then return false end
    return (attackerHrp.Position - targetHrp.Position).Magnitude <= maxHitRange
end

-- Break ground voxels
local function breakGround(position)
    local voxels = voxBreaker:CreateHitbox(
        Vector3.new(3,3,3),
        CFrame.new(position.X, position.Y - 2, position.Z),
        Enum.PartType.Block,
        4,
        15
    )
    for _, voxel in pairs(voxels) do
        voxel.Anchored = false
        voxel.Velocity = Vector3.new(
            math.random(-20, 20),
            math.random(10, 30),
            math.random(-20, 20)
        )
    end
end

-- Body velocity
function module.bodyVelocity(parent, hrp, knockBack, stayTime)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, 0, math.huge)
    bv.P = 50000
    bv.Velocity = hrp.CFrame.LookVector * knockBack
    bv.Parent = parent
    debris:AddItem(bv, stayTime)
end

-- Body velocity down
function module.bvDown(parent, force, stayTime)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(0, math.huge, 0)
    bv.P = 50000
    bv.Velocity = Vector3.new(0, -force, 0)
    bv.Parent = parent
    debris:AddItem(bv, stayTime)
end

-- Body velocity up
function module.bvUp(parent, force, stayTime)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.P = 50000
    bv.Velocity = Vector3.new(0, force, 0)
    bv.Parent = parent
    debris:AddItem(bv, stayTime)
end

-- Rotate
function module.alignBellyUp(eHrp, stayTime)
    local att = Instance.new("Attachment")
    att.Parent = eHrp

    local align = Instance.new("AlignOrientation")
    align.Attachment0 = att
    align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    align.RigidityEnabled = false
    align.MaxTorque = 50000
    align.Responsiveness = 15
    align.CFrame = eHrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
    align.Parent = eHrp

    debris:AddItem(align, stayTime)
    debris:AddItem(att, stayTime)
end

-- Normal M1 hitbox
function module.normalHitboxHit(char, eHum, currentChar, hitbox, hit, hitAnim, damage, ragdollTime, knockback, stunTime)
    local eChar = eHum.Parent
    local eHrp = eChar.HumanoidRootPart
    local hrp = char.HumanoidRootPart
    local charStats = charStatsModule.getStats(currentChar)

    if not inRange(hrp, eHrp) then return end

    if damage == nil then damage = charStats.Damage end
    if ragdollTime == nil then ragdollTime = charStats.ragdollTime end
    if knockback == nil then knockback = charStats.knockBack end
    if stunTime == nil then stunTime = charStats.stunTime end

    local m1Knockback = charStats.m1Knockback

    if othersModule.CheckForStatus(eChar, char, hit.CFrame, true) then return end

    local combo = char:GetAttribute("Combo")

    eHum:TakeDamage(damage)
    combatModule.stopAnims(eHum)

    local soundObj = charSounds[currentChar].Hit["Hit" .. combo]
    local soundClone = soundObj:Clone()
    soundClone.Parent = eChar
    soundObj:Play()
    debris:AddItem(soundClone, 2)

    local success, hamonSound = pcall(function()
        return rs:WaitForChild("Sounds"):WaitForChild("MoveSounds")[currentChar].HamonHit
    end)

    if success and hamonSound then
        local s = hamonSound:Clone()
        s.Parent = eChar
        hamonSound:Play()
        debris:AddItem(s, 2)
    end

    local animator = eHum:FindFirstChildOfClass("Animator")
    if animator and hitAnim then
        animator:LoadAnimation(hitAnim):Play()
    end

    if combo >= 4 then
        module.bodyVelocity(eHrp, char.HumanoidRootPart, knockback - 15, 0.5)
        stunTime = ragdollTime
        othersModule.Ragdoll(eChar, ragdollTime)
    else
        module.bodyVelocity(eHrp, char.HumanoidRootPart, m1Knockback, 0.1)
    end

    stunHandler.Stun(eHum, stunTime, 5, 0)
end

-- Front dash hitbox
function module.frontDashHitbox(char, eHum, currentChar, hitbox, hit, hitAnim)
    local eChar = eHum.Parent
    local eHrp = eChar.HumanoidRootPart
    local hrp = char.HumanoidRootPart
    local charStats = charStatsModule.getStats(currentChar)

    if not inRange(hrp, eHrp) then return end

    local damage = charStats.Damage
    local stunTime = charStats.stunTime
    local m1Knockback = charStats.m1Knockback

    if othersModule.CheckForStatus(eChar, char, hit.CFrame, true) then return end

    eHum:TakeDamage(damage)
    combatModule.stopAnims(eHum)

    local soundObj = charSounds[currentChar].Hit.Hit3
    local soundClone = soundObj:Clone()
    soundClone.Parent = eChar
    soundObj:Play()
    debris:AddItem(soundClone, 2)

    local animator = eHum:FindFirstChildOfClass("Animator")
    if animator and hitAnim then
        animator:LoadAnimation(hitAnim):Play()
    end

    module.bodyVelocity(eHrp, char.HumanoidRootPart, m1Knockback, 0.1)
    stunHandler.Stun(eHum, stunTime, 5, 0)
end

-- Uppercut hitbox
function module.upperCutHitbox(char, eHum, currentChar, hitbox, hit, hitAnim)
    local eChar = eHum.Parent
    local eHrp = eChar.HumanoidRootPart
    local hrp = char.HumanoidRootPart
    local charStats = charStatsModule.getStats(currentChar)

    if not inRange(hrp, eHrp) then return end

    local damage = charStats.Damage
    local downSlamKnockback = charStats.downSlamKnockback
    local ragdollTime = charStats.ragdollTime
    local stunTime = charStats.stunTime

    if othersModule.CheckForStatus(eChar, char, hit.CFrame) then return end

    eHum:TakeDamage(damage)
    combatModule.stopAnims(eHum)

    local soundObj = charSounds[currentChar].Hit.Hit4
    local soundClone = soundObj:Clone()
    soundClone.Parent = eChar
    soundObj:Play()
    debris:AddItem(soundClone, 2)

    local animator = eHum:FindFirstChildOfClass("Animator")
    if animator and hitAnim then
        animator:LoadAnimation(hitAnim):Play()
    end

    local function breakGroundLocal(position)
        local voxels = voxBreaker:CreateHitbox(
            Vector3.new(3,3,3),
            CFrame.new(position.X, position.Y - 2, position.Z),
            Enum.PartType.Block,
            4,
            15
        )
        for _, voxel in pairs(voxels) do
            voxel.Anchored = false
            voxel.Velocity = Vector3.new(
                math.random(-20, 20),
                math.random(10, 30),
                math.random(-20, 20)
            )
        end
    end

    breakGroundLocal(eHrp.Position)

    module.bvUp(eHrp, downSlamKnockback, 0.1)
    stunTime = ragdollTime
    othersModule.Ragdoll(eChar, ragdollTime)
    stunHandler.Stun(eHum, stunTime, 0, 0)
end

-- Downslam hitbox
function module.downSlamHitbox(char, eHum, currentChar, hitbox, hit, hitAnim)
    local eChar = eHum.Parent
    local eHrp = eChar.HumanoidRootPart
    local hrp = char.HumanoidRootPart
    local charStats = charStatsModule.getStats(currentChar)

    if not inRange(hrp, eHrp) then return end

    local damage = charStats.Damage
    local downSlamKnockback = charStats.downSlamKnockback
    local stunTime = charStats.stunTime

    if othersModule.CheckForStatus(eChar, char, hit.CFrame) then return end

    eHum:TakeDamage(damage)
    combatModule.stopAnims(eHum)

    local soundObj = charSounds[currentChar].Hit.Hit4
    local soundClone = soundObj:Clone()
    soundClone.Parent = eChar
    soundObj:Play()
    debris:AddItem(soundClone, 2)

    stunHandler.Stun(eHum, stunTime, 0, 0)
    eHum:ChangeState(Enum.HumanoidStateType.Physics)

    module.alignBellyUp(eHrp, 1)

    task.wait(0.06)
    eHrp.AssemblyLinearVelocity = Vector3.zero
    eHrp.AssemblyAngularVelocity = Vector3.zero

    module.bvDown(eHrp, downSlamKnockback, 0.2)

    local attach = Instance.new("Attachment", eHrp)

    local alignPos = Instance.new("AlignPosition")
    alignPos.Attachment0 = attach
    alignPos.Position = eHrp.Position
    alignPos.MaxForce = 100000
    alignPos.Responsiveness = 200
    alignPos.Parent = eHrp

    local alignOri = Instance.new("AlignOrientation")
    alignOri.Attachment0 = attach
    alignOri.CFrame = eHrp.CFrame
    alignOri.MaxTorque = 100000
    alignOri.Responsiveness = 200
    alignOri.Parent = eHrp

    local function breakGroundLocal(position)
        local voxels = voxBreaker:CreateHitbox(
            Vector3.new(3,3,3),
            CFrame.new(position.X, position.Y - 2, position.Z),
            Enum.PartType.Block,
            4,
            15
        )
        for _, voxel in pairs(voxels) do
            voxel.Anchored = false
            voxel.Velocity = Vector3.new(
                math.random(-20, 20),
                math.random(10, 30),
                math.random(-20, 20)
            )
        end
    end

    breakGroundLocal(eHrp.Position)

    debris:AddItem(alignOri, 0.3)

    othersModule.Ragdoll(eChar, stunTime)

    task.delay(0.3, function()
        if eHum then
            eHum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

function module.abilitiesHitbox(char, eHum, currentChar, hitbox, hit, hitAnim, damage, ragdollTime, knockback, stunTime)
    local eChar = eHum.Parent
    local eHrp = eChar.HumanoidRootPart
    local hrp = char.HumanoidRootPart
    local charStats = charStatsModule.getStats(currentChar)

    if damage == nil then damage = charStats.Damage end
    if ragdollTime == nil then ragdollTime = charStats.ragdollTime end
    if knockback == nil then knockback = charStats.knockBack end
    if stunTime == nil then stunTime = charStats.stunTime end

    if othersModule.CheckForStatus(eChar, char, hit.CFrame, true) then return end

    eHum:TakeDamage(damage)
    if eHum.Health <= 0 then return end

    combatModule.stopAnims(eHum)

    local success, hamonSound = pcall(function()
        return rs:WaitForChild("Sounds"):WaitForChild("MoveSounds")[currentChar].HamonHit
    end)

    if success and hamonSound then
        local s = hamonSound:Clone()
        s.Parent = eChar
        hamonSound:Play()
        debris:AddItem(s, 2)
    end

    local animator = eHum:FindFirstChildOfClass("Animator")
    if animator and hitAnim then
        animator:LoadAnimation(hitAnim):Play()
    end

    module.bodyVelocity(eHrp, hrp, knockback, 0.15)
    stunHandler.Stun(eHum, stunTime, 5, 0)
    breakGround(eHrp.Position)

    local function breakGroundLocal(position)
        local voxels = voxBreaker:CreateHitbox(
            Vector3.new(3,3,3),
            CFrame.new(position.X, position.Y - 2, position.Z),
            Enum.PartType.Block,
            2,
            10
        )
        for _, voxel in pairs(voxels) do
            voxel.Anchored = false
            voxel.Velocity = Vector3.new(
                math.random(-20, 20),
                math.random(10, 30),
                math.random(-20, 20)
            )
        end
    end

    breakGroundLocal(eHrp.Position)
end

return module
