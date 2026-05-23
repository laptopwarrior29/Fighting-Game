local module = {}

-- GentleMan Character 

--// Services //--
local replicated = game:GetService("ReplicatedStorage")
local ss = game:GetService("ServerStorage")
local sss = game:GetService("ServerScriptService")
local rs = game:GetService("RunService")
local starterPlr = game:GetService("StarterPlayer")
local soundService = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local Players = game:GetService("Players")

--// Modules //--
local CharacterStatsModule = require(ss.Combat.CharacterStats)
local hitModule = require(ss.Combat.Hit)
local combatModule = require(ss.Combat.CombatModule)
local othersModule = require(ss.Stuff.Others)
local CooldownManager = require(ss.Combat.CooldownManager)
local StunHandler = require(ss.Stuff.StunHandlerV2)

--// Variables //--
local hitboxSize = Vector3.new(6, 8, 5)
local hitboxTime = 0.05
local ComboResetTime = 0.2
local COOLDOWN = 0.1

--// Events //--
local valueEvent = replicated.Events.Value

--// Tables //--
local movesetStats = {
	["ZoomPunch"] = { Damage = 6, cooldown = 17, knockBack = 25, stunTime = 2, ragdollTime = 2 },
	["OverdriveBarrage"] = { Damage = 0.95, cooldown = 15, knockBack = 50, stunTime = 1 },
	["Overdrive"] = { Damage = 7.5, cooldown = 20, knockBack = 50, stunTime = 2, ragdollTime = 2 },
	["Pluck"] = { Damage = 5.25, cooldown = 25, knockBack = 50, stunTime = 3, ragdollTime = 3 },
}

local ultMoveStats = {
	["Sendo"] = { Damage = 8, cooldown = 15, knockBack = 30, stunTime = 2, ragdollTime = 2 },
	["Scarlet"] = { Damage = 1.2, cooldown = 15, knockBack = 50, stunTime = 1 },
	["YellowOverdrive"] = { Damage = 9, cooldown = 20, knockBack = 55, stunTime = 2, ragdollTime = 2 },
	["UltimatePluck"] = { Damage = 7, cooldown = 25, knockBack = 55, stunTime = 3, ragdollTime = 3 },
}

local Welds = {}

local UltimateDuration = 100
local Maxult = 250

-- Helper: Get Model from Part
local function getModel(hit)
	local current = hit
	while current and current ~= workspace do
		if current:IsA("Model") and current:FindFirstChild("Humanoid") then
			return current
		end
		current = current.Parent
	end
	return nil
end

