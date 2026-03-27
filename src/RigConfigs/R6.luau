--!strict

local Types = require(script.Parent.Parent.Types)
type SocketLimits = Types.SocketLimits

local NECK_LIMITS: SocketLimits = {MaxFrictionTorque = 10, UpperAngle = 30, TwistLowerAngle = -60, TwistUpperAngle = 60}
local SHOULDER_LIMITS: SocketLimits = {MaxFrictionTorque = 10, UpperAngle = 90, TwistLowerAngle = -45, TwistUpperAngle = 175}
local HIP_LIMITS: SocketLimits = {MaxFrictionTorque = 10, UpperAngle = 60, TwistLowerAngle = -25, TwistUpperAngle = 120}

local Config: Types.RigConfig = {
	Animator = {"Humanoid", "Animator"},
	Humanoid = {"Humanoid"},
	RootPart = {"HumanoidRootPart"},
	CameraSubject = {"Head"},
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