--!strict

local RagdollBuilder = {}

local Util = require(script.Parent.Util)
local Types = require(script.Parent.Types)
local RigConfigs = require(script.Parent.RigConfigs)
local InstanceQuery = require(script.Parent.InstanceQuery)

type RigConfig = Types.RigConfig
type CharacterRagdollInfo = Types.CharacterRagdollInfo

local function CreateInfo(character: Model, rig_type: string): CharacterRagdollInfo
	return {
		Ragdolled = false,
		Character = character,
		RigType = rig_type,
		Limbs = {},
		Joints = {},
		Attachments = {},
		Sockets = {},
		NoCollisionConstraints = {},
		Connections = {},
	}
end

function RagdollBuilder.Validate(character: Model, rig_type: string): boolean
	if rig_type == "Generic" then return true end
	local config = RigConfigs[rig_type]
	if not config then
		warn(`[RagdollService]: Unknown rig type: {rig_type}`)	
		return false
	end
	for name, path in config.Limbs do
		local limb = InstanceQuery:Get(character, path) :: BasePart?
		if not limb then
			Util.StudioWarn(`Missing the limb with path: {table.concat(path, ".")}`)
			return false
		end
		if not limb:IsA("BasePart") then
			Util.StudioWarn(`Limb must be a BasePart: {table.concat(path, ".")}`)
			return false
		end
	end
	for name, path in config.Joints do
		local motor6d = InstanceQuery:Get(character, path) :: Motor6D?
		if not motor6d then
			Util.StudioWarn(`Missing the joint with path: {table.concat(path, ".")}`)
			return false
		end
		if not motor6d:IsA("Motor6D") then
			Util.StudioWarn(`Joint must be a Motor6D: {table.concat(path, ".")}`)
			return false
		end
		if not (motor6d.Part0 and motor6d.Part1) then
			Util.StudioWarn(`Joint is missing Part0 or Part1: {table.concat(path, ".")}`)
			return false
		end
		local socket_limits = config.Sockets[name]
		if not socket_limits then
			Util.StudioWarn(`No socket for following joint: {table.concat(path, ".")}`)
			return false
		end
	end
	
	for _, no_collision_config in config.NoCollisionConstraints do
		local limb0 = config.Limbs[no_collision_config[1]]
		local limb1 = config.Limbs[no_collision_config[2]]
		if not (limb0 and limb1) then
			Util.StudioWarn(`Unable to find limb0 or limb1 for NoCollisionConstraint.`)
			return false
		end
	end
	
	return true
end

local function BuildGeneric(info: CharacterRagdollInfo)
	local character = info.Character
	local root_part = character.PrimaryPart
	
	local humanoid = character:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		root_part = humanoid.RootPart
		humanoid.BreakJointsOnDeath = false
		humanoid.RequiresNeck = false
		info.Humanoid = humanoid
	end
	
	info.Animator = character:FindFirstChildWhichIsA("Animator", true)
	info.RootPart = root_part

	local limb_cache = {} :: {[BasePart]: boolean}
	local motor6ds: {Motor6D} = character:QueryDescendants("Motor6D") :: any
	for _, motor6d in motor6ds do
		if motor6d.Name:lower():find("root", nil, true) then continue end
		local part0 = motor6d.Part0
		local part1 = motor6d.Part1
		if not part0 or not part1 then continue end

		Util.RegisterRootNoCollision(limb_cache, part0, info)
		Util.RegisterRootNoCollision(limb_cache, part1, info)

		local attachment0 = Util.NewAttachment(motor6d.C0, part0)
		local attachment1 = Util.NewAttachment(motor6d.C1, part1)

		table.insert(info.NoCollisionConstraints, Util.NewNoCollision(part0, part1))
		table.insert(info.Attachments, attachment0)
		table.insert(info.Attachments, attachment1)

		info.Joints[motor6d.Name] = motor6d
		info.Sockets[motor6d.Name] = Util.NewSocket(attachment0, attachment1)
	end
end

local function BuildFromConfig(info: CharacterRagdollInfo)
	local character = info.Character
	local config = RigConfigs[info.RigType] :: RigConfig
	
	info.RootPart = Util.QueryInstance(character, config.RootPart) :: BasePart?
	info.Animator = Util.QueryInstance(character, config.Animator) :: Animator?

	local humanoid = Util.QueryInstance(character, config.Humanoid) :: Humanoid?
	if humanoid then
		humanoid.BreakJointsOnDeath = false
		humanoid.RequiresNeck = false
		info.Humanoid = humanoid
	end

	for name, path in config.Limbs do
		info.Limbs[name] = InstanceQuery:Get(character, path) :: BasePart
	end

	for name, path in config.Joints do
		local motor6d = InstanceQuery:Get(character, path) :: Motor6D

		local attachment0 = Util.NewAttachment(motor6d.C0, motor6d.Part0 :: BasePart)
		local attachment1 = Util.NewAttachment(motor6d.C1, motor6d.Part1 :: BasePart)

		table.insert(info.Attachments, attachment0)
		table.insert(info.Attachments, attachment1)

		info.Sockets[name] = Util.NewSocket(attachment0, attachment1, config.Sockets[name])
		info.Joints[name] = motor6d
	end

	for _, no_collision_config in config.NoCollisionConstraints do
		local limb0 = info.Limbs[no_collision_config[1]]
		local limb1 = info.Limbs[no_collision_config[2]]
		table.insert(info.NoCollisionConstraints, Util.NewNoCollision(limb0, limb1))
	end
end

function RagdollBuilder.Build(character: Model, rig_type: string): CharacterRagdollInfo
	local info = CreateInfo(character, rig_type)

	if rig_type == "Generic" then
		BuildGeneric(info)
	else
		BuildFromConfig(info)
	end

	return info
end

return RagdollBuilder