--// Zoom Punch
function module.ZoomPunch(char)
	if not char then return end
	local humanoid = char.Humanoid
	local root = char.HumanoidRootPart
	local plr = Players:GetPlayerFromCharacter(char)
	
	local noCooldownValue = char:FindFirstChild("Combat").NoCooldowns
	
	if not humanoid or not root then return end
	if othersModule.CheckForAttributes(char, nil, true, true, true, nil, true, true, true) then return end
	
	if noCooldownValue.Value == true then
		CooldownManager:resetCooldowns(char)
		task.wait(0.05)
	else
		if CooldownManager:IsOnCooldown(char, "ZoomPunch") then 
			print("Zoom Punch is on  cooldown!!!")
			return 
		end
	end

	char:SetAttribute("Attacking", true)
	char:SetAttribute("UsingAbility", true)
	
	
	if noCooldownValue.Value == false then
		CooldownManager:setCooldown(char, "ZoomPunch", movesetStats["ZoomPunch"].cooldown)
	else
		task.delay(0.05, function()
			CooldownManager:resetCooldowns(char)
		end)
	end
	
	--print("Zoom Punch")

	local zoomAnim = replicated:WaitForChild("Animations"):WaitForChild("Characters"):WaitForChild("GentleMan"):WaitForChild("Moveset").ZoomPunch
	local zoomTrack = humanoid:LoadAnimation(zoomAnim)
	zoomTrack:Play()

	local currentChar = char:GetAttribute("Class")
	local damage = movesetStats["ZoomPunch"].Damage
	local ragdollTime = movesetStats["ZoomPunch"].ragdollTime
	local stunTime = movesetStats["ZoomPunch"].stunTime
	local knockback = movesetStats["ZoomPunch"].knockBack

	humanoid.WalkSpeed = 3
	humanoid.JumpHeight = 0

	zoomTrack:GetMarkerReachedSignal("Start"):Connect(function()
		local hitbox = Instance.new("Part")
		hitbox.Size = hitboxSize
		hitbox.Transparency = 0.7
		hitbox.CanCollide = false
		hitbox.Anchored = false
		hitbox.Massless = true
		hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -4)
		hitbox.Parent = workspace
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = hitbox
		weld.C1 = CFrame.new(0,0,5)
		weld.Parent = hitbox
		debris:AddItem(hitbox, hitboxTime)

		local hitOnce = {}
		hitbox.Touched:Connect(function(hit)
			local eChar = getModel(hit)
			local eHum = eChar and eChar:FindFirstChild("Humanoid")
			local eRoot = eChar and eChar:FindFirstChild("HumanoidRootPart")
			if eHum and eChar ~= char and not hitOnce[eChar] then
				hitOnce[eChar] = true
				hitModule.Abilities_Hitbox(char, eHum, currentChar, hitbox, hit, nil, damage, ragdollTime, knockback, stunTime)
				if eChar:GetAttribute("IsBlocking") == true then return end
				
				valueEvent:FireClient(plr, damage)
				--applyKillEnhancedKnockback(eRoot, root, knockback, damage, eHum, 0.15)
				if (eHum.Health - damage) > 0 then
					hitModule.BodyVelocity(root, root, -knockback * 0.6, 0.1)
				end
			end
		end)
	end)

	zoomTrack:GetMarkerReachedSignal("End"):Connect(function()
		char:SetAttribute("Attacking", true)
		task.wait(0.15)
		char:SetAttribute("Attacking", false)
		char:SetAttribute("UsingAbility", false)
	end)

	zoomTrack.Stopped:Connect(function()
		if not char:GetAttribute("IsBlocking") then
			combatModule.SetComboTo(char, 1)
			humanoid.WalkSpeed = starterPlr.CharacterWalkSpeed
			humanoid.JumpHeight = starterPlr.CharacterJumpHeight
		end
	end)
end

--// Overdrive Barrage
function module.OverdriveBarrage(char)
	if not char then return end
	local humanoid = char.Humanoid
	local root = char.HumanoidRootPart
	local plr = Players:GetPlayerFromCharacter(char)
	
	local noCooldownValue = char:FindFirstChild("Combat").NoCooldowns
	
	if not humanoid or not root then return end
	if othersModule.CheckForAttributes(char, nil, true, true, true, nil, true, true, true) then return end
	
	if noCooldownValue.Value == true then
		CooldownManager:resetCooldowns(char)
		task.wait(0.05)
	else
		if CooldownManager:IsOnCooldown(char, "OverdriveBarrage") then 
			print("OverdriveBarrage is on  cooldown!!!")
			return 
		end
	end

	char:SetAttribute("Attacking", true)
	char:SetAttribute("UsingAbility", true)


	if noCooldownValue.Value == false then
		CooldownManager:setCooldown(char, "OverdriveBarrage", movesetStats["OverdriveBarrage"].cooldown)
	else
		task.delay(0.05, function()
			CooldownManager:resetCooldowns(char)
		end)
	end

	local barrageAnim = replicated:WaitForChild("Animations"):WaitForChild("Characters"):WaitForChild("GentleMan"):WaitForChild("Moveset").Barrage
	local barrageTrack = humanoid:LoadAnimation(barrageAnim)
	barrageTrack:Play()

	local currentChar = char:GetAttribute("Class")
	local damage = movesetStats["OverdriveBarrage"].Damage
	local ragdollTime = movesetStats["OverdriveBarrage"].ragdollTime or 0
	local stunTime = movesetStats["OverdriveBarrage"].stunTime
	local knockback = movesetStats["OverdriveBarrage"].knockBack

	humanoid.WalkSpeed 	= 3
	humanoid.JumpHeight = 0

	barrageTrack:GetMarkerReachedSignal("Start"):Connect(function()
		local hitbox 				= Instance.new("Part")
		hitbox.Size 					= hitboxSize
		hitbox.Transparency 	= 0.7
		hitbox.CanCollide 		= false
		hitbox.Anchored 		= false
		hitbox.Massless 		= true
		hitbox.CFrame 			= root.CFrame * CFrame.new(0, 0, -4)
		hitbox.Parent 				= workspace
		local weld 					= Instance.new("Weld")
		weld.Part0 					= root
		weld.Part1 					= hitbox
		weld.C1 						= CFrame.new(0,0,5)
		weld.Parent 				= hitbox
		
		debris:AddItem(hitbox, hitboxTime)

		local hitOnce = {}
		hitbox.Touched:Connect(function(hit)
			local eChar = getModel(hit)
			local eHum = eChar and eChar:FindFirstChild("Humanoid")
			local eRoot = eChar and eChar:FindFirstChild("HumanoidRootPart")
			if eHum and eChar ~= char and not hitOnce[eChar] then
				
				
				hitOnce[eChar] = true
				hitModule.Abilities_Hitbox(char, eHum, currentChar, hitbox, hit, nil, damage, ragdollTime, 0.5, stunTime)
				if eChar:GetAttribute("IsBlocking") == true then return end
				valueEvent:FireClient(plr, damage)
				--[[if eHum.Health <= 0 then
					applyKillEnhancedKnockback(eRoot, root, 100, damage, eHum, 0.25)
				end]]
			end
		end)
	end)

	barrageTrack:GetMarkerReachedSignal("End"):Connect(function()
		char:SetAttribute("Attacking", true)
		combatModule.SetComboTo(char, 3)
		task.wait(0.15)
		char:SetAttribute("Attacking", false)
		char:SetAttribute("UsingAbility", false)
	end)

	barrageTrack.Stopped:Connect(function()
		if not char:GetAttribute("IsBlocking") then
			humanoid.WalkSpeed = starterPlr.CharacterWalkSpeed
			humanoid.JumpHeight = starterPlr.CharacterJumpHeight
		end
	end)
