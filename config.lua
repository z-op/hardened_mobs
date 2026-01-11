hardened_mobs = hardened_mobs or {}
-- Hardened Mobs Configuration
-- Modify these values to change the behavior
hardened_mobs.config = {
	-- General settings
	enabled = true,
	global_multiplier = 2.0,
	min_multiplier = 0.5,
	max_multiplier = 20.0,

	-- Depth scaling (Y coordinate)
	depth_enabled = true,
	depth_start = 0, -- Start scaling below this Y level
	depth_multiplier = 0.005, -- Multiplier per node below start (0.5%)

	-- Distance scaling (from world origin)
	distance_enabled = false,
	distance_start = 0, -- Start scaling after this distance
	distance_multiplier = 0.0001, -- Multiplier per node (0.01%)

	-- Time of day scaling
	time_enabled = false,
	night_multiplier = 1.5, -- Multiplier at night
	day_multiplier = 1.0, -- Multiplier during day

	-- Biome scaling
	biome_enabled = false,
	biome_multipliers = {
		["desert"] = 1.5,
		["icesheet"] = 1.3,
		["tundra"] = 1.2,
		["taiga"] = 1.1,
	},

	-- Visual effects
	show_particles = true,
	particle_texture = "hardened_mobs_particle.png",
	show_flames = false,

	-- Specific mob overrides (examples)
	mob_overrides = {
		-- ["mobs_monster:zombie"] = {
		--     health_mult = 2.0,
		--     damage_mult = 1.5
		-- },
		-- ["mobs_monster:sand_monster"] = {
		--     health_mult = 1.8,
		--     damage_mult = 1.3
		-- },
	},

	-- Mob whitelist (empty = all mobs)
	mob_whitelist = {
		-- ["mobs_monster:zombie"] = true,
		-- ["mobs_monster:sand_monster"] = true,
	},

	-- Mob blacklist
	mob_blacklist = {
		-- ["mobs_animal:chicken"] = true,
		-- ["mobs_animal:cow"] = true,
	},
}
hardened_mobs.debug = false
