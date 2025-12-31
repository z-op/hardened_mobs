-- Helper: Check if mob should be affected
local function should_harden(mobname)
    -- Check if mod is enabled
    if not hardened_mobs.config.enabled then
        return false
    end

    -- Check whitelist (if not empty, only whitelisted mobs are affected)
    if next(hardened_mobs.config.mob_whitelist or {}) ~= nil then
        return (hardened_mobs.config.mob_whitelist or {})[mobname] == true
    end

    -- Check blacklist
    if (hardened_mobs.config.mob_blacklist or {})[mobname] == true then
        return false
    end

    return true
end

-- Calculate total multiplier based on various factors
local function calculate_multiplier(pos, mobname)
    local multiplier = hardened_mobs.config.global_multiplier or 1.0

    -- Depth scaling
    if (hardened_mobs.config.depth_enabled) and pos.y < (hardened_mobs.config.depth_start or 0) then
        local depth = (hardened_mobs.config.depth_start or 0) - pos.y
        local depth_mult = 1.0 + (depth * (hardened_mobs.config.depth_multiplier or 0))
        multiplier = multiplier * depth_mult
    end

    -- Distance scaling (from world origin)
    if hardened_mobs.config.distance_enabled then
        local distance = vector.distance(pos, {x=0, y=0, z=0})
        if distance > (hardened_mobs.config.distance_start or 0) then
            local dist_mult = 1.0 + ((distance - (hardened_mobs.config.distance_start or 0)) *
                                   (hardened_mobs.config.distance_multiplier or 0))
            multiplier = multiplier * dist_mult
        end
    end

    -- Time scaling
    if hardened_mobs.config.time_enabled then
        local time = minetest.get_timeofday()
        if time > 0.2 and time < 0.8 then -- Night
            multiplier = multiplier * (hardened_mobs.config.night_multiplier or 1.5)
        else -- Day
            multiplier = multiplier * (hardened_mobs.config.day_multiplier or 1.0)
        end
    end

    -- Biome scaling
    if hardened_mobs.config.biome_enabled then
        local biome_data = minetest.get_biome_data(pos)
        if biome_data then
            local biome_name = minetest.get_biome_name(biome_data.biome)
            if biome_name and (hardened_mobs.config.biome_multipliers or {})[biome_name] then
                multiplier = multiplier * hardened_mobs.config.biome_multipliers[biome_name]
            end
        end
    end

    -- Apply min/max limits
    multiplier = math.max(hardened_mobs.config.min_multiplier or 0.5,
                         math.min(hardened_mobs.config.max_multiplier or 10.0, multiplier))

    return multiplier
end

-- Apply visual effects to mob
local function apply_effects(entity, multiplier)
    if not hardened_mobs.config.show_particles and not hardened_mobs.config.show_flames then
        return
    end

    -- Show particles for significantly strengthened mobs
    if hardened_mobs.config.show_particles and multiplier > 1.5 then
        minetest.add_particlespawner({
            amount = 6,
            time = 0.1,
            minpos = {x=-0.5, y=0, z=-0.5},
            maxpos = {x=0.5, y=2, z=0.5},
            minvel = {x=-1, y=2, z=-1},
            maxvel = {x=1, y=4, z=1},
            minacc = {x=0, y=-9.81, z=0},
            maxacc = {x=0, y=-9.81, z=0},
            minexptime = 0.5,
            maxexptime = 1.5,
            minsize = 0.5,
            maxsize = 1.0,
            collisiondetection = false,
            vertical = false,
            texture = hardened_mobs.config.particle_texture or "hardened_mobs_particle.png",
            attached = entity,
        })
    end

    -- Show flames for very strong mobs
    if hardened_mobs.config.show_flames and multiplier > 3.0 then
        -- Add flame overlay
        entity:set_properties({
            textures = entity:get_properties().textures,
            -- Note: Actual flame effect would require additional handling
        })
    end
end

