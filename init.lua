--!strict
--!optimize 2

local RagdollService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InstanceQuery = require(script.InstanceQuery)
local RigConfigs = require(script.RigConfigs)
local RigConfigType = require(script.RigConfigs.RigConfigType)

local IsStudio = RunService:IsStudio()
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

type CharacterRagdollInfo = {
	Ragdolled: boolean,
	RigType: string,
	Config: RigConfigType.RigConfig,
	Animator: Animator?,
	Humanoid: Humanoid?,
	RootPart: BasePart,
	Limbs: {[string]: BasePart},
	Joints: {[string]: Motor6D},
	Sockets: {[string]: BallSocketConstraint},
	Attachments: {Attachment},
	NoCollisionConstraints: {NoCollisionConstraint},
	Connections: {RBXScriptConnection},
}
local CharacterRagdollInfos = {} :: {[Model]: CharacterRagdollInfo}

local RagdollRemote: RemoteEvent

local function StudioWarn(msg: string)
	if not IsStudio then return end
	warn(`[RagdollService]: {msg}`)
end

local function SafeChangeState(humanoid: Humanoid, state: Enum.HumanoidStateType)
	if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
		humanoid:ChangeState(state)
	end
end

if IsServer then
	RagdollRemote = Instance.new("RemoteEvent")
	RagdollRemote.Name = "RagdollRemote"
	RagdollRemote.Parent = script
else
	RagdollRemote = script:WaitForChild("RagdollRemote") :: any
	RagdollRemote.OnClientEvent:Connect(function(enabled: boolean, ragdoll_type: string)
		local player = Players.LocalPlayer :: Player
		local character = player.Character
		if not character or not character:IsDescendantOf(workspace) then return end
		
		local config = RigConfigs[ragdoll_type]
		local root_part = InstanceQuery:Get(character, config.RootPart) :: BasePart
		if not root_part then return end
		
		local humanoid: Humanoid?
		if config.Humanoid then
			humanoid = InstanceQuery:Get(character, config.Humanoid)
		end
		
		local animator: Animator?
		if config.Animator then
			animator = InstanceQuery:Get(character, config.Animator)
		end

		if humanoid then
			if enabled then
				if config.HasDefaultAnimate == true then
					
					-- Transition Animate script to "PlatformStanding" pose to fix camera swing issue
					SafeChangeState(humanoid, Enum.HumanoidStateType.PlatformStanding)
					task.wait()
					
					-- Check if ragdoll activated and deactivated on the same frame
					if humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding then
						SafeChangeState(humanoid, Enum.HumanoidStateType.Physics)
					end
					
					-- Fix engine bug where exiting "PlatformStanding" state toggles off platform stand
					task.delay(0, function() humanoid.PlatformStand = true end)
				else
					SafeChangeState(humanoid, Enum.HumanoidStateType.Physics)
				end
				
				-- Give the character bit of angular momentum to break the balance
				root_part:ApplyAngularImpulse(root_part.CFrame.RightVector * 50)
			else
				SafeChangeState(humanoid, Enum.HumanoidStateType.GettingUp)
			end
		end
		
		if enabled and animator then
			for _, track in animator:GetPlayingAnimationTracks() do
				if track.Priority ~= Enum.AnimationPriority.Core then
					-- Stop tracks that are not used by the Animate script
					track:Stop(0)
				else
					-- Pause core animations to fix camera swing before animate stepAnimate
					track:AdjustSpeed(0)
				end
			end
		end
	end)
end

local function IsModel(value: any)
	return typeof(value) == "Instance" and value:IsA("Model")
end

local function IsRagdolled(character: Model): boolean
	local info = CharacterRagdollInfos[character]
	if not info then return false end
	return info.Ragdolled
end

local function IsPlayerRagdolled(player: Player): boolean
	if not player.Character then return false end
	return IsRagdolled(player.Character)
end

local function GetRigType(character: Model): string
	local rig_type = character:GetAttribute("RigType")
	if rig_type then return rig_type end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			return "R6"
		elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
			return "R15"
		end
	end
	
	error(`[RagdollService]: Unkown rig type for character: {character}`)
end

