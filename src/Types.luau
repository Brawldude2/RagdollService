--!strict

export type SavedTracks = {{Track: AnimationTrack, Speed: number, TimePosition: number}}
export type CharacterRagdollInfo = {
	Ragdolled: boolean,
	Character: Model,
	RigType: string,
	Animator: Animator?,
	Humanoid: Humanoid?,
	RootPart: BasePart?,
	Limbs: {[string]: BasePart},
	Joints: {[string]: Motor6D},
	Sockets: {[string]: BallSocketConstraint},
	Attachments: {Attachment},
	NoCollisionConstraints: {NoCollisionConstraint},
	Connections: {RBXScriptConnection},
}
export type LocalPlayerRagdollInfo = {
	Character: Model,
	CameraSubject: Instance?,
	PreviousCameraSubject: Instance?,
	Humanoid: Humanoid?,
	Animator: Animator?,
	RootPart: BasePart?,
	Connections: {RBXScriptConnection},
	SavedTracks: SavedTracks,
}

-- Path array is a relative path to a certain instance from Character
-- Example: Animator path -> {"Humanoid", "Animator"}
export type QueryPath = {string}
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
	Animator: QueryPath?,
	Humanoid: QueryPath?,
	RootPart: QueryPath,
	CameraSubject: QueryPath?,
	Joints: {[string]: QueryPath},
	Limbs: {[string]: QueryPath},
	Sockets: {[string]: SocketLimits},
	NoCollisionConstraints: {NoCollisionConfig},
}

return nil