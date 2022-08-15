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




-- This file fakes the API so that code Editors with Lua language support 
-- will provide hints and warnings.
-- It doesn't **actually** do anything. Any implementation that you see here is just an example.



---@class List
---@field Count integer The number of elements currently in the list
---@field Capacity integer The number of elements the list can contain before it will automatically allocate additional memory.
local listAPI = { }

---Adds an element to the list. Note that calling it with : instead of . is required.
---@param element any
function listAPI:Add(element)
	table.insert(self, element)
end



---@class CurveSpec
local curveSpecAPI = {}




---@class Extrusion
local extrusionAPI = {}

local extrusionMT = {}

---Creates a new Extrusion object
---@return Extrusion
function extrusionMT.__call()
	return Extrusion()
end
setmetatable(extrusionAPI, extrusionMT)