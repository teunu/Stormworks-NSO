-- Rail without any embankment.

local Rails	= require('Lib.RailGenerator')

-- Create container object.
local Spec = CurveSpec()
Spec.MaxSegmentLength = 200

-- Create a shared InterpolationSettings (explained below).
local ISet = InterpolationSettings()

-- While generating the system will attempt to make segments as long as possible up to:
ISet.MaxInterpolationDistance = 200 -- meters
-- The following two constraints can cause the segment to become shorter if they are not met:
-- Segments are straight lines, it will try to make sure that the angle between
-- such lines is no more than this value.
ISet.MaxAngleBetweenInterpolations = 0.01 -- degrees
-- The maximum distance between the middle of the segment and the perfect mathematical curve.
ISet.MaxSegmentOffset = 0.1 -- meters
-- When the constraints are never satisfied the segment will not be made shorter than this:
ISet.MinInterpolationDistance = 5 -- meters

do -- Make trains be able to drive
	local train = TrainPhysics()

	train.InterpolationSettings = ISet

	--  Adjust physics upwards so wheels are aligned to the rails.
	train.Transform.LocalPosition = Vector3(0, 0.04, 0)

	Spec.TrainPhysics:Add(train)
end

do -- Add rails
	local RailSettings = Rails.presets.UIC60
	local Extrusion = Rails(RailSettings, ISet)

	-- Convert to stormworks (wide) gauge.
	Extrusion.Transform.LocalScale = Vector3(1.115, 1.115, 1)

	Spec.Extrusions:Add(Extrusion)
end

-- Add Sleepers
Spec.Periodics:Add(require('lib.Clamped_Slab'))

-- Return the specification.
return Spec