-- Main hardening function
function hardened_mobs.harden_mob(entity, pos)
    if not entity or not pos then
        return
    end

    local luaentity = entity:get_luaentity()
    if not luaentity or not luaentity.name then
        return
    end

    local mobname = luaentity.name

    -- Check if mob should be hardened
    if not should_harden(mobname) then
        return
    end

    -- Check if mob has already been hardened
    if luaentity._hardened_mobs_applied then
        return
    end

    -- Calculate multiplier
    local multiplier = calculate_multiplier(pos, mobname)

    -- Debug log BEFORE hardening
    if hardened_mobs.debug then
        local prop = entity:get_properties()
        minetest.log("action", string.format(
            "[hardened_mobs] Processing %s at %s: health=%s, hp_max=%s, multiplier=%.2f",
            mobname,
            minetest.pos_to_string(pos),
            luaentity.health or "nil",
            prop.hp_max or "nil",
            multiplier
        ))
    end

    -- Apply mob-specific override
    local override = (hardened_mobs.config.mob_overrides or {})[mobname]
    if override then
        if override.health_mult then
            multiplier = override.health_mult
        end
    end

    -- Apply hardening
    if multiplier ~= 1.0 then
        -- Store original values if not already stored
        if not luaentity._hardened_mobs_original then
            luaentity._hardened_mobs_original = {}

            -- Store current health
            if luaentity.health then
                luaentity._hardened_mobs_original.health = luaentity.health
            end

            -- Store max health from object properties (CRITICAL FIX)
            local prop = entity:get_properties()
            if prop.hp_max then
                luaentity._hardened_mobs_original.hp_max = prop.hp_max
            end

            -- Store hp_min/hp_max for Mobs Redo
            if luaentity.hp_min then
                luaentity._hardened_mobs_original.hp_min = luaentity.hp_min
            end
            if luaentity.hp_max then
                luaentity._hardened_mobs_original.hp_max_mobs = luaentity.hp_max
            end

            -- Store damage and other properties
            if luaentity.damage then
                luaentity._hardened_mobs_original.damage = luaentity.damage
            end
            if luaentity.walk_velocity then
                luaentity._hardened_mobs_original.walk_velocity = luaentity.walk_velocity
            end
            if luaentity.run_velocity then
                luaentity._hardened_mobs_original.run_velocity = luaentity.run_velocity
            end
            if luaentity.armor then
                luaentity._hardened_mobs_original.armor = luaentity.armor
            end
        end

        -- Apply multiplier to current health
        if luaentity._hardened_mobs_original.health then
            luaentity.health = math.floor(luaentity._hardened_mobs_original.health * multiplier)
            luaentity.old_health = luaentity.health  -- Important for health change detection
        end

        -- Apply multiplier to max health in object properties (CRITICAL FIX)
        if luaentity._hardened_mobs_original.hp_max then
            local new_hp_max = math.floor(luaentity._hardened_mobs_original.hp_max * multiplier)
            entity:set_properties({hp_max = new_hp_max})
        end

        -- Apply multiplier to hp_min/hp_max for Mobs Redo
        if luaentity._hardened_mobs_original.hp_min then
            luaentity.hp_min = math.floor(luaentity._hardened_mobs_original.hp_min * multiplier)
        end
        if luaentity._hardened_mobs_original.hp_max_mobs then
            luaentity.hp_max = math.floor(luaentity._hardened_mobs_original.hp_max_mobs * multiplier)
        end

        -- Apply multiplier to damage
        local damage_multiplier = multiplier
        if override and override.damage_mult then
            damage_multiplier = override.damage_mult
        end

        if luaentity._hardened_mobs_original.damage then
            if type(luaentity._hardened_mobs_original.damage) == "number" then
                luaentity.damage = luaentity._hardened_mobs_original.damage * damage_multiplier
            elseif type(luaentity._hardened_mobs_original.damage) == "table" then
                luaentity.damage = {
                    min = luaentity._hardened_mobs_original.damage.min * damage_multiplier,
                    max = luaentity._hardened_mobs_original.damage.max * damage_multiplier,
                }
            end
        end

        -- Apply to other properties (optional)
        if luaentity._hardened_mobs_original.walk_velocity then
            luaentity.walk_velocity = luaentity._hardened_mobs_original.walk_velocity *
                                   (1 + (multiplier - 1) * 0.3)
        end
        if luaentity._hardened_mobs_original.run_velocity then
            luaentity.run_velocity = luaentity._hardened_mobs_original.run_velocity *
                                  (1 + (multiplier - 1) * 0.3)
        end
        if luaentity._hardened_mobs_original.armor then
            luaentity.armor = luaentity._hardened_mobs_original.armor *
                            (1 + (multiplier - 1) * 0.2)
        end

        -- Update mob's nametag and infotext
        if luaentity.update_tag then
            luaentity:update_tag()
        end

        -- Apply visual effects
        apply_effects(entity, multiplier)

        -- Mark as hardened
        luaentity._hardened_mobs_applied = true
        luaentity._hardened_mobs_multiplier = multiplier

        -- Debug log AFTER hardening
        if hardened_mobs.debug then
            local prop = entity:get_properties()
            minetest.log("action", string.format(
                "[hardened_mobs] AFTER Hardening %s: health=%s, hp_max=%s, hp_min=%s, hp_max_mobs=%s",
                mobname,
                luaentity.health or "nil",
                prop.hp_max or "nil",
                luaentity.hp_min or "nil",
                luaentity.hp_max or "nil"
            ))

            minetest.log("action", "[hardened_mobs] Hardened " .. mobname ..
                        " at " .. minetest.pos_to_string(pos) ..
                        " with multiplier " .. multiplier)
        end
    end
end

-- API functions
function hardened_mobs.register_rule(name, rule_def)
    hardened_mobs.rules = hardened_mobs.rules or {}
    hardened_mobs.rules[name] = rule_def
end

function hardened_mobs.get_multiplier_at_pos(pos, mobname)
    if not pos then return 1.0 end
    return calculate_multiplier(pos, mobname or "")
end

function hardened_mobs.is_hardened(entity)
    local luaentity = entity:get_luaentity()
    return luaentity and luaentity._hardened_mobs_applied == true
end
