--!strict

local RigConfigType = require(script.Parent.RigConfigType)
type SocketLimits = RigConfigType.SocketLimits

local NECK_LIMITS: SocketLimits = {UpperAngle = 30, TwistLowerAngle = -60, TwistUpperAngle = 60}
local SHOULDER_LIMITS: SocketLimits = {UpperAngle = 90, TwistLowerAngle = -30, TwistUpperAngle = 175}
local HIP_LIMITS: SocketLimits = {UpperAngle = 60, TwistLowerAngle = -5, TwistUpperAngle = 120}

local Config: RigConfigType.RigConfig = {
	Animator = {"Humanoid", "Animator"},
	Humanoid = {"Humanoid"},
	BreakJointsOnDeath = false,
	HasDefaultAnimate = true,
	RootPart = {"HumanoidRootPart"},
	Limbs = {
		["HumanoidRootPart"] = {"HumanoidRootPart"},
		["Head"] = {"Head"},
		["Torso"] = {"Torso"},
		["Right Leg"] = {"Right Leg"},
		["Right Arm"] = {"Right Arm"},
		["Left Leg"] = {"Left Leg"},
		["Left Arm"] = {"Left Arm"},
	},
	Joints = {
		Neck = {"Torso", "Neck"},
		RightShoulder = {"Torso", "Right Shoulder"},
		LeftShoulder = {"Torso", "Left Shoulder"},
		RightHip = {"Torso", "Right Hip"},
		LeftHip = {"Torso", "Left Hip"},
	},
	Sockets = {
		Neck = NECK_LIMITS,
		RightShoulder = SHOULDER_LIMITS,
		LeftShoulder = SHOULDER_LIMITS,
		RightHip = HIP_LIMITS,
		LeftHip = HIP_LIMITS,
	},
	NoCollisionConstraints = {
		{"HumanoidRootPart","Torso"},
		{"HumanoidRootPart","Head"},
		{"HumanoidRootPart","Left Arm"},
		{"HumanoidRootPart","Right Arm"},
		{"HumanoidRootPart","Right Leg"},
		{"HumanoidRootPart","Left Leg"},
		
		{"Head", "Torso"},
		{"Left Arm", "Torso"},
		{"Right Arm", "Torso"},
		{"Left Leg", "Torso"},
		{"Right Leg", "Torso"},
	}
}

return Config