local function DestroyRagdoll(character: Model)
	local info = CharacterRagdollInfos[character]
	if not info then return end
	
	for _, no_collision in info.NoCollisionConstraints do
		no_collision:Destroy()
	end
	for name, socket in info.Sockets do
		socket:Destroy()
	end
	for name, attachment in info.Attachments do
		attachment:Destroy()
	end
	for _, c in info.Connections do
		c:Disconnect()
	end
	CharacterRagdollInfos[character] = nil
end

local function SetupRagdoll(character: Model, rig_type: string?): boolean
	if not character:IsDescendantOf(workspace) then return false end
	local info = {} :: CharacterRagdollInfo
	info.Ragdolled = false
	info.Limbs = {}
	info.Joints = {}
	info.Attachments = {}
	info.Sockets = {}
	info.NoCollisionConstraints = {}
	info.Connections = {}
	
	local player = Players:GetPlayerFromCharacter(character)
	
	local rig_type = rig_type or GetRigType(character)
	local config = RigConfigs[rig_type]
	if not config then
		error(`[RagdollService]: Unknown rig type: {rig_type}`)	
	end
	
	local root_part = InstanceQuery:Get(character, config.RootPart) :: BasePart
	if not root_part then
		error(`[RagdollService]: No root part found with path: {table.concat(config.RootPart, ".")}`)
	end
	info.RootPart = root_part
	
	if config.Humanoid then
		local humanoid: Humanoid? = InstanceQuery:Get(character, config.Humanoid)
		if not humanoid then
			StudioWarn(`No humanoid found with path: {table.concat(config.Humanoid, ".")}`)
			return false
		end
		
		if config.BreakJointsOnDeath ~= nil then
			humanoid.BreakJointsOnDeath = config.BreakJointsOnDeath
		end
		
		info.Humanoid = humanoid
	end
	
	if config.Animator then
		local animator: Animator? = InstanceQuery:Get(character, config.Animator)
		info.Animator = animator
	end
	
	for name, path in config.Limbs do
		local limb = InstanceQuery:Get(character, path) :: BasePart?
		if not limb then
			StudioWarn(`Missing the limb with path: {table.concat(path, ".")}`)
			continue
		end
		if not limb:IsA("BasePart") then
			StudioWarn(`Limb must be a BasePart: {table.concat(path, ".")}`)
			continue
		end

		info.Limbs[name] = limb
	end
	
	for name, path in config.Joints do
		local motor6d = InstanceQuery:Get(character, path) :: Motor6D?
		if not motor6d then
			StudioWarn(`Missing the joint with path: {table.concat(path, ".")}`)
			continue
		end
		if not motor6d:IsA("Motor6D") then
			StudioWarn(`Joint must be a Motor6D: {table.concat(path, ".")}`)
			continue
		end
		if not (motor6d.Part0 and motor6d.Part1) then
			StudioWarn(`Joint is missing Part0 or Part1: {table.concat(path, ".")}`)
			continue
		end

		local socket_limits = config.Sockets[name]
		if not socket_limits then
			StudioWarn(`No socket for following joint: {table.concat(path, ".")}`)
			continue
		end

		local attachment0 = Instance.new("Attachment")
		attachment0.CFrame = motor6d.C0
		attachment0.Parent = motor6d.Part0

		local attachment1 = Instance.new("Attachment")
		attachment1.CFrame = motor6d.C1
		attachment1.Parent = motor6d.Part1

		local socket = Instance.new("BallSocketConstraint")
		socket.Attachment0 = attachment0
		socket.Attachment1 = attachment1
		socket.LimitsEnabled = true
		socket.TwistLimitsEnabled = true

		if socket_limits.MaxFrictionTorque then
			socket.MaxFrictionTorque = socket_limits.MaxFrictionTorque
		end
		socket.UpperAngle = socket_limits.UpperAngle
		socket.TwistLowerAngle = socket_limits.TwistLowerAngle
		socket.TwistUpperAngle = socket_limits.TwistUpperAngle
		socket.Parent = attachment0.Parent
		
		table.insert(info.Attachments, attachment0)
		table.insert(info.Attachments, attachment1)

		info.Sockets[name] = socket
		info.Joints[name] = motor6d
	end
	
	for _, no_collision_config in config.NoCollisionConstraints do
		local limb0 = info.Limbs[no_collision_config[1]]
		local limb1 = info.Limbs[no_collision_config[2]]
		if not (limb0 and limb1) then continue end

		local no_collision = Instance.new("NoCollisionConstraint")
		no_collision.Part0 = limb0
		no_collision.Part1 = limb1
		no_collision.Parent = limb1
		
		no_collision.Enabled = false

		table.insert(info.NoCollisionConstraints, no_collision)
	end
	
	table.insert(info.Connections, character.AncestryChanged:Once(function(child, parent)
		if parent == nil then
			DestroyRagdoll(character)
		end
	end))
	
	table.insert(info.Connections, character.Destroying:Once(function()
		DestroyRagdoll(character)
	end))
	
	info.RigType = rig_type
	info.Config = config
	
	CharacterRagdollInfos[character] = info
	
	return true
