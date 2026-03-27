--!strict
--!optimize 2

local RagdollService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Util = require(script.Util)
local Types = require(script.Types)
local RigConfigs = require(script.RigConfigs)
local RagdollBuilder = require(script.RagdollBuilder)

local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

local RAGDOLL_REMOTE_NAME = "LocalPlayerRagdollRemote"

type CharacterRagdollInfo = Types.CharacterRagdollInfo
type LocalPlayerRagdollInfo = Types.LocalPlayerRagdollInfo
type RigTypes = Types.RigTypes

local Camera = workspace.CurrentCamera
local CharacterRagdollInfos = {} :: {[Model]: CharacterRagdollInfo}
local LocalPlayerRagdollInfo: LocalPlayerRagdollInfo? = nil
local LocalPlayerRagdollRemote: RemoteEvent

local function InvalidateLocalPlayerRagdollInfo()
	if not LocalPlayerRagdollInfo then return end
	if Players.LocalPlayer.Character ~= LocalPlayerRagdollInfo.Character then
		LocalPlayerRagdollInfo = nil
	end
end

local function CreateLocalPlayerRagdollInfo(character: Model, ragdoll_type: RigTypes): LocalPlayerRagdollInfo
	local info: LocalPlayerRagdollInfo = {
		Character = character,
		SavedTracks = {},
		Connections = {},
	} 
	if ragdoll_type == "Generic" then
		info.Humanoid = character:FindFirstChildWhichIsA("Humanoid", true)
		info.Animator = character:FindFirstChildWhichIsA("Animator", true)
		info.CameraSubject = character:FindFirstChild("Head", true)
		info.RootPart = character.PrimaryPart
		if info.Humanoid then
			info.RootPart = info.Humanoid.RootPart
		end
	else
		local config = RigConfigs[ragdoll_type]
		info.Humanoid = Util.QueryInstance(character, config.Humanoid)
		info.Animator = Util.QueryInstance(character, config.Animator)
		info.CameraSubject = Util.QueryInstance(character, config.CameraSubject)
		info.RootPart = Util.QueryInstance(character, config.RootPart)
	end
	return info
end

local function ActivateLocalPlayerRagdoll(ragdoll_type: RigTypes)
	InvalidateLocalPlayerRagdollInfo()
	if LocalPlayerRagdollInfo then return end
	
	local player = Players.LocalPlayer :: Player
	local character = player.Character
	if not character or not character:IsDescendantOf(workspace) then return end
	
	local info = CreateLocalPlayerRagdollInfo(character, ragdoll_type)
	LocalPlayerRagdollInfo = info
	
	if info.Humanoid then
		Util.ToggleHumanoidRagdoll(true, info.Humanoid)
	end
	
	if info.CameraSubject then
		info.PreviousCameraSubject = Camera.CameraSubject
		Camera.CameraSubject = info.CameraSubject
	end
	
	-- Break the ragdoll balance
	if info.RootPart then
		info.RootPart:ApplyAngularImpulse(info.RootPart.CFrame.RightVector * 50)
	end
	
	local animator = info.Animator
	if animator then
		-- Let humanoid step once for Animate script compatibility
		table.insert(info.Connections, RunService.PreSimulation:Once(function()
			for _, track: AnimationTrack in animator:GetPlayingAnimationTracks() do
				Util.SaveTrack(info.SavedTracks, track)
			end
			table.insert(info.Connections, animator.AnimationPlayed:Connect(function(track: AnimationTrack)
				Util.SaveTrack(info.SavedTracks, track)
			end))
		end))
	end
end

local function DeactivateLocalPlayerRagdoll(ragdoll_type: RigTypes)
	InvalidateLocalPlayerRagdollInfo()
	if not LocalPlayerRagdollInfo then return end
	local info = LocalPlayerRagdollInfo
	LocalPlayerRagdollInfo = nil
	
	for _, connection in info.Connections do
		connection:Disconnect()
	end
	
	if info.Humanoid then
		Util.ToggleHumanoidRagdoll(false, info.Humanoid)
	end
	
	for _, track_info in info.SavedTracks do
		local track = track_info.Track
		local timeposition = os.clock() - track.TimePosition
		if track.Looped or timeposition < track.Length then
			track:AdjustSpeed(track_info.Speed)
			track.TimePosition = timeposition
		else
			track:Stop()
		end
	end
	
	if info.PreviousCameraSubject then
		Camera.CameraSubject = info.PreviousCameraSubject
	end
end

local function ConnectLocalPlayerRagdollRemote(remote: RemoteEvent)
	remote.OnClientEvent:Connect(function(enabled: boolean, ragdoll_type: RigTypes)
		if enabled then
			ActivateLocalPlayerRagdoll(ragdoll_type)
		else
			DeactivateLocalPlayerRagdoll(ragdoll_type)
		end
	end)
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

