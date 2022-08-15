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





--[[ Explanation of the measurements of the Rail profile, see also: https://en.wikipedia.org/wiki/Rail_profile
                                                        
                                      │<───>│ Head Width
          │<-- Rail Inner Distance -->│     │           
    ╔═════╗                           ╔═════╗ ─┐  <--────────── The top of the Head is at height 0.
    ║     ║     <-- Head              ║     ║  ├─ Head Height
    ╚═╗ ╔═╝                           ╚═╗ ╔═╝ ─┘  ────┐ 
      ║ ║                               ║ ║           │ 
      ║ ║       <-- Web                 ║ ║           ├─ Web Height
      ║ ║                               ║ ║           │ 
 ╔════╝ ╚════╗                     ╔════╝ ╚════╗ ─┐  ─┘ 
 ║           ║  <-- Bottom         ║           ║  ├─ Bottom Height (can be 0)
 ╚═══════════╝                     ╚═══════════╝ ─┘     
 │<--─────-->│ Bottom Width                             
                                                        
--------------------------------------------------------
Vertex order for Right (+x) Rail
        0                  1
      19╔══════════════════╗ 2
        ║                  ║   
        ║     16     5     ║   
      18╚═════╗      ╔═════╝  3 
        17    ║      ║     4
              ║      ║     
    14      15║      ║6        7
  13╔═════════╝      ╚═════════╗ 8
    ║                          ║ 
    ║                          ║ 
  12╚══════════════════════════╝ 9
   11                          10

   Vertex order for Right (+x) Rail with zero bottom height
        0                  1        
      15╔══════════════════╗2       
        ║                  ║        
        ║                  ║        
      14╚═════╗12   5╔═════╝3       
        13    ║      ║     4        
              ║      ║              
    10        ║      ║         7    
   9╔═════════╝11   6╚═════════╗ 8  
    ╚══════════════════════════╝    
]]



-- todo: move to it's own lib.
---Creates a full/deep copy of the provided data.
---Copies both keys and values, but ignores metaTables.
---@param data table|any The data to be copied.
---@param seen table? Optional Set of things that have been copied already, mapping original to copy.
---@param target table? Optional target table to write to.
---@return table
local function deepCopy(data, seen, target)
	if(type(data) ~= "table") then
		return data
	end
	seen = seen or {}
	target = target or {}
	if seen[data] then
		return seen[data]
	end

	seen[data] = target
	for k, v in pairs(data) do
		target[deepCopy(k, seen)] = deepCopy(v, seen)
	end
	return target
end


local lib = {}
lib.version = "0.1.0"


--- A tiny offset that prevents Z fighting that occurs when two surfaces are at exactly the same place.
local antiZFight = 0.001

--- Presets of Rail Settings.
---@type table<string, RailGeneratorSettings>
lib.presets =
{
	--- UIC60 is a European specification for rails.
	---@class RailGeneratorSettings
	UIC60 =
	{
		--- The distance between the insides of the rails, AKA the gauge.
		InnerDistance = 1435,

		HeadWidth        = 72,
		HeadHeight       = 37,
		HeadBottomWidth  = 75,

		--- The height of the transition between Head and Web.
		Head2WebHeight   = 14,

		WebHeight        = 89.5,
		WebTopWidth      = 26,
		WebBottomWidth   = 26,

		--- The height of the transition between Web and Bottom.
		Web2BottomHeight = 31.5,

		--- Unlike all other settings this one can be 0.
		BottomHeight     = 0,
		BottomWidth      = 150,

		--- Color of the driving/contact surfaces.
		--- Typically the contact of the wheels keep this rust-free.
		SurfaceColor    = Color255(90, 70, 70, 255),
		--- Color of the infrequent contact surfaces.
		--- Infrequent contact of the wheels keeps this somewhat rust-free.
		MediumRustColor = Color255(90, 70, 70, 255),
		--- Color of the remaining parts of the rail that are not kept rust-free.
		FullRustColor   = Color255(90, 70, 70, 255),
	},
}

function lib.newSettings()
	return deepCopy(lib.presets.UIC60)
end


