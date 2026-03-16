--!strict

local Util = {}

local Types = require(script.Parent.Types)
local InstanceQuery = require(script.Parent.InstanceQuery)

local DEFAULT_MAX_FRICTION_TORQUE = 20
local IsStudio = game:GetService("RunService"):IsStudio()

type SavedTracks = Types.SavedTracks
type CharacterRagdollInfo = Types.CharacterRagdollInfo

local function IsModel(value: any)
	return typeof(value) == "Instance" and value:IsA("Model")
end

local function StudioWarn(msg: string)
	if not IsStudio then return end
	debug.traceback(`[RagdollService]: {msg}`)
end

local function NewAttachment(cframe: CFrame, parent: BasePart): Attachment
	local attachment = Instance.new("Attachment")
	attachment.CFrame = cframe
	attachment.Parent = parent
	return attachment
end

local function NewNoCollision(part0: BasePart, part1: BasePart): NoCollisionConstraint
	local no_collision = Instance.new("NoCollisionConstraint")
	no_collision.Enabled = false
	no_collision.Part0 = part0
	no_collision.Part1 = part1
	no_collision.Parent = part1
	return no_collision
end

local function NewSocket(attachment0: Attachment, attachment1: Attachment, socket_limits: Types.SocketLimits?): BallSocketConstraint
	local socket = Instance.new("BallSocketConstraint")
	socket.Attachment0 = attachment0
	socket.Attachment1 = attachment1
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true
	socket.MaxFrictionTorque = DEFAULT_MAX_FRICTION_TORQUE
	
	if socket_limits then
		if socket_limits.MaxFrictionTorque then
			socket.MaxFrictionTorque = socket_limits.MaxFrictionTorque
		end
		socket.UpperAngle = socket_limits.UpperAngle
		socket.TwistLowerAngle = socket_limits.TwistLowerAngle
		socket.TwistUpperAngle = socket_limits.TwistUpperAngle
	end
	
	socket.Parent = attachment0.Parent
	return socket
end

local function QueryInstance(parent: Instance, path: Types.PathArray?): any?
	if not path then return nil end
	return InstanceQuery:Get(parent, path)
end

local function RegisterDestroyedConnection(info: CharacterRagdollInfo, callback: () -> ())
	table.insert(info.Connections, info.Character.Destroying:Once(callback))
	table.insert(info.Connections, info.Character.AncestryChanged:Once(function(child, parent)
		if parent == nil then
			callback()
		end
	end))
end

local function RegisterRootNoCollision(limb_cache: {[BasePart]: boolean}, limb: BasePart, info: CharacterRagdollInfo)
	local root_part = info.RootPart
	if not root_part or limb == root_part or limb_cache[limb] then return end
	limb_cache[limb] = true
	table.insert(info.NoCollisionConstraints, NewNoCollision(limb, root_part))
end

local function SafeChangeState(humanoid: Humanoid, state: Enum.HumanoidStateType)
	if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
		humanoid:ChangeState(state)
	end
end

local function ToggleHumanoidRagdoll(ragdolled: boolean, humanoid: Humanoid)
	local state = if ragdolled then Enum.HumanoidStateType.Physics else Enum.HumanoidStateType.GettingUp
	SafeChangeState(humanoid, state)
	humanoid.AutoRotate = not ragdolled
end

local function ToggleRagdollComponents(ragdolled: boolean, info: CharacterRagdollInfo)
	for _, motor6d in info.Joints do
		motor6d.Enabled = not ragdolled
	end

	for _, no_collision in info.NoCollisionConstraints do
		no_collision.Enabled = ragdolled
	end
end

local function SaveTrack(saved_tracks: SavedTracks, track: AnimationTrack)
	table.insert(saved_tracks, {
		Track = track,
		TimePosition = os.clock() - track.TimePosition,
		Speed = track.Speed,
	})
	track:AdjustSpeed(0)
end

Util.IsModel = IsModel
Util.StudioWarn = StudioWarn

Util.NewAttachment = NewAttachment
Util.NewSocket = NewSocket
Util.NewNoCollision = NewNoCollision

Util.RegisterRootNoCollision = RegisterRootNoCollision
Util.RegisterDestroyedConnection = RegisterDestroyedConnection

Util.QueryInstance = QueryInstance
Util.SafeChangeState = SafeChangeState
Util.ToggleHumanoidRagdoll = ToggleHumanoidRagdoll
Util.ToggleRagdollComponents = ToggleRagdollComponents
Util.SaveTrack = SaveTrack

return table.freeze(Util)
