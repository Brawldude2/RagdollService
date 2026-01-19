--!strict

local RigConfigType = require(script.Parent.RigConfigType)
type SocketLimits = RigConfigType.SocketLimits

local NECK_LIMITS: SocketLimits = {MaxFrictionTorque = 55, UpperAngle = 15, TwistLowerAngle = -25, TwistUpperAngle = 25}
local WAIST_LIMITS: SocketLimits = {MaxFrictionTorque = 100, UpperAngle = 30, TwistLowerAngle = -40, TwistUpperAngle = 40}
local SHOULDER_LIMITS: SocketLimits = {MaxFrictionTorque = 100, UpperAngle = 35, TwistLowerAngle = -180, TwistUpperAngle = 180}
local ELBOW_LIMITS: SocketLimits = {MaxFrictionTorque = 100, UpperAngle = 0, TwistLowerAngle = -5, TwistUpperAngle = 160}
local HIP_LIMITS: SocketLimits = {MaxFrictionTorque = 100, UpperAngle = 30, TwistLowerAngle = -5, TwistUpperAngle = 20}
local KNEE_LIMITS: SocketLimits = {MaxFrictionTorque = 100, UpperAngle = 0, TwistLowerAngle = -45, TwistUpperAngle = 10}
local WRIST_LIMITS: SocketLimits = {MaxFrictionTorque = 100, UpperAngle = 20, TwistLowerAngle = -70, TwistUpperAngle = 40}
local ANKLE_LIMITS: SocketLimits = {MaxFrictionTorque = 100, UpperAngle = 10, TwistLowerAngle = -45, TwistUpperAngle = 25}

local Config: RigConfigType.RigConfig = {
	Animator = {"Humanoid", "Animator"},
	Humanoid = {"Humanoid"},
	BreakJointsOnDeath = false,
	Animate = {"Animate"},
	RootPart = {"HumanoidRootPart"},
	Limbs = {
		["HumanoidRootPart"] = {"HumanoidRootPart"},
		["Head"] = {"Head"},
		["LeftHand"] = {"LeftHand"},
		["RightHand"] = {"RightHand"},
		["LeftLowerArm"] = {"LeftLowerArm"},
		["RightLowerArm"] = {"RightLowerArm"},
		["LeftUpperArm"] = {"LeftUpperArm"},
		["RightUpperArm"] = {"RightUpperArm"},
		["LeftFoot"] = {"LeftFoot"},
		["LeftLowerLeg"] = {"LeftLowerLeg"},
		["UpperTorso"] = {"UpperTorso"},
		["LeftUpperLeg"] = {"LeftUpperLeg"},
		["RightFoot"] = {"RightFoot"},
		["RightLowerLeg"] = {"RightLowerLeg"},
		["LowerTorso"] = {"LowerTorso"},
		["RightUpperLeg"] = {"RightUpperLeg"},
	},
	Joints = {
		Neck = {"Head","Neck"},
		Waist = {"UpperTorso","Waist"},
		
		LeftWrist = {"LeftHand","LeftWrist"},
		LeftElbow = {"LeftLowerArm","LeftElbow"},
		LeftShoulder = {"LeftUpperArm","LeftShoulder"},
		
		RightWrist = {"RightHand","RightWrist"},
		RightElbow = {"RightLowerArm","RightElbow"},
		RightShoulder = {"RightUpperArm","RightShoulder"},
		
		RightHip = {"RightUpperLeg","RightHip"},
		RightKnee = {"RightLowerLeg","RightKnee"},
		RightAnkle = {"RightFoot","RightAnkle"},
		
		LeftHip = {"LeftUpperLeg","LeftHip"},
		LeftKnee = {"LeftLowerLeg","LeftKnee"},
		LeftAnkle = {"LeftFoot","LeftAnkle"},
	},
	Sockets = {
		Neck = NECK_LIMITS,
		Waist = WAIST_LIMITS,
		
		LeftShoulder = SHOULDER_LIMITS,
		LeftElbow = ELBOW_LIMITS,
		LeftWrist = WRIST_LIMITS,

		RightShoulder = SHOULDER_LIMITS,
		RightElbow = ELBOW_LIMITS,
		RightWrist = WRIST_LIMITS,

		RightHip = HIP_LIMITS,
		RightKnee = KNEE_LIMITS,
		RightAnkle = ANKLE_LIMITS,

		LeftHip = HIP_LIMITS,
		LeftKnee = KNEE_LIMITS,
		LeftAnkle = ANKLE_LIMITS,
	},
	NoCollisionConstraints = {
		{"HumanoidRootPart","UpperTorso"},
		{"HumanoidRootPart","LowerTorso"},
		{"HumanoidRootPart","Head"},
		{"HumanoidRootPart","RightUpperArm"},
		{"HumanoidRootPart","LeftUpperArm"},
		{"HumanoidRootPart","RightLowerArm"},
		{"HumanoidRootPart","LeftLowerArm"},
		{"HumanoidRootPart","RightHand"},
		{"HumanoidRootPart","LeftHand"},
		{"HumanoidRootPart","RightUpperLeg"},
		{"HumanoidRootPart","LeftUpperLeg"},
		{"HumanoidRootPart","RightLowerLeg"},
		{"HumanoidRootPart","LeftLowerLeg"},
		{"HumanoidRootPart","RightFoot"},
		{"HumanoidRootPart","LeftFoot"},
		
		{"UpperTorso","Head"},
		{"RightUpperArm","Head"},
		{"LeftUpperArm","Head"},
		{"RightLowerArm","Head"},
		{"LeftLowerArm","Head"},
		{"LeftLowerArm","LeftHand"},
		{"LeftHand","LeftUpperArm"},
		{"RightLowerArm","RightHand"},
		{"RightHand","RightUpperArm"},
		{"LeftUpperArm","LeftLowerArm"},
		{"RightUpperArm","RightLowerArm"},
		{"UpperTorso","LeftUpperArm"},
		{"UpperTorso","RightUpperArm"},
		{"LeftLowerLeg","LeftFoot"},
		{"LeftUpperLeg","LeftLowerLeg"},
		{"LeftFoot","LeftLowerLeg"},
		{"LowerTorso","UpperTorso"},
		{"RightLowerLeg","UpperTorso"},
		{"LeftUpperLeg","UpperTorso"},
		{"LeftHand","UpperTorso"},
		{"RightHand","UpperTorso"},
		{"LowerTorso","LeftUpperLeg"},
		{"LeftUpperLeg","RightUpperLeg"},
		{"RightLowerLeg","RightFoot"},
		{"RightUpperLeg","RightLowerLeg"},
		{"RightFoot","RightLowerLeg"},
		{"HumanoidRootPart","LowerTorso"},
		{"RightUpperLeg","LowerTorso"},
		{"LeftLowerLeg","LowerTorso"},
		{"UpperTorso","LowerTorso"},
		{"LeftHand","LowerTorso"},
		{"RightHand","LowerTorso"},
		{"LowerTorso","RightUpperLeg"},
	}
}

return Config
