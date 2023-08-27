
local Spec    = require('PW.Conc.NoBed')
local Bank    = require('Lib.Embankment')
local Colours = require('Lib.Colours')

local ISet = InterpolationSettings()
ISet.MaxInterpolationDistance      = 50
ISet.MaxAngleBetweenInterpolations = 0.01
ISet.MaxSegmentOffset              = 0.1
ISet.MinInterpolationDistance      = 10

do
	local extrusion = Bank(
		{
			TopColour    = Colours.Gravel,
			Colour       = Colours.Rusty,
			BottomWidth  = 6,
			ClosedBottom = true,
			Height       = 2,
			YOffset      = -0.25
		},
		ISet
	)
	Spec.Extrusions:Add(extrusion)
end

do -- Bridge Pillar
	local Interval     = 20
	local PeriodicSpec = PeriodicItemSpec()

	PeriodicSpec.Transform.LocalPosition = Vector3(0, -40.5, 0)
	PeriodicSpec.Transform.LocalScale    = Vector3(1, 40, 0.8)
	PeriodicSpec.Physics = true

	local Item = PeriodicItem()
	Item.IdealDistance = Interval

	local Mesh = MeshSpec()
	Mesh.MeshPath   = "meshes/unit_cylinder.mesh"
	Mesh.ForcePaint = true
	Mesh.PaintZones:Add(Colours.Rusty)

	Item.MeshSpec = Mesh
	PeriodicSpec.Items:Add(Item)
	Spec.Periodics:Add(PeriodicSpec)
end

return Spec