end

--// Overdrive //--
function module.Overdrive(char)
	-- (your original Overdrive code remains unchanged)
	if not char then return end
	local humanoid = char.Humanoid
	local root = char.HumanoidRootPart
	local plr = Players:GetPlayerFromCharacter(char)
	if not humanoid or not root then return end
	
	local noCooldownValue = char:FindFirstChild("Combat").NoCooldowns
	
	if othersModule.CheckForAttributes(char, nil, true, true, true, nil, true, true, true) then return end
	
	if noCooldownValue.Value == true then
		CooldownManager:resetCooldowns(char)
		task.wait(0.05)
	else
		if CooldownManager:IsOnCooldown(char, "Overdrive") then 
			print("Overdrive is on  cooldown!!!")
			return 
		end
	end

	char:SetAttribute("Attacking", true)
	char:SetAttribute("UsingAbility", true)


	if noCooldownValue.Value == false then
		CooldownManager:setCooldown(char, "Overdrive", movesetStats["Overdrive"].cooldown)
	else
		task.delay(0.05, function()
			CooldownManager:resetCooldowns(char)
		end)
	end


	local anim = replicated:WaitForChild("Animations"):WaitForChild("Characters"):WaitForChild("GentleMan"):WaitForChild("Moveset").Overdrive
	local animTrack = humanoid:LoadAnimation(anim)
	animTrack:Play()

	local currentChar = char:GetAttribute("Class")
	local damage = movesetStats["Overdrive"].Damage
	local ragdollTime = movesetStats["Overdrive"].ragdollTime
	local stunTime = movesetStats["Overdrive"].stunTime
	local knockback = movesetStats["Overdrive"].knockBack

	humanoid.WalkSpeed = 3
	humanoid.JumpHeight = 0

	animTrack:GetMarkerReachedSignal("Start"):Connect(function()
		local hitbox = Instance.new("Part")
		hitbox.Size = hitboxSize
		hitbox.Transparency = 0.7
		hitbox.CanCollide = false
		hitbox.Anchored = false
		hitbox.Massless = true
		hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -4)
		hitbox.Parent = workspace
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = hitbox
		weld.C1 = CFrame.new(0,0,5)
		weld.Parent = hitbox
		debris:AddItem(hitbox, hitboxTime)

		local hitOnce = {}
		hitbox.Touched:Connect(function(hit)
			local eChar = getModel(hit)
			local eHum = eChar and eChar:FindFirstChild("Humanoid")
			local eRoot = eChar and eChar:FindFirstChild("HumanoidRootPart")
			if eHum and eChar ~= char and not hitOnce[eChar] then
				
				
				hitOnce[eChar] = true
				hitModule.Abilities_Hitbox(char, eHum, currentChar, hitbox, hit, nil, damage, ragdollTime, knockback, stunTime)
				if eChar:GetAttribute("IsBlocking") == true then return end
				valueEvent:FireClient(plr, damage)
				--applyKillEnhancedKnockback(eRoot, root, knockback, damage, eHum, 0.15)
				if (eHum.Health - damage) <= 0 then
					othersModule.Ragdoll(eChar, ragdollTime or 2.5)
				end
			end
		end)
	end)

	animTrack:GetMarkerReachedSignal("End"):Connect(function()
		char:SetAttribute("Attacking", true)
		task.wait(0.15)
		char:SetAttribute("Attacking", false)
		char:SetAttribute("UsingAbility", false)
	end)

	animTrack.Stopped:Connect(function()
		if not char:GetAttribute("IsBlocking") then
			humanoid.WalkSpeed = starterPlr.CharacterWalkSpeed
			humanoid.JumpHeight = starterPlr.CharacterJumpHeight
		end
	end)
