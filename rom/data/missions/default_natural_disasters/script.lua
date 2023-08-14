g_savedata =
{
    doomsday_frequency = property.slider("Natural Disaster Frequency (Mins)", 1, 60, 1, 15) * 60 * 60,
    doomsday_countdown = 15 * 60 * 60,
    sirens = {},
    disasters = {},
    is_spawn_sirens = property.checkbox("Enable Sirens", true)
}

local timer = 0

local function SpawnWave(transform)
    server.spawnTsunami(transform, 0.1)
end

local function SpawnTornado(transform)
    server.spawnTornado(transform)
end

local function SpawnWhirlpool(transform)
    server.spawnWhirlpool(transform, 1)
end

local function SpawnTsunami(transform)
    server.spawnTsunami(transform, 0.9)
end

local function SpawnMeteor(transform)
    server.spawnMeteorShower(transform, 1, true)
end

local function SpawnVolcano(transform)

    local volcanos = server.getVolcanos()
    local closest_dist = 999999999
    local closest_volcano = nil

    for tile, v in pairs(volcanos) do
        local dist = matrix.distance(transform, matrix.translation(v.x, 0, v.z))
        if dist < closest_dist then
            closest_dist = dist
            closest_volcano = v
        end
    end

    if closest_volcano then
        server.spawnVolcano(matrix.translation(closest_volcano.x, 0, closest_volcano.z))
    end
end

local events = {
    Wave
        = { probability = 500/1000, spawn = SpawnWave },
    Tornado
        = { probability = 200/1000, spawn = SpawnTornado },
    Whirlpool
        = { probability = 100/1000, spawn = SpawnWhirlpool },
    Tsunami
        = { probability = 100/1000, spawn = SpawnTsunami },
    Meteor
        = { probability = 50/1000, spawn = SpawnMeteor },
    Volcano
        = { probability = 50/1000, spawn = SpawnVolcano },
}

function onTick(tick_time)
    g_savedata.doomsday_countdown = g_savedata.doomsday_countdown - 1
    if g_savedata.doomsday_countdown <= 0 then
        g_savedata.doomsday_countdown = g_savedata.doomsday_frequency

        local name, event = getRandomEvent()
        if event ~= nil then
            spawnEvent(name, event)
        end
    end

    if timer <= 0 then
        timer = 60 * 10

        for _, disaster in pairs(g_savedata.disasters) do
            if disaster.time <= 0 then
                disaster = nil
            else
                disaster.time = disaster.time - timer
                local siren_dist = math.max(disaster.siren_dist, 4000)
                activateSirens(disaster.transform, siren_dist)
            end
        end
    else
        timer = timer - 1
    end
end

function spawnEvent(name, event)
    local transform = getSpawnTransform()
    event.spawn(transform)
    --server.announce("disaster", "spawning "..name.." at "..transform[13].." "..transform[15])
end

function getSpawnTransform()
    local transform = (server.getPlayerPos(0))
    local angle = math.random() * math.pi * 2;
    local x = math.cos(angle) * 5000;
    local z = math.sin(angle) * 5000;

    return matrix.multiply(transform, matrix.translation(x, 0, z))
end

function getDifficulty()
	local difficulty_factor = 1
	if server.getGameSettings().no_clip == false then
		difficulty_factor = math.min(1, (server.getDateValue() - 20) / 60)
	end
	return difficulty_factor
end

function getRandomEvent()
    local d = math.random()
    local diff = getDifficulty()
    if d >= diff then
        return nil, nil
    end

    local p = math.random()
    local totalProbability = 0
    for name, event in pairs(events) do
        totalProbability = totalProbability + event.probability
        if p <= totalProbability then
            return name, event
        end
    end

    return nil, nil
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, a, b, c, d)
    if server.isDev() then
        if command == "?disaster" then
            if(a ~= nil) then
                if events[a] ~= nil then
                    spawnEvent(a, events[a])
                else
                    server.announce("Disaster", "Failed to spawn: "..a)
                end
            else
                g_savedata.doomsday_countdown = 0
            end
        elseif command == "?disastercancel" then
            server.cancelGerstner()
         end
    end
end

function onCreate(is_world_create)
    if g_savedata.is_spawn_sirens == nil then g_savedata.is_spawn_sirens = true end

	if is_world_create and g_savedata.is_spawn_sirens then
		spawnAll()
	end

    g_savedata.doomsday_countdown = g_savedata.doomsday_frequency
end

function spawnAll()
	local addonIndex = server.getAddonIndex()
	local sirenComponentId

	for locationIndex = 0, server.getAddonData(addonIndex).location_count - 1 do
		local locationData = server.getLocationData(addonIndex, locationIndex)
		if not locationData.is_env_mod then
			for componentIndex = 0, locationData.component_count - 1 do
				local componentData = server.getLocationComponentData(addonIndex, locationIndex, componentIndex)
				for i, tag in pairs(componentData.tags) do
					if tag == "default_siren" then
						sirenComponentId = componentData.id
					end
				end
			end
		end
	end

	local spawn_zones = server.getZones("siren_zone")

	for _, zone in pairs(spawn_zones) do
		local spawn_transform = matrix.multiply(zone.transform, matrix.translation(0, zone.size.y * 0.5, 0))
		local id = server.spawnAddonVehicle(spawn_transform, addonIndex, sirenComponentId)
        g_savedata.sirens[id] = spawn_transform
	end
end

function activateSirens(disaster_transform, dist)
    if g_savedata.is_spawn_sirens then
        for id, siren_transform in pairs(g_savedata.sirens) do
            if matrix.distance(disaster_transform, siren_transform) < dist then
                server.pressVehicleButton(id, "trigger")
            end
        end
    end
end

function onButtonPress(vid, pid, name, pressed)
    if pressed and name == "Toggle Warning System" then
        g_savedata.is_spawn_sirens = not g_savedata.is_spawn_sirens
        for id, siren_transform in pairs(g_savedata.sirens) do
            server.setVehicleKeypad(id, "state", g_savedata.is_spawn_sirens and 1 or 0)
        end
    end
end

function onVehicleLoad(vid)
    for id, siren_transform in pairs(g_savedata.sirens) do
        if id == vid then
            server.setVehicleKeypad(id, "state", g_savedata.is_spawn_sirens and 1 or 0)
        end
    end
end

function onTornado(transform)
    table.insert(g_savedata.disasters, {transform=transform, time=60*60*4, siren_dist=4000})
    activateSirens(transform, 4000)
end

function onTsunami(transform)
    table.insert(g_savedata.disasters, {transform=transform, time=60*60*5, siren_dist=7000})
    activateSirens(transform, 7000)
end

function onWhirlpool(transform)
    table.insert(g_savedata.disasters, {transform=transform, time=60*60*6, siren_dist=4000})
    activateSirens(transform, 4000)
end

function onMeteor(transform)
    table.insert(g_savedata.disasters, {transform=transform, time=60*60*1, siren_dist=4000})
    activateSirens(transform, 4000)
end

function onVolcano(transform)
    table.insert(g_savedata.disasters, {transform=transform, time=60*60*2, siren_dist=4000})
    activateSirens(transform, 4000)
end