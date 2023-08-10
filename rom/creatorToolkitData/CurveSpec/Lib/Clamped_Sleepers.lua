local Settings = require('Lib.Settings')
local Interval = 1
local TrackHalfWidth  = 
(1435 -- Inner distance
+ 250 -- adjustment
) 
 / 1000     -- Millimeter to meter
 / 2        -- 'diameter' to 'radius '

local ClampHeight = -
(
    37 + 14 + 89.5 + 31.5 -- Height of rail
    - 10  -- adjustment
) / 1000  -- Millimeter to meter


local Spec = PeriodicItemSpec()
Spec.Physics = false

local Group = PeriodicGroup()
Group.IdealDistance = Interval

local Sleeper = MeshSpec()
Sleeper.MeshPath = "nso_mod/meshes/railway/Sleeper_Concrete.mesh"
Sleeper.Transform.LocalPosition = Vector3(0, -0.315, 0)
Sleeper.Transform.LocalRotationDegrees = Vector3(0, 0, 0)


Group.Entries:Add(Sleeper)
Spec.Items:Add(Group)

Spec.Enabled = Settings.SleepersOn

return Spec