end

--// Pluck //--
function module.Pluck(char)
	if not char then return end
	local humanoid = char.Humanoid
	local root = char.HumanoidRootPart
	local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
	local plr = Players:GetPlayerFromCharacter(char)
	
	local noCooldownValue = char:FindFirstChild("Combat").NoCooldowns
	
	if not humanoid or not root or not rightArm then return end
	if othersModule.CheckForAttributes(char, nil, true, true, true, nil, true, true, true) then return end
	
	if noCooldownValue.Value == true then
		CooldownManager:resetCooldowns(char)
		task.wait(0.05)
	else
		if CooldownManager:IsOnCooldown(char, "Pluck") then 
			print("Pluck is on  cooldown!!!")
			return 
		end
	end

	char:SetAttribute("Attacking", true)
	char:SetAttribute("UsingAbility", true)


	if noCooldownValue.Value == false then
		CooldownManager:setCooldown(char, "Pluck", movesetStats["Pluck"].cooldown)
	else
		task.delay(0.05, function()
			CooldownManager:resetCooldowns(char)
		end)
	end

	local anim = replicated:WaitForChild("Animations"):WaitForChild("Characters"):WaitForChild("GentleMan"):WaitForChild("Moveset").Pluck
	local animTrack = humanoid:LoadAnimation(anim)
	animTrack:Play()

	local hitAnim = replicated:WaitForChild("Animations"):WaitForChild("Characters"):WaitForChild("GentleMan"):WaitForChild("Moveset").PluckHit

	local currentChar = char:GetAttribute("Class")
	local damage = movesetStats["Pluck"].Damage
	local ragdollTime = movesetStats["Pluck"].ragdollTime
	local stunTime = movesetStats["Pluck"].stunTime
	local knockback = movesetStats["Pluck"].knockBack

	humanoid.WalkSpeed = 0
	humanoid.JumpHeight = 0

	local pluckSword = replicated.Assets["Pluck Sword"]:Clone()
	pluckSword.Parent = char
	pluckSword.CFrame = root.CFrame
	debris:AddItem(pluckSword, 3)

	local swordWeld = sss.CombatServer.PluckSword6D.Sword6D
	Welds[plr] = swordWeld:Clone()
	Welds[plr].Part0 = rightArm
	Welds[plr].Part1 = pluckSword
	Welds[plr].Parent = rightArm

	local charWeld = nil

	-- First HitBox
	animTrack:GetMarkerReachedSignal("Start1"):Connect(function()
		local hitbox = Instance.new("Part")
		hitbox.Size = hitboxSize
		hitbox.Transparency = 0.7
		hitbox.CanCollide = false
		hitbox.Anchored = false
		hitbox.Massless = true
		hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -4)
		hitbox.Parent = workspace
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = hitbox
		weld.C1 = CFrame.new(0, 0, 5)
		weld.Parent = hitbox
		debris:AddItem(hitbox, hitboxTime)

		local hitOnce = {}
		hitbox.Touched:Connect(function(hit)
			local eChar = getModel(hit)
			if not eChar then return end
			local eHum = eChar:FindFirstChild("Humanoid")
			local eRoot = eChar:FindFirstChild("HumanoidRootPart")
			if eHum and eChar ~= char and not hitOnce[eChar] then
				
				
				
				
				hitOnce[eChar] = true
				print("Hit registered on:", eChar.Name)
				print("CheckForStatus result:", othersModule.CheckForStatus(eChar, char, hit.CFrame, true))
				hitModule.Abilities_Hitbox(char, eHum, currentChar, hitbox, hit, nil, damage, ragdollTime, knockback, stunTime)
				if eChar:GetAttribute("IsBlocking") == true then return end
				valueEvent:FireClient(plr, damage)
				if eHum.Health <= 0 then return end
				charWeld = Instance.new("Weld")
				charWeld.Part0 = root
				charWeld.Part1 = eRoot
				charWeld.C1 = CFrame.new(0, 0, 4)
				charWeld.Parent = eRoot
			end
		end)
	end)

	-- Second HitBox (finisher)
	animTrack:GetMarkerReachedSignal("Start2"):Connect(function()
		if charWeld then charWeld:Destroy() charWeld = nil end

		local hitbox = Instance.new("Part")
		hitbox.Size = hitboxSize
		hitbox.Transparency = 0.7
		hitbox.CanCollide = false
		hitbox.Anchored = false
		hitbox.Massless = true
		hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -4)
		hitbox.Parent = workspace
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = hitbox
		weld.C1 = CFrame.new(0, 0, 5)
		weld.Parent = hitbox
		debris:AddItem(hitbox, hitboxTime)

		local hitOnce = {}
		hitbox.Touched:Connect(function(hit)
			local eChar = getModel(hit)
			if not eChar then return end
			local eHum = eChar:FindFirstChild("Humanoid")
			local eRoot = eChar:FindFirstChild("HumanoidRootPart")
			if eHum and eChar ~= char and not hitOnce[eChar] then
				
				
				hitOnce[eChar] = true
				hitModule.Abilities_Hitbox(char, eHum, currentChar, hitbox, hit, nil, damage, ragdollTime, knockback, stunTime)
				if eChar:GetAttribute("IsBlocking") == true then return end
				valueEvent:FireClient(plr, damage)
				--applyKillEnhancedKnockback(eRoot, root, knockback, damage, eHum, 0.2)
				othersModule.Ragdoll(eChar, ragdollTime or 3)
			end
		end)
	end)

	animTrack:GetMarkerReachedSignal("End"):Connect(function()
		if charWeld then charWeld:Destroy() charWeld = nil end
		char:SetAttribute("Attacking", true)
		task.wait(0.15)
		char:SetAttribute("Attacking", false)
		char:SetAttribute("UsingAbility", false)
	end)

	animTrack.Stopped:Connect(function()
		if charWeld then charWeld:Destroy() charWeld = nil end
		if not char:GetAttribute("IsBlocking") then
			humanoid.WalkSpeed = starterPlr.CharacterWalkSpeed
			humanoid.JumpHeight = starterPlr.CharacterJumpHeight
		end
	end)
