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

local lib = {}

function lib.Generate(steps, radius, color)
	-- Create the LoopSet
	-- LoopSet holds a number of Loops (but 1 is fine too)
	local set = LoopSet()
	set.ReverseTriangles = true

	local loop = Loop()
	set.Loops:Add(loop)

	for i = 0, steps do
		local t = i / steps * math.pi * 2

		local x = math.sin(t)
		local y = math.cos(t)

		local v = VertexRecord()
		v.position = Vector3(x * radius, y * radius, 0)
		v.normal   = Vector3(x, y, 0)
		v.color    = color or Color4.White

		loop.Vertices:Add(v)
	end

	-- Indices reference vertices to create lines
	for i = 0, steps - 1 do
		set.LineIndices:Add(i)
		set.LineIndices:Add(i + 1)
	end
	-- Finish up with a line from the last Vertex to the first.
	set.LineIndices:Add(steps - 1)
	set.LineIndices:Add(0)

	return set
end


local mt =
{
	-- Allow usage like so: lib(steps, radius, color)
	__call = lib.Generate
}
setmetatable(lib, mt)

return lib