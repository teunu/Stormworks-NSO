g_savedata = {
	lists = {}
}

function onCreate(is_world_create)
	if is_world_create then
		spawnAll()
	end
end

function spawnAll()

	local spawn_types = {
		{
			tag = "railroad_signal",
			default_type = "default"
		}
	}

	for _, spawn_type in ipairs(spawn_types) do
		local tag, default_type = spawn_type.tag, spawn_type.default_type
		local type_tag = tag .. "_type"

		local objects_by_type = generateObjectByTypeMapping(tag, default_type)
		local spawn_zones = getSpawnZones(tag, default_type)

		local index = 0
		local spawned = {}

		for _, zone in ipairs(spawn_zones) do
			local prefab = nil
			if not zone.meta[type_tag] then
				prefab = objects_by_type[zone.meta[type_tag]]
			end
			if not prefab and zone.meta[type_tag] ~= default_type then
				prefab = objects_by_type[default_type]
			end
			if not prefab then
				server.announce("Railroad Signal", "Error spawning " .. tag:gsub("_"," ") .. " - no signal prefab for type: " .. tostring(zone.meta[type_tag]))
			else
				local vehicle_id, success = prefab.spawn(zone.transform)
				if not success then
					server.announce("Railroad Signal", "Error spawning " .. tag:gsub("_"," ") .. " - spawn error for zone: " .. tostr(zone))
				end
			end
		end
		g_savedata.lists[tag] = spawned
	end
end

function tostr(v)
	if type(v) == type({}) then
		local str, first = "", true
		for k, v in pairs(v) do
			if first then first = false else str = str .. "," end
			str = str .. tostr(k) .. "=" .. tostr(v)
		end
		return "{" .. str .. "}"
	else
		return tostring(v)
	end
end

function hasTag(tags, targetTag)
	for _, tag in ipairs(tags) do
		if tag == targetTag then
			return true
		end
	end
	return false
end

function splitStringOnce(value, separator)
	local pos = value:find(separator, 1, true)
	if pos or 0 > 1 then
		return value:sub(1, pos - 1), value:sub(pos + separator:len())
	else
		return value
	end
end

function parseTags(tags, container)
	for _, tag in ipairs(tags) do
		local k, v = splitStringOnce(tag, "=")
		if v == nil then v = true end
		container[k] = v
	end
	return container
end

function splitString(value, separator)
	local parts = {}
	while value and value:len() > 0 do
		local part, tail = splitStringOnce(value, separator)
		table.insert(parts, part)
		value = tail
	end
	return parts
end

function joinStringArray(stringArray, separator)
	local out, first = "", true
	for _, str in ipairs(stringArray) do
		if first then first = false else out = out .. separator end
		out = out .. str
	end
	return out
end

function sortTypeParts(typeString)
	local parts = splitString(typeString, "&")
	table.sort(parts)
	return joinStringArray(parts, "&")
end

function iterComponents(addon_index, location_index)
	local location_data = server.getLocationData(addon_index, location_index)
	local object_count = 0
	if location_data then object_count = location_data.component_count end
	local object_index = 0

	return function()
		local object_data = nil
		local index = object_count

		while not object_data and object_index < object_count do
			object_data = server.getLocationComponentData(addon_index, location_index, object_index)
			index = object_index
			object_index = object_index + 1
		end

		if object_data then
			return index, object_data
		else
			return nil
		end
	end
end

function iterLocations(addon_index)
	local addon_data = server.getAddonData(addon_index)
	local location_count = 0
	if addon_data then location_count = addon_data.location_count end
	local location_index = 0

	return function()
		local location_data = nil
		local index = location_count

		while not location_data and location_index < location_count do
			location_data = server.getLocationData(addon_index, location_index)
			local local_location_index = location_index
			location_data.iterate = function() return iterComponents(addon_index, local_location_index) end
			index = location_index
			location_index = location_index + 1
		end

		if location_data then
			return index, location_data
		else
			return nil
		end
	end
end

function iterAddons()
	local addon_count = server.getAddonCount()
	local addon_index = 0

	return function()
		local addon_data = nil
		local index = addon_count

		while not addon_data and addon_index < addon_count do
			addon_data = server.getAddonData(addon_index)
			local local_addon_index = addon_index
			addon_data.iterate = function() return iterLocations(local_addon_index) end
			index = addon_index
			addon_index = addon_index + 1
		end

		if addon_data then
			return index, addon_data
		else
			return nil
		end
	end
end

function generateObjectByTypeMapping(tag, default_type)
	local type_tag = tag .. "_type"
        local objects_by_type = {}
       	local our_addon_index = server.getAddonIndex()
       	for addon_index,addon_data in iterAddons() do
	        for _, location_data in addon_data.iterate() do
	  		if not location_data.env_mod then
	  			for component_index,component_data in location_data.iterate() do
					if component_data.type == "vehicle" and hasTag(component_data.tags, tag) then
						local meta = {[type_tag] = default_type}
						component_data.meta = parseTags(component_data.tags, meta)
						component_data.meta[type_tag] = sortTypeParts(component_data.meta[type_tag])
						if component_data.meta[type_tag] and (addon_index ~= our_addon_index or objects_by_type[component_data.meta[type_tag]] == nil) then
							local local_addon_index = addon_index
							local local_component_index = component_data.id
							component_data.spawn = function(position)
								return server.spawnAddonVehicle(matrix.multiply(position, component_data.transform), local_addon_index, local_component_index)
							end

							objects_by_type[component_data.meta[type_tag]] = component_data
						end
					end
				end
			end
		end
	end
	return objects_by_type
end

function getSpawnZones(tag, default_type)
	local type_tag = tag .. "_type"
	local zones = server.getZones(tag)
	for _, zone in ipairs(zones) do
		local meta = {[type_tag] = default_type}
		zone.meta = parseTags(zone.tags, meta)
		zone.meta[type_tag] = sortTypeParts(zone.meta[type_tag])
	end
	return zones
end