end

--// Ultimate 
function module.Ultimate(char)	
	if not char then return end
	local plr = Players:GetPlayerFromCharacter(char)
	local humanoid = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
	if not plr or not humanoid or not root or not rightArm then return end
	
	CooldownManager:resetCooldowns(char)

	combatModule.stopAnims(humanoid)
	local ultAnim = replicated:WaitForChild("Animations"):WaitForChild("Characters"):WaitForChild("GentleMan"):WaitForChild("Moveset"):WaitForChild("Ultimate")
	local ultTrack = humanoid:LoadAnimation(ultAnim)
	ultTrack:Play()

	-- Gentlemen VFX Ultimate
	local vfxTemplate = replicated:WaitForChild("VFXForAnim"):WaitForChild("VFX"):WaitForChild("GentleAuraUlt")
	local addedAttachments = {}
	for _, vfxPart in pairs(vfxTemplate:GetChildren()) do
		if vfxPart:IsA("BasePart") then
			local playerPart = char:FindFirstChild(vfxPart.Name)
			if playerPart then
				for _, emitter in pairs(vfxPart:GetDescendants()) do
					if emitter:IsA("ParticleEmitter") then
						local attachment = Instance.new("Attachment")
						attachment.Parent = playerPart
						local emitterClone = emitter:Clone()
						emitterClone.Parent = attachment
						emitterClone:Emit(emitterClone.Rate)
						table.insert(addedAttachments, attachment)
					end
				end
			end
		end
	end

	StunHandler.Stun(humanoid, 2, 0, 0)

	char:SetAttribute("UltMode", true)
	char:SetAttribute("Test", true)
	char:SetAttribute("Iframes", true)

	valueEvent:FireClient(plr, "UltStart")
	valueEvent:FireClient(plr, 0)


	-- Equip Pluck Sword 
	
	local swordTemplate = replicated:FindFirstChild("Assets") and replicated.Assets:FindFirstChild("Pluck Sword")
	local weldTemplate = sss:FindFirstChild("CombatServer")
		and sss.CombatServer:FindFirstChild("PluckSword6D")
		and sss.CombatServer.PluckSword6D:FindFirstChild("Sword6D")
	local swordClone, swordWeld
	if swordTemplate and weldTemplate then
		swordClone = swordTemplate:Clone()
		swordClone.Parent = char
		swordClone.CFrame = rightArm.CFrame
		swordWeld = weldTemplate:Clone()
		swordWeld.Part0 = rightArm
		swordWeld.Part1 = swordClone
		swordWeld.Parent = rightArm
		Welds[plr] = swordWeld
	else
		warn("Could not equip Pluck Sword in Ultimate - missing template or weld")
	end

	ultTrack:GetMarkerReachedSignal("End"):Connect(function()
		char:SetAttribute("Iframes", false)
		char:SetAttribute("Test", false)
		humanoid.WalkSpeed = 16
	end)

	task.delay(UltimateDuration, function()
		char:SetAttribute("UltMode", false)
		humanoid.WalkSpeed = 16
		humanoid.JumpHeight = starterPlr.CharacterJumpHeight
		valueEvent:FireClient(plr, "UltEnd")

		for _, attachment in pairs(addedAttachments) do
			if attachment and attachment.Parent then
				attachment:Destroy()
			end
		end

	
		if Welds[plr] then
			Welds[plr]:Destroy()
			Welds[plr] = nil
		end
		if swordClone and swordClone.Parent then
			swordClone:Destroy()
		end
	end)