end

local function ActivateRagdoll(character: Model): boolean
	local info = CharacterRagdollInfos[character]
	if not info or info.Ragdolled then return false end
	info.Ragdolled = true
	
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		RagdollRemote:FireClient(player, true, info.RigType)
	end
	
	local previous_owner: any
	if IsServer then
		previous_owner = info.RootPart:GetNetworkOwner()
		info.RootPart:SetNetworkOwner(nil)
	end
	
	if info.Humanoid then
		local humanoid = info.Humanoid
		-- Prevent death sound from playing twice
		-- If Humanoid is dead it forces itself back to Dead state whenever ChangeState is called
		-- Order dependent: Physics state must be entered before PlatformStand to prevent engine from going into PlatformStanding state
		SafeChangeState(humanoid, Enum.HumanoidStateType.Physics)
		humanoid.RequiresNeck = false
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
	end

	if info.Animator then
		local animator = info.Animator
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end

	for _, motor6d in info.Joints do
		motor6d.Enabled = false
	end

	for _, no_collision in info.NoCollisionConstraints do
		no_collision.Enabled = true
	end
	
	if IsServer then
		info.RootPart:SetNetworkOwner(previous_owner)
	end
	
	-- Break the ragdoll balance on server if owned by server on client if local rig
	if IsClient or info.RootPart:GetNetworkOwner() == nil then
		info.RootPart:ApplyAngularImpulse(info.RootPart.CFrame.RightVector * 50)
	end
	
	return true
end

local function DeactivateRagdoll(character: Model): boolean
	assert(IsModel(character), "Character is not model.")
	
	local info = CharacterRagdollInfos[character]
	if not info or not info.Ragdolled then return false end
	info.Ragdolled = false

	if info.Humanoid then
		local humanoid = info.Humanoid
		humanoid.RequiresNeck = true
		humanoid.AutoRotate = true
		humanoid.PlatformStand = false
		
		SafeChangeState(humanoid, Enum.HumanoidStateType.GettingUp)
	end

	local player = Players:GetPlayerFromCharacter(character)
	if player then
		RagdollRemote:FireClient(player, false, info.RigType)
	end
	
	for _, motor6d in info.Joints do
		motor6d.Enabled = true
	end
	
	for _, no_collision in info.NoCollisionConstraints do
		no_collision.Enabled = false
	end
	
	return true
end

local function Ragdoll(character: Model, rig_type: string?): boolean
	assert(IsModel(character), "Character is not model.")
	
	local info = CharacterRagdollInfos[character]
	if not info then
		local success = SetupRagdoll(character, rig_type)
		if not success then return false end
	end
	
	ActivateRagdoll(character)
	
	return true
end

local function Unragdoll(character: Model): boolean
	assert(IsModel(character), "Character is not model.")

	local info = CharacterRagdollInfos[character]
	if not info then return false end
	
	DeactivateRagdoll(character)
	DestroyRagdoll(character)

	return true
end

RagdollService.IsPlayerRagdolled = IsPlayerRagdolled
RagdollService.IsRagdolled = IsRagdolled
RagdollService.SetupRagdoll = SetupRagdoll
RagdollService.DestroyRagdoll = DestroyRagdoll
RagdollService.ActivateRagdoll = ActivateRagdoll
RagdollService.DeactivateRagdoll = DeactivateRagdoll
RagdollService.Ragdoll = Ragdoll
RagdollService.Unragdoll = Unragdoll

return RagdollService