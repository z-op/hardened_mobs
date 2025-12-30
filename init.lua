--[[
Hardened Mobs - Makes mobs stronger based on various factors
Copyright (C) 2018 ExeterDad

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

local modpath = minetest.get_modpath("hardened_mobs")

-- Configuration settings
hardened_mobs = {
	config = {},
	rules = {},
	enabled_mobs = {},
	debug = false
}

-- Default configuration
local default_config = {
	-- General
	enabled = true,
	global_multiplier = 1.0,
	min_multiplier = 0.5,
	max_multiplier = 10.0,

	-- Depth scaling
	depth_enabled = true,
	depth_start = 0,
	depth_multiplier = 0.005, -- 0.5% per node below start

	-- Distance scaling
	distance_enabled = false,
	distance_start = 0,
	distance_multiplier = 0.0001, -- 0.01% per node from start

	-- Time scaling
	time_enabled = false,
	night_multiplier = 1.5,
	day_multiplier = 1.0,

	-- Biome scaling
	biome_enabled = false,
	biome_multipliers = {
		["desert"] = 1.5,
		["icesheet"] = 1.3,
		["tundra"] = 1.2,
	},

	-- Visual effects
	show_particles = true,
	particle_texture = "hardened_mobs_particle.png",
	show_flames = false,

	-- Specific mob overrides
	mob_overrides = {
		-- Example: ["mobs_monster:zombie"] = {health_mult = 2.0, damage_mult = 1.5}
	},

	-- Blacklist/whitelist
	mob_whitelist = {}, -- If empty, all mobs are affected
	mob_blacklist = {}, -- Mobs to exclude
}

-- Load configuration
local function load_config()
	-- First load defaults
	for k, v in pairs(default_config) do
		hardened_mobs.config[k] = v
	end

	-- Try to load custom config
	local config_file = io.open(modpath .. "/config.lua", "r")
	if config_file then
		local config_content = config_file:read("*all")
		config_file:close()

		-- Use loadstring to execute the config file
		local chunk, err = loadstring(config_content)
		if chunk then
			-- Create a local config table and run the chunk
			local custom_config = {}
			setfenv(chunk, {config = custom_config})
			local success, result = pcall(chunk)
			if success then
				-- Merge custom config with defaults
				for k, v in pairs(custom_config) do
					hardened_mobs.config[k] = v
				end
			else
				minetest.log("warning", "[hardened_mobs] Error loading config: " .. result)
			end
		else
			minetest.log("warning", "[hardened_mobs] Error parsing config: " .. err)
		end
	end
end

-- Load rules
local function load_rules()
	local rules_file = io.open(modpath .. "/rules.lua", "r")
	if rules_file then
		local rules_content = rules_file:read("*all")
		rules_file:close()

		local chunk, err = loadstring(rules_content)
		if chunk then
			setfenv(chunk, {
				hardened_mobs = hardened_mobs,
				minetest = minetest,
				mobs = mobs
			})
			local success, result = pcall(chunk)
			if not success then
				minetest.log("warning", "[hardened_mobs] Error loading rules: " .. result)
			end
		end
	end
end

-- Helper: Check if mob should be affected
local function should_harden(mobname)
	-- Check if mod is enabled
	if not hardened_mobs.config.enabled then
		return false
	end

	-- Check whitelist (if not empty, only whitelisted mobs are affected)
	if next(hardened_mobs.config.mob_whitelist) ~= nil then
		return hardened_mobs.config.mob_whitelist[mobname] == true
	end

	-- Check blacklist
	if hardened_mobs.config.mob_blacklist[mobname] == true then
		return false
	end

	return true
end

-- Calculate total multiplier based on various factors
local function calculate_multiplier(pos, mobname)
	local multiplier = hardened_mobs.config.global_multiplier

	-- Depth scaling
	if hardened_mobs.config.depth_enabled and pos.y < hardened_mobs.config.depth_start then
		local depth = hardened_mobs.config.depth_start - pos.y
		local depth_mult = 1.0 + (depth * hardened_mobs.config.depth_multiplier)
		multiplier = multiplier * depth_mult
	end

	-- Distance scaling (from world origin)
	if hardened_mobs.config.distance_enabled then
		local distance = vector.distance(pos, {x=0, y=0, z=0})
		if distance > hardened_mobs.config.distance_start then
			local dist_mult = 1.0 + ((distance - hardened_mobs.config.distance_start) *
								   hardened_mobs.config.distance_multiplier)
			multiplier = multiplier * dist_mult
		end
	end

	-- Time scaling
	if hardened_mobs.config.time_enabled then
		local time = minetest.get_timeofday()
		if time > 0.2 and time < 0.8 then -- Night
			multiplier = multiplier * hardened_mobs.config.night_multiplier
		else -- Day
			multiplier = multiplier * hardened_mobs.config.day_multiplier
		end
	end

	-- Biome scaling
	if hardened_mobs.config.biome_enabled then
		local biome_data = minetest.get_biome_data(pos)
		if biome_data then
			local biome_name = minetest.get_biome_name(biome_data.biome)
			if biome_name and hardened_mobs.config.biome_multipliers[biome_name] then
				multiplier = multiplier * hardened_mobs.config.biome_multipliers[biome_name]
			end
		end
	end

	-- Mob-specific override
	local override = hardened_mobs.config.mob_overrides[mobname]
	if override then
		if override.health_mult then
			-- Handle mob-specific multiplier differently
			-- We'll apply this in the hardening function
		end
	end

	-- Apply min/max limits
	multiplier = math.max(hardened_mobs.config.min_multiplier,
						 math.min(hardened_mobs.config.max_multiplier, multiplier))

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
			texture = hardened_mobs.config.particle_texture,
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

	-- Apply mob-specific override
	local override = hardened_mobs.config.mob_overrides[mobname]
	if override then
		if override.health_mult then
			-- Override takes precedence for health
			multiplier = override.health_mult
		end
	end

	-- Apply hardening
	if multiplier ~= 1.0 then
		-- Store original values if not already stored
		if not luaentity._hardened_mobs_original then
			luaentity._hardened_mobs_original = {
				health = luaentity.health or 10,
				max_health = luaentity.max_health or 10,
				damage = luaentity.damage or 2,
			}

			-- Try to get other properties
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

		-- Apply multiplier to health
		luaentity.health = math.floor(luaentity._hardened_mobs_original.health * multiplier)
		luaentity.max_health = math.floor(luaentity._hardened_mobs_original.max_health * multiplier)

		-- Apply multiplier to damage (with override handling)
		local damage_multiplier = multiplier
		if override and override.damage_mult then
			damage_multiplier = override.damage_mult
		end

		if type(luaentity._hardened_mobs_original.damage) == "number" then
			luaentity.damage = luaentity._hardened_mobs_original.damage * damage_multiplier
		elseif type(luaentity._hardened_mobs_original.damage) == "table" then
			luaentity.damage = {
				min = luaentity._hardened_mobs_original.damage.min * damage_multiplier,
				max = luaentity._hardened_mobs_original.damage.max * damage_multiplier,
			}
		end

		-- Apply to other properties (optional)
		if luaentity._hardened_mobs_original.walk_velocity then
			luaentity.walk_velocity = luaentity._hardened_mobs_original.walk_velocity *
								   (1 + (multiplier - 1) * 0.3) -- 30% of health boost
		end
		if luaentity._hardened_mobs_original.run_velocity then
			luaentity.run_velocity = luaentity._hardened_mobs_original.run_velocity *
								  (1 + (multiplier - 1) * 0.3)
		end
		if luaentity._hardened_mobs_original.armor then
			luaentity.armor = luaentity._hardened_mobs_original.armor *
							(1 + (multiplier - 1) * 0.2) -- 20% of health boost
		end

		-- Apply visual effects
		apply_effects(entity, multiplier)

		-- Mark as hardened
		luaentity._hardened_mobs_applied = true
		luaentity._hardened_mobs_multiplier = multiplier

		if hardened_mobs.debug then
			minetest.log("action", "[hardened_mobs] Hardened " .. mobname ..
						" at " .. minetest.pos_to_string(pos) ..
						" with multiplier " .. multiplier)
		end
	end
end

-- Hook into mob spawns
if mobs and mobs.register_on_spawn then
	mobs.register_on_spawn(function(entity, pos)
		hardened_mobs.harden_mob(entity, pos)
	end)
end

-- Alternative: Globalstep to catch mobs that might have been missed
local hardened_mobs_timer = 0
minetest.register_globalstep(function(dtime)
	if not hardened_mobs.config.enabled then
		return
	end

	hardened_mobs_timer = hardened_mobs_timer + dtime
	if hardened_mobs_timer < 1.0 then  -- Check every second
		return
	end
	hardened_mobs_timer = 0

	-- Check all objects
	for _, obj in ipairs(minetest.get_objects()) do
		local entity = obj:get_luaentity()
		if entity and entity.name and not entity._hardened_mobs_applied then
			-- Check if it's a mob (has health)
			if entity.health then
				local pos = obj:get_pos()
				if pos then
					hardened_mobs.harden_mob(obj, pos)
				end
			end
		end
	end
end)

-- Admin commands
minetest.register_chatcommand("hardened_mobs_reload", {
	params = "",
	description = "Reload Hardened Mobs configuration",
	privs = {server = true},
	func = function(name, param)
		load_config()
		load_rules()
		return true, "Hardened Mobs configuration reloaded"
	end,
})

minetest.register_chatcommand("hardened_mobs_debug", {
	params = "",
	description = "Toggle debug mode",
	privs = {server = true},
	func = function(name, param)
		hardened_mobs.debug = not hardened_mobs.debug
		return true, "Debug mode: " .. (hardened_mobs.debug and "ON" or "OFF")
	end,
})

-- API functions
function hardened_mobs.register_rule(name, rule_def)
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

-- Initialize
load_config()
load_rules()

-- Create default rules file if it doesn't exist
local rules_path = modpath .. "/rules.lua"
local rules_file = io.open(rules_path, "r")
if not rules_file then
	-- Create default rules file
	local default_rules = [[
-- Hardened Mobs Rules Configuration
-- Add custom rules here

-- Example rule: Harder mobs in specific areas
hardened_mobs.register_rule("danger_zone", {
	description = "Mobs in danger zone are stronger",

	condition = function(pos, mobname)
		-- Define a dangerous area (e.g., around spawn)
		local danger_pos = {x=0, y=0, z=0}
		local radius = 50
		return vector.distance(pos, danger_pos) < radius
	end,

	apply = function(entity, multiplier, pos, mobname)
		-- Double the multiplier in danger zone
		return multiplier * 2.0
	end
})

-- Example rule: Specific mob types get special treatment
hardened_mobs.register_rule("boss_mobs", {
	description = "Boss mobs are always strong",

	condition = function(pos, mobname)
		-- Check if mobname contains "boss"
		return mobname and string.find(mobname:lower(), "boss")
	end,

	apply = function(entity, multiplier, pos, mobname)
		-- Boss mobs minimum multiplier
		return math.max(multiplier, 3.0)
	end
})
]]

	local file = io.open(rules_path, "w")
	if file then
		file:write(default_rules)
		file:close()
		minetest.log("action", "[hardened_mobs] Created default rules file")
	end
else
	rules_file:close()
end

minetest.log("action", "[hardened_mobs] Mod loaded")