end


-- First Ultimate Gentlemen Move 

function module.Sendo(char)
	if not char then return end

	local humanoid = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local plr = Players:GetPlayerFromCharacter(char)
	if not humanoid or not root then return end
	
	local noCooldownValue = char:FindFirstChild("Combat").NoCooldowns

	if othersModule.CheckForAttributes(char, nil, true, true, true, nil, true, true, true) then return end

	if noCooldownValue.Value == true then
		CooldownManager:resetCooldowns(char)
		task.wait(0.05)
	else
		if CooldownManager:IsOnCooldown(char, "Sendo") then 
			print("Sendo is on  cooldown!!!")
			return 
		end
	end

	char:SetAttribute("Attacking", true)
	char:SetAttribute("UsingAbility", true)


	if noCooldownValue.Value == false then
		CooldownManager:setCooldown(char, "Sendo", ultMoveStats["Sendo"].cooldown)
	else
		task.delay(0.05, function()
			CooldownManager:resetCooldowns(char)
		end)
	end

	local currentChar = char:GetAttribute("Class")
	local damage = ultMoveStats["Sendo"].Damage
	local ragdollTime = ultMoveStats["Sendo"].ragdollTime
	local stunTime = ultMoveStats["Sendo"].stunTime
	local knockback = ultMoveStats["Sendo"].knockBack

	humanoid.WalkSpeed = 3
	humanoid.JumpHeight = 0

	local sendoAnim = replicated.Animations.Characters.GentleMan.Moveset.Sendo
	local sendoTrack = humanoid:LoadAnimation(sendoAnim)

	sendoTrack:GetMarkerReachedSignal("Start"):Connect(function()
		local hitbox = Instance.new("Part")
		hitbox.Size = hitboxSize
		hitbox.Transparency = 0.7
		hitbox.CanCollide = false
		hitbox.Anchored = false
		hitbox.Massless = true
		hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -4)
		hitbox.Parent = workspace

		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = hitbox
		weld.C1 = CFrame.new(0, 0, 5)
		weld.Parent = hitbox

		debris:AddItem(hitbox, hitboxTime)

		local hitOnce = {}

		hitbox.Touched:Connect(function(hit)
			local eChar = getModel(hit)
			local eHum = eChar and eChar:FindFirstChild("Humanoid")
			local eRoot = eChar and eChar:FindFirstChild("HumanoidRootPart")

			if eHum and eChar ~= char and not hitOnce[eChar] then
				hitOnce[eChar] = true

				
				
				
				hitModule.Abilities_Hitbox(char, eHum, currentChar, hitbox, hit, nil, damage, ragdollTime, 0, stunTime)
				
				if eChar:GetAttribute("IsBlocking") == true then return end

				valueEvent:FireClient(plr, damage)
				othersModule.Ragdoll(eChar, ragdollTime)

			
				task.delay(0.1, function()
					if eChar and eRoot and eHum.Health > 0 then
						local direction = (eRoot.Position - root.Position).Unit
						for _, part in pairs(eChar:GetDescendants()) do
							if part:IsA("BasePart") then
								local bv = Instance.new("BodyVelocity")
								bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
								bv.Velocity = direction * knockback
								bv.Parent = part
								debris:AddItem(bv, 0.15)
							end
						end
					end
				end)
			end
		end)
	end)

	sendoTrack:GetMarkerReachedSignal("End"):Connect(function()
		char:SetAttribute("Attacking", true)
		combatModule.SetComboTo(char, 1)
		task.wait(0.15)
		char:SetAttribute("Attacking", false)
		char:SetAttribute("UsingAbility", false)
	end)

	sendoTrack.Stopped:Connect(function()
		if not char:GetAttribute("IsBlocking") then
			humanoid.WalkSpeed = starterPlr.CharacterWalkSpeed
			humanoid.JumpHeight = starterPlr.CharacterJumpHeight
		end
	end)

	sendoTrack:Play()
