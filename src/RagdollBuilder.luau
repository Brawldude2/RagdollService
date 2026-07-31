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
		local joint = InstanceQuery:Get(character, path) :: Motor6D | AnimationConstraint
		if not joint then
			Util.StudioWarn(`Missing the joint with path: {table.concat(path, ".")}`)
			return false
		end
		if joint:IsA("Motor6D") then
			if not (joint.Part0 and joint.Part1) then
				Util.StudioWarn(`Motor6D joint is missing Part0 or Part1: {table.concat(path, ".")}`)
				return false
			end
		elseif joint:IsA("AnimationConstraint") then
			if not (joint.Attachment0 and joint.Attachment1) then
				Util.StudioWarn(`AnimationConstraint joint is missing Attachment0 or Attachment1: {table.concat(path, ".")}`)
				return false
			end
		else
			Util.StudioWarn(`Joint must be a Motor6D or an AnimationConstraint: {table.concat(path, ".")}`)
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
	
	local animation_constraints: {AnimationConstraint} = character:QueryDescendants("AnimationConstraint") :: any
	for _, animation_constraint in animation_constraints do
		if animation_constraint.Name:lower():find("root", nil, true) then continue end
		local joint_attachment0 = animation_constraint.Attachment0
		local joint_attachment1 = animation_constraint.Attachment1
		if not joint_attachment0 or not joint_attachment1 then warn("OH NO") continue end
		
		local part0 = joint_attachment0.Parent
		local part1 = joint_attachment1.Parent
		if not part0 or not part1 or not part0:IsA("BasePart") or not part1:IsA("BasePart") then continue end
		
		local attachment0 = joint_attachment0:Clone()
		local attachment1 = joint_attachment1:Clone()
		
		attachment0.Parent = joint_attachment0.Parent
		attachment1.Parent = joint_attachment1.Parent

		--table.insert(info.NoCollisionConstraints, Util.NewNoCollision(part0, part1))
		table.insert(info.Attachments, attachment0)
		table.insert(info.Attachments, attachment1)
		
		info.Joints[animation_constraint.Name] = animation_constraint
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
		local joint = InstanceQuery:Get(character, path) :: Motor6D | AnimationConstraint
		
		local attachment0: Attachment
		local attachment1: Attachment
		
		if joint:IsA("Motor6D") then
			attachment0 = Util.NewAttachment(joint.C0, joint.Part0 :: BasePart)
			attachment1 = Util.NewAttachment(joint.C1, joint.Part1 :: BasePart)
		elseif joint:IsA("AnimationConstraint") then
			local joint_attachment0 = joint.Attachment0 :: Attachment
			local joint_attachment1 = joint.Attachment1 :: Attachment
			
			attachment0 = joint_attachment0:Clone()
			attachment1 = joint_attachment1:Clone()
			
			attachment0.Parent = joint_attachment0.Parent
			attachment1.Parent = joint_attachment1.Parent
		else
			continue
		end

		table.insert(info.Attachments, attachment0)
		table.insert(info.Attachments, attachment1)
		
		if config.Sockets[name] then
			info.Sockets[name] = Util.NewSocket(attachment0, attachment1, config.Sockets[name])
		end
		
		info.Joints[name] = joint
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