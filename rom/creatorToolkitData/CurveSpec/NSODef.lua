
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

do -- Add Toblerone(TM) Sleepers
	-- Using a triangle rather than cube as the basis saves some performance.
	local p = PeriodicItemSpec()
	p.Transform.LocalPosition = Vector3(0, -0.185, 0)

	-- Rotations are in degrees and are:
		-- around X axis (right)
		-- around Y axis (up)
		-- around Z axis (forward)
	-- Note that each such rotation affects the next rotation axis.
	p.Transform.LocalRotationDegrees = Vector3(90, -45, 90)

	p.Transform.LocalScale = Vector3(1, 7.3, 7.3)

	local i = PeriodicItem()
	i.IdealDistance = 2

	local m = MeshSpec()
	m.MeshPath = "meshes/tut_wedge.mesh"
	m.ForcePaint = true
	m.PaintZones:Add(Color255(199, 173, 153))

	-- Disable physics for the sleepers because it causes too much lag for little added value.
	p.Physics = false

	i.MeshSpec = m
	p.Items:Add(i)
	spec.Periodics:Add(p)
end

do -- Create Embankment
	-- Pass nil to settings argument to use defaults.
	local extrusion = Embankment({Colour = Color255(77, 77, 62, 255), BottomWidth = 24, YOffset = -0.25 }, ISet)
	spec.Extrusions:Add(extrusion)
end

-- Return the specification.
return spec