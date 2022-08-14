
-- Helper functions
local Rails				= require('Lib.NSORailGenerator')
local Gravelbed			= require('Lib.Railbed')
local Embankment		= require('Lib.Embankment')

-- Create container object.
local spec = CurveSpec()

-- Create a shared InterpolationSettings (explained below).
local ISet = InterpolationSettings()

-- While generating the system will attempt to make segments as long as possible up to:
ISet.MaxInterpolationDistance = 50 -- meters

-- The following two constraints can cause the segment to become shorter if they are not met:
-- Segments are straight lines, it will try to make sure that the angle between
-- such lines is no more than this value.
ISet.MaxAngleBetweenInterpolations = 0.01 -- degrees

-- The maximum distance between the middle of the segment and the perfect mathematical curve.
ISet.MaxSegmentOffset = 0.1 -- meters

-- When the constraints are never satisfied the segment will not be made shorter than this:
ISet.MinInterpolationDistance = 6 -- meters


do -- Make trains be able to drive
	local train = TrainPhysics()

	train.InterpolationSettings = ISet

	spec.TrainPhysics:Add(train)
end

do -- Add rails
	local railSettings = Rails.presets.UIC60
	local extrusion = Rails(railSettings, ISet)

	-- Convert to stormworks (wide) gauge.
	extrusion.Transform.LocalScale = Vector3(1.115, 1.115, 1)

	spec.Extrusions:Add(extrusion)
end

spec.Periodics:Add(require('lib.Sleepers'))

do -- Create Embankment
	-- Pass nil to settings argument to use defaults.
	local extrusion = Embankment({Colour = Color255(77, 77, 62, 255), BottomWidth = 24, YOffset = -0.25 }, ISet)
	spec.Extrusions:Add(extrusion)
end

-- Return the specification.
return spec