---Generate an Extrusion for a set of rails based on settings.
---@param settings RailGeneratorSettings Defaults to Stormworks' standard gauge.
---@param ISet? InterpolationSettings the interpolationSettings to apply.
function lib.Generate(settings, ISet)
	settings = deepCopy(settings, nil, lib.newSettings())


	-- Convert MilliMeters to Meters
	local railInnerDistance = settings.InnerDistance / 1000

	local headWidth  = settings.HeadWidth / 1000
	local headHeight = settings.HeadHeight / 1000
	local headBottomWidth = settings.HeadBottomWidth / 1000

	local headToWebTransitionHeight = settings.Head2WebHeight / 1000

	local webHeight      = settings.WebHeight / 1000
	local webTopWidth    = settings.WebTopWidth / 1000
	local webBottomWidth = settings.WebBottomWidth / 1000

	local webToBottomTransitionHeight = settings.Web2BottomHeight / 1000

	local bottomHeight  = settings.BottomHeight / 1000
	local bottomWidth   = settings.BottomWidth / 1000

	local surfaceColor      = settings.SurfaceColor
	local outerSurfaceColor = settings.MediumRustColor
	local restColor         = settings.FullRustColor

	local railOffset = railInnerDistance / 2
	local railCenter = railOffset + headWidth / 2

	--- The current height.
	local height = 0
	local vertexIndex = 0
	local makeSingleLine = true

	-- For physics
	local mkPhys = true


	local extrusion = Extrusion()
	local set = LoopSet()
	extrusion.LoopSets:Add(set)

	-- Enable manually simplified physics.
	set.PhysFromVisual = false

	-- Collect vertex indices in a table,
	-- then make lines for them afterwards.
	local physVertexIndices =
	{
		Add = function(self, element)
			table.insert(self, element)
		end
	}

	set.ReverseTriangles = true

	local loop = Loop()
	set.Loops:Add(loop)

	if ISet then -- Apply only when a value is provided, so we don't set it to nothing.
		loop.InterpolationSettings = ISet
	end

	---Adds a point, multiple points will have blended normals
	---which means it appears as smooth/curved.
	---@param x number
	---@param y number
	---@param color Color
	---@param physics? boolean
	local function Point(x, y, color, physics)
		if makeSingleLine then
			set.LineIndices:Add(vertexIndex)
		else
			set.LineIndices:Add(vertexIndex)
			set.LineIndices:Add(vertexIndex)
		end

		if physics == true then
			physVertexIndices:Add(vertexIndex)
		end

		local v = VertexRecord()
		v.position = Vector3(x, y, 0)
		v.normal = Vector3(0,0,0) -- Will be computed later.
		v.color = color

		loop.Vertices:Add(v)

		vertexIndex = vertexIndex + 1

		makeSingleLine = false
	end

	---Adds a point but forces it to be a hard edge (not blended normals).
	---It does this by adding multiple points.
	---@param x number
	---@param y number
	---@param color1 Color
	---@param color2 Color
	---@param physics? boolean
	local function HardEdge(x, y, color1, color2, physics)
		set.LineIndices:Add(vertexIndex)

		if physics == true then
			physVertexIndices:Add(vertexIndex)
		end

		local v = VertexRecord()
		v.position = Vector3(x, y, 0)
		v.normal = Vector3(0,0,0) -- Will be computed later.
		v.color = color1

		loop.Vertices:Add(v)
		vertexIndex = vertexIndex + 1

		set.LineIndices:Add(vertexIndex)

		v.color = color2
		loop.Vertices:Add(v)
		vertexIndex = vertexIndex + 1

		makeSingleLine = false
	end

--------------------------------------------------------------------------------
------- Start ------------------------------------------------------------------
--------------------------------------------------------------------------------

	-- This is the Right (+X) side.

	-- Inner driving surface
	Point(railOffset, height, surfaceColor, mkPhys) -- by definition.

	-- Outer driving surface
	HardEdge(railOffset + headWidth, height + antiZFight, outerSurfaceColor, outerSurfaceColor, mkPhys);


	height = height - headHeight;
	-- Low end of outer head.
	-- HardEdge(railOffset + headBottomWidth, height, restColor, restColor);

	height = height - headToWebTransitionHeight;
	-- Upper end of outer web.
	-- Point(railCenter + webTopWidth / 2, height, restColor);

	height = height - webHeight;
	-- Lower end of outer web.
	-- Point(railCenter + webBottomWidth / 2, height, restColor);

	height = height - webToBottomTransitionHeight;

	if bottomHeight ~= 0 then
		-- Outer Top of bottom
		--HardEdge(railCenter + bottomWidth / 2, height, restColor, restColor);

		height = height - bottomHeight;
		-- Inner Base of bottom
		HardEdge(railCenter + bottomWidth / 2, height, restColor, restColor, mkPhys);

		-- Outer Base of bottom
		HardEdge(railCenter - bottomWidth / 2, height, restColor, restColor, mkPhys);

		-- Transition to Inner side
		-- Now going up again

		height = height + bottomHeight;
		-- Inner side of Top of bottom
		--HardEdge(railCenter - bottomWidth / 2, height, restColor, restColor);
	else
		-- Outer Top of bottom
		HardEdge(railCenter + bottomWidth / 2, height, restColor, restColor, mkPhys);

		-- Inner Top of bottom
		HardEdge(railCenter - bottomWidth / 2, height, restColor, restColor, mkPhys);
	end

	height = height + webToBottomTransitionHeight;
	-- Inner web bottom
	--Point(railCenter - webBottomWidth / 2, height, restColor);


	height = height + webHeight;
	-- Inner web top
	--Point(railCenter - webTopWidth / 2, height, restColor);

	height = height + headToWebTransitionHeight;
	-- Inner head bottom
	--HardEdge(railCenter - headBottomWidth / 2, height, restColor, restColor);

	height = height + headHeight;
	-- Inner head top, last
	makeSingleLine = true;
	Point(railCenter - headWidth / 2, height, surfaceColor);


--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	-- Compute normals, but keep any that ware explicitly defined already.
	-- Will only replace (0,0,0).
	set:ComputeNormals(false)

--------------------------------------------------------------------------------
------ Mirror ------------------------------------------------------------------
--------------------------------------------------------------------------------
	-- Mirror on X axis to obtain the rail on the other side.

	local pointsPerRail      = loop.Vertices.Count
	local indicesPerRail     = set.LineIndices.Count
	local physIndicesPerRail = set.PhysLineIndices.Count

	for i = 0, pointsPerRail - 1, 1 do
		-- Copy the record at position i
		local record = loop.Vertices[i]

		-- Copy the position of the record
		local position = record.position
		-- Modify the position
		position.X = - position.X
		-- Save the modification back to our copy.
		record.position = position

		-- Flip the normal.
		local normal = record.normal
		normal.X = - normal.X
		record.normal = normal

		-- Add the modified copy to the list.
		loop.Vertices:Add(record)
	end

	for i = 0, indicesPerRail - 1, 2 do -- Note the step size for i is 2
		-- Indices are reversed.
		set.LineIndices:Add(set.LineIndices[i + 1] + pointsPerRail)
		set.LineIndices:Add(set.LineIndices[i    ] + pointsPerRail)
	end

	return extrusion
end


local mt =
{
	-- Allow usage like so: lib(railSettings)
	__call = function(self, ...) return lib.Generate(...) end,
}
setmetatable(lib, mt)

return lib