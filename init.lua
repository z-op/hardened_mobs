local MP = minetest.get_modpath("hardened_mobs")

-- Загрузка конфигурации
hardened_mobs = {}
dofile(MP .. "/config.lua")
dofile(MP .. "/functions.lua")

-- Загрузка правил, если файл существует
local rules_path = MP .. "/rules.lua"
if io.open(rules_path, "r") then
    dofile(rules_path)
end

-- Обработчик для всех мобов
minetest.register_globalstep(function(dtime)
    hardened_mobs.globalstep_timer = (hardened_mobs.globalstep_timer or 0) + dtime
    if hardened_mobs.globalstep_timer > 0.5 then  -- Check more frequently
        hardened_mobs.globalstep_timer = 0

        for _, player in ipairs(minetest.get_connected_players()) do
            local pos = player:get_pos()
            if pos then
                local objects = minetest.get_objects_inside_radius(pos, 150)  -- Increased radius
                for _, obj in ipairs(objects) do
                    local entity = obj:get_luaentity()
                    if entity and entity._cmi_is_mob and not entity._hardened_mobs_applied then
                        local mob_pos = obj:get_pos()
                        if mob_pos then
                            hardened_mobs.harden_mob(obj, mob_pos)
                        end
                    end
                end
            end
        end
    end
end)
minetest.log("action", "[hardened_mobs] Mod loaded")
