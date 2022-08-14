
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
ISet.MinInterpolationDistance = 4 -- meters


do -- Make trains be able to drive
	local train = TrainPhysics()

	train.InterpolationSettings = ISet

	spec.TrainPhysics:Add(train)
end

do -- Add rails
	local railSettings = Rails.presets.UIC60
	local extrusion = Rails(railSettings)

	-- Convert to stormworks (wide) gauge.
	extrusion.Transform.LocalScale = Vector3(1.115, 1.115, 1)

	spec.Extrusions:Add(extrusion)
end

spec.Periodics:Add(require('lib.Sleepers'))

do -- Create Embankment
	-- Pass nil to settings argument to use defaults.
	local extrusion = Embankment({TopColour = Color255(77, 77, 62, 255), Colour = Color255(98, 70, 60, 255), BottomWidth = 6, Height = 2, YOffset = -0.25, ClosedBottom = true }, ISet)
	spec.Extrusions:Add(extrusion)
end

do
	-- Create Pillars
	local Interval	= 20

	local p = PeriodicItemSpec()

	p.Transform.LocalPosition = Vector3(0, -40.5, 0)

	-- Rotations are in degrees and are:
		-- around X axis (right)
		-- around Y axis (up)
		-- around Z axis (forward)
	-- Note that each such rotation affects the next rotation axis.
	p.Transform.LocalRotationDegrees = Vector3(0, 0, 0)

	p.Transform.LocalScale = Vector3(1, 40, 0.8)

	local i = PeriodicItem()
	i.IdealDistance = Interval

	local m = MeshSpec()
	m.MeshPath = "meshes/unit_cylinder.mesh"
	m.ForcePaint = true
	m.PaintZones:Add(Color255(98, 70, 60, 255))

	p.Physics = true

	i.MeshSpec = m
	p.Items:Add(i)
	spec.Periodics:Add(p)
end

-- Return the specification.
return spec