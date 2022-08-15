
-- Add Toblerone(TM) Sleepers
-- Using a triangle rather than cube as the basis saves some performance.

local Interval	= 1.4

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
i.IdealDistance = Interval

local m = MeshSpec()
m.MeshPath = "meshes/tut_wedge.mesh"
m.ForcePaint = true
m.PaintZones:Add(Color255(199, 173, 153))

-- Disable physics for the sleepers because it causes too much lag for little added value.
p.Physics = false

i.MeshSpec = m
p.Items:Add(i)

return p
