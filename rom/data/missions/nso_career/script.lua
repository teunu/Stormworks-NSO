--career object:
--active			is wether or not missions of this type could spawn randomly.
--prestige_level 	is the prestige score, useful for rewards and mission size / difficulty.
--missions_active 	is just a flat count of how much missions with this tag are in the world

g_savedata = {
	initialised	= false,
	career_info_id = -1,

	--career lines
	career_sar = { active = false, prestige_level = 0, missions_active = 0 },
	career_transport = { active = false, prestige_level = 0, missions_active = 0 },
	career_industry = { active = false, prestige_level = 0, missions_active = 0 },
	career_science 	= { active = false, prestige_level = 0, missions_active = 0 },
	career_military = { active = false, prestige_level = 0, missions_active = 0 }
}

update_timer = 0

function onCreate(is_world_create)
	if is_world_create then
		if g_savedata == nil then
			g_savedata = {}
		end
	end
end

function onTick(delta_worldtime)
	if update_timer == 60 and not g_savedata.initialised then
		server.notify(user_peer_id, "NSO Careers", "NSO is loading in the shared career framework...", 7)
		
		--Start loading in shared components
		local playlist_index = server.getAddonIndex()
		server.spawnMissionLocation(matrix.translation(0,0,0), playlist_index, (server.getLocationIndex(playlist_index, "start")))
	elseif update_timer == 60 then
		server.notify(user_peer_id, "NSO Careers", "NSO Careers are Active", 5)
	end

	if update_timer == 120 and not g_savedata.initialised then
		server.notify(user_peer_id, "NSO Careers", "NSO Careers are Active", 5)
		g_savedata.initialised = true

		GetNSOCareerData()
		--server.notify(user_peer_id, "NSO Careers", tostring(g_savedata.career_info_id), 6)
	end

	update_timer = update_timer + 1
end

function GetNSOCareerData()
	for i = 1, 256, 1 do
		name, is_success = server.getVehicleName(i)
		if not is_success then break end
		if name == nil or name == '' then
			
		else
			if name == 'vehicle_147' then 
				g_savedata.career_info_id = i
				break
			end
		end
	end
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, arg1, arg2, arg3, arg4)
	if command == "?nso test" then 
		server.announce("NSO Careers Library: Active")
		server.notify(user_peer_id, "[NSO] Careers", "Active:" .. tostring(initalised), 7)
	end

	if command == "?nso_prestige_get" then 
		server.notify(user_peer_id, "[NSO] SAR Career Prestige", tostring(g_savedata.career_sar.prestige_level), 5)
		server.notify(user_peer_id, "[NSO] Transport Career Prestige", tostring(g_savedata.career_transport.prestige_level), 5)
		server.notify(user_peer_id, "[NSO] Industry Career Prestige", tostring(g_savedata.career_industry.prestige_level), 5)
		server.notify(user_peer_id, "[NSO] Science Career Prestige", tostring(g_savedata.career_science.prestige_level), 5)
		server.notify(user_peer_id, "[NSO] Military Career Prestige", tostring(g_savedata.career_military.prestige_level), 5)
	end

end