end


--Second Ultimate Gentlemen Move 

--[[ function module.Scarlet(char)
	if not char then return end
	local humanoid = char.Humanoid
	local root = char.HumanoidRootPart
	local plr = Players:GetPlayerFromCharacter(char)
	if not humanoid or not root then return end
	if othersModule.CheckForAttributes(char, nil, true, true, true, nil, true, true) then return end
	if not char:GetAttribute("UltMode") then return end
	if CooldownManager:IsOnCooldown(char, "Scarlet") then return end

	char:SetAttribute("Attacking", true)
	char:SetAttribute("UsingAbility", true)
	CooldownManager:setCooldown(char, "Scarlet", ultMoveStats["Scarlet"].cooldown) -- im eating lunch rn

	local currentChar = char:GetAttribute("Class")
	local damage = ultMoveStats["Scarlet"].Damage
	local stunTime = ultMoveStats["Scarlet"].stunTime
	local knockback = ultMoveStats["Scarlet"].knockBack

	humanoid.WalkSpeed = 3
	humanoid.JumpHeight = 0

	local sunlightAnim = replicated:WaitForChild("Animations"):WaitForChild("Characters"):WaitForChild("GentleMan"):WaitForChild("Moveset").Scarlet
	local sunlightTrack = humanoid:LoadAnimation(sunlightAnim)
	sunlightTrack:Play()

	sunlightTrack:GetMarkerReachedSignal("Start"):Connect(function()
		local hitbox = Instance.new("Part")
		hitbox.Size = hitboxSize
		hitbox.Transparency = 0.7
		hitbox.CanCollide = false
		hitbox.Anchored = false
		hitbox.Massless = true
		hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -4)
		hitbox.Parent = workspace
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = hitbox
		weld.C1 = CFrame.new(0, 0, 5)
		weld.Parent = hitbox
		debris:AddItem(hitbox, hitboxTime)

		local hitOnce = {}
		hitbox.Touched:Connect(function(hit)
			local eChar = getModel(hit)
			local eHum = eChar and eChar:FindFirstChild("Humanoid")
			if eHum and eChar ~= char and not hitOnce[eChar] then
				hitOnce[eChar] = true
				hitModule.Abilities_Hitbox(char, eHum, currentChar, hitbox, hit, nil, damage, 0, knockback, stunTime)
				if eChar:GetAttribute("IsBlocking") == true then return end
				valueEvent:FireClient(plr, damage)
			end
		end)
	end)

	sunlightTrack:GetMarkerReachedSignal("End"):Connect(function()
		char:SetAttribute("Attacking", true)
		combatModule.SetComboTo(char, 1)
		task.wait(0.15)
		char:SetAttribute("Attacking", false)
		char:SetAttribute("UsingAbility", false)
	end)

	sunlightTrack.Stopped:Connect(function()
		if not char:GetAttribute("IsBlocking") then
			humanoid.WalkSpeed = starterPlr.CharacterWalkSpeed
			humanoid.JumpHeight = starterPlr.CharacterJumpHeight
		end
	end)
end ]] 

return module
