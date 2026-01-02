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
local process_interval = 5.0
local last_process_time = 0

minetest.register_globalstep(function(dtime)
    last_process_time = last_process_time + dtime
    if last_process_time < process_interval then
        return
    end
    last_process_time = 0

    if not hardened_mobs.config.enabled then
        return
    end

    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        if pos then
            local objects = minetest.get_objects_inside_radius(pos, 50)
            for _, obj in ipairs(objects) do
                local luaentity = obj:get_luaentity()
                if luaentity and luaentity.name then
                    -- Пропускаем уже обработанных мобов
                    if not luaentity._hardened_mobs_applied then
                        local mobname = luaentity.name

                        -- Быстрая предварительная фильтрация
                        if mobname and not mobname:find("^__builtin:") and mobname ~= "player" then
                            local mob_pos = obj:get_pos()
                            if mob_pos then
                                hardened_mobs.harden_mob(obj, mob_pos)
                            end
                        end
                    end
                end
            end
        end
    end
end)
minetest.log("action", "[hardened_mobs] Mod loaded")
