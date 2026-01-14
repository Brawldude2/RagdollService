--!strict
export type PathArray = {string}
export type AttachmentConfig = {
	Limb: string,
	Position: Vector3?,
	Orientation: Vector3?,
}
export type SocketLimits = {
	MaxFrictionTorque: number?,
	UpperAngle: number,
	TwistLowerAngle: number,
	TwistUpperAngle: number,
}
export type NoCollisionConfig = {string}
export type RigConfig = {
	Animator: PathArray?,
	Humanoid: PathArray?,
	BreakJointsOnDeath: boolean?,
	Animate: PathArray?,
	RootPart: PathArray,
	Joints: {[string]: PathArray},
	Limbs: {[string]: PathArray},
	Sockets: {[string]: SocketLimits},
	NoCollisionConstraints: {NoCollisionConfig},
}
return nil