-- Copyright 2022 CodeLeopard
-- License: LGPL-3.0-or-later

--[[ This Program is free software: you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

The Program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with the Program. If not, see <https://www.gnu.org/licenses/>.
]]



---@meta
-- This file fakes the API so that code Editors with Lua language support 
-- will provide hints and warnings.
-- It doesn't **actually** do anything. Any implementation that you see here is just an example.
-- A good plugin for VSCode is: sumneko.lua
error('This file exists only to help code editors understand, you don\'t need to require it.')


---@class InterpolationSettings
---@field MaxAngleBetweenInterpolations number
---@field MaxSegmentOffset number
---@field MinInterpolationDistance number
---@field ShrinkReluctance number
---@field Clone fun(): InterpolationSettings
---@operator call: InterpolationSettings
InterpolationSettings = {}



---@class CurveSpec
---@field Enabled boolean
---@field Transform Transformation
---@field MeshSharing MeshSharing
---@field PhysSharing PhysSharing
---@field SnapType string
---@field MinLength number
---@field Extrusions List --List<Extrusion>
---@field Periodics List --List<PeriodicItemSpec>
---@field TrainPhysics List --List<TrainPhysics>
---@field SubSpecs List --List<CurveSpec>
---@field Clone fun(): CurveSpec
---@operator call: CurveSpec
CurveSpec = {}



---@class Transformation
---@field Parent Transformation
---@field LockRotationX boolean
---@field LockRotationY boolean
---@field LockRotationZ boolean
---@field LocalPosition Vector3
---@field LocalScale Vector3
---@field LocalRotationRadians Vector3
---@field LocalRotationDegrees Vector3



---@class MeshOrPhysSharing

---@class MeshSharing : MeshOrPhysSharing

---@class PhysSharing : MeshOrPhysSharing



--todo: when generics are implemented apply them to List.

---@class List
---@field Count integer The number of elements currently in the list
---@field Capacity integer The number of elements the list can contain before it will automatically allocate additional memory.
local List = { }
---Adds an element to the list. Note that calling it with : instead of . is required.
---@param element `T`
function List:Add(element)
	table.insert(self, element)
end


---@class Extrusion
---@field LoopSets List --List<LoopSet>
---@field Clone fun(): Extrusion
---@operator call: Extrusion
Extrusion = {}


---@class LoopSet
---@field Loops List --List<Loop>
---@field LineIndices List --List<integer>
---@field PhysLineIndices List --List<integer>
---@field ReverseTriangles boolean
---@field PhysFromVisual boolean
---@field ComputeNormals fun(self: LoopSet, overrideExisting?: boolean)
---@field Clone fun(): LoopSet
---@operator call: LoopSet
LoopSet = {}


---@class Loop
---@field InterpolationSettings InterpolationSettings
---@field Vertices List --List<VertexRecord>
---@field Clone fun(): Loop
---@operator call: Loop
Loop = {}

--------------------------------------------------------------------------------

--- Struct: copied by value rather than reference!
---@class VertexRecord
---@field position Vector3
---@field color Color
---@field normal Vector3
---@overload fun(position: Vector3, color: Color, normal: Vector3): VertexRecord
---@operator call: VertexRecord
VertexRecord = {}


--- Struct: copied by value rather than reference!
---@class Vector3
---@field X number
---@field Y number
---@field Z number
---@overload fun(x: number, y: number, z: number): Vector3
---@operator call: Vector3
Vector3 = {}


--- Struct: copied by value rather than reference!
---@class Color 
---@field R number [0..1]
---@field G number [0..1]
---@field B number [0..1]
---@field A? number [0..1]
---@overload fun(r: number, g: number, b: number, a: number|nil): Color
---@operator call: Color
Color = {}

---@param R integer [0..255]
---@param G integer [0..255]
---@param B integer [0..255]
---@param A? integer [0..255]
---@return Color
function Color255(R, G, B, A)
	return Color(R / 255, G / 255, B / 255, (A or 255) / 255)
end




--------------------------------------------------------------------------------

---@class PeriodicItemSpec
---@field Enabled boolean
---@field Transform Transformation
---@field Visual boolean
---@field Physics boolean
---@field MeshSharing MeshSharing
---@field PhysSharing PhysSharing
---@field InitialOffset number [0..1]
---@field Smudge number [0..1]
---@field AlwaysFullSequence boolean
---@field Items List --List<PeriodicItemBase>
---@field Clone fun(): PeriodicItemSpec
---@operator call: PeriodicItemSpec
PeriodicItemSpec = {}


---@class PeriodicItemBase
---@field Transform Transformation
---@field MinDistance number
---@field IdealDistance number



---@class PeriodicItem : PeriodicItemBase
---@field MeshSpec MeshSpec
---@field Clone fun(): PeriodicItem
---@operator call: PeriodicItem
PeriodicItem = {}



---@class PeriodicGroup : PeriodicItemBase
---@field Entries List --List<MeshSpecification>
---@field Clone fun(): PeriodicGroup
---@operator call: PeriodicGroup
PeriodicGroup = {}



---@class MeshSpec
---@field Transform Transformation
---@field Mesh Mesh
---@field MeshPath string
---@field PaintZones List --List<Color>
---@field ForcePaint boolean Apply the first paint zone/color to all vertices.
---@field GeneratePhys boolean
---@field Phys Phys
---@field PhysPath string
---@field Clone fun(): MeshSpec
---@operator call: MeshSpec
MeshSpec = {}


---@class TrainPhysics
---@field Enabled boolean
---@field Transform Transformation
---@field InterpolationSettings InterpolationSettings
---@field Clone fun(): TrainPhysics
---@operator call: TrainPhysics
TrainPhysics = {}



--- Stores mesh (visual) data.
---@class Mesh
--- Stores physics data.
---@class Phys

---@enum ShaderID
ShaderID =
{
	Opaque      = 0,
	Transparent = 1,
	Emissive    = 2,
	Lava        = 3,
}