local function GetRigType(character: Model): RigTypes
	local rig_type = character:GetAttribute("RigType") :: RigTypes?
	if rig_type then return rig_type end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			return "R6"
		elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
			return "R15"
		end
	end
	
	return "Generic"
end

local function DestroyRagdoll(character: Model)
	local info = CharacterRagdollInfos[character]
	if not info then return end
	
	for _, no_collision in info.NoCollisionConstraints do
		no_collision:Destroy()
	end
	for _, socket in info.Sockets do
		socket:Destroy()
	end
	for _, attachment in info.Attachments do
		attachment:Destroy()
	end
	for _, c in info.Connections do
		c:Disconnect()
	end
	CharacterRagdollInfos[character] = nil
end

local function SetupRagdoll(character: Model, rig_type: RigTypes?): boolean
	assert(Util.IsModel(character), "Character is not model.")
	if not character:IsDescendantOf(workspace) then return false end
	
	local rig_type = rig_type or GetRigType(character)
	if not RagdollBuilder.Validate(character, rig_type) then
		return false
	end
	
	local info = RagdollBuilder.Build(character, rig_type)
	Util.RegisterDestroyedConnection(info, function()
		DestroyRagdoll(character)
	end)
	CharacterRagdollInfos[character] = info
	return true
end

local function ActivateRagdoll(character: Model): boolean
	assert(Util.IsModel(character), "Character is not model.")
	
	local info = CharacterRagdollInfos[character]
	if not info or info.Ragdolled then return false end
	info.Ragdolled = true

	if IsServer then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			LocalPlayerRagdollRemote:FireClient(player, true, info.RigType)
		end
	end

	if info.Humanoid then
		Util.ToggleHumanoidRagdoll(true, info.Humanoid)
	end
	
	Util.ToggleRagdollComponents(true, info)

	if info.Animator then
		local animator = info.Animator
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop()
		end
	end

	-- Break the ragdoll balance on server if owned by server on client if local rig
	if info.RootPart and (IsClient or info.RootPart:GetNetworkOwner() == nil) then
		info.RootPart:ApplyAngularImpulse(info.RootPart.CFrame.RightVector * 50)
	end

	return true
end

local function DeactivateRagdoll(character: Model): boolean
	assert(Util.IsModel(character), "Character is not a model.")
	
	local info = CharacterRagdollInfos[character]
	if not info or not info.Ragdolled then return false end
	info.Ragdolled = false

	if info.Humanoid then
		Util.ToggleHumanoidRagdoll(false, info.Humanoid)
	end
	Util.ToggleRagdollComponents(false, info)
	
	if IsServer then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			LocalPlayerRagdollRemote:FireClient(player, false, info.RigType)
		end
	end

	return true
end

local function Ragdoll(character: Model, rig_type: RigTypes?): boolean
	assert(Util.IsModel(character), "Character is not a model.")
	
	local info = CharacterRagdollInfos[character]
	if not info then
		local success = SetupRagdoll(character, rig_type)
		if not success then return false end
	end
	
	ActivateRagdoll(character)
	
	return true
end

local function Unragdoll(character: Model): boolean
	assert(Util.IsModel(character), "Character is not model.")

	local info = CharacterRagdollInfos[character]
	if not info then return false end
	
	DeactivateRagdoll(character)
	DestroyRagdoll(character)

	return true
end

if IsServer then
	LocalPlayerRagdollRemote = Instance.new("RemoteEvent")
	LocalPlayerRagdollRemote.Name = RAGDOLL_REMOTE_NAME
	LocalPlayerRagdollRemote.Parent = script
else
	LocalPlayerRagdollRemote = script:FindFirstChild(RAGDOLL_REMOTE_NAME) :: RemoteEvent
	if LocalPlayerRagdollRemote then
		ConnectLocalPlayerRagdollRemote(LocalPlayerRagdollRemote)
	end
	local connection: RBXScriptConnection
	connection = script.ChildAdded:Connect(function(child: Instance)
		if child:IsA("RemoteEvent") and child.Name == RAGDOLL_REMOTE_NAME then
			connection:Disconnect()
			ConnectLocalPlayerRagdollRemote(child)
		end
	end)
end

RagdollService.IsPlayerRagdolled = IsPlayerRagdolled
RagdollService.IsRagdolled = IsRagdolled
RagdollService.SetupRagdoll = SetupRagdoll
RagdollService.DestroyRagdoll = DestroyRagdoll
RagdollService.ActivateRagdoll = ActivateRagdoll
RagdollService.DeactivateRagdoll = DeactivateRagdoll
RagdollService.Ragdoll = Ragdoll
RagdollService.Unragdoll = Unragdoll

return table.freeze(